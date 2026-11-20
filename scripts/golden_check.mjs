#!/usr/bin/env node
// golden 双端运行对比 — 同一输入在 MoonBit 与 Dart 两端实跑并逐行对比 | Golden dual-runtime diff
//
// 用法：node scripts/golden_check.mjs
// 前置：moon 工具链 + Dart SDK 3.x；回应组委会"用同一输入给出两端结果及拒绝或人工处理边界"的要求。
//
// 两组证据：
//   A. 算术语义（fixture.mbt）：溢出回绕 / 截断除法 / 截断余数 / trap 边界（14 行）
//   B. 业务函数（business.mbt）：Array→List / 索引 / while / push / 边界（10 行）
// 每组：MoonBit 真值端 `moon run <pkg>`；Dart 端经 moon2dart（wrapping, fail-closed）转换后 `dart run`。

import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const WORK = join(ROOT, 'golden_out');

function run(cmd) {
  const r = spawnSync(cmd, {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    cwd: ROOT,
  });
  if (r.status !== 0) {
    throw new Error(`命令失败: ${cmd}\n${r.stderr}`);
  }
  return r.stdout;
}

function runCapture(cmd) {
  const r = spawnSync(cmd, {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    cwd: ROOT,
  });
  return { stdout: r.stdout, stderr: r.stderr, status: r.status };
}

function splitLines(text) {
  return text.trim().split(/\r?\n/).filter((l) => l.length > 0);
}

// 通用：真值端 vs 转换端逐行对比，返回 rows/pass/fail
function checkGroup({ title, goldenCmd, fixture, cases, outFile, mdFile }) {
  console.log(`\n=== ${title} ===`);
  console.log(`[1/3] ${goldenCmd}`);
  const moonRes = runCapture(goldenCmd);
  const moonLines = splitLines(moonRes.stdout);
  if (moonRes.status !== 0 || moonLines.length === 0) {
    console.error('MoonBit 端执行失败：\n' + moonRes.stderr);
    process.exit(1);
  }

  console.log('[2/3] convert --semantics wrapping --on-unresolved error');
  const dartCode = run(
    `moon run cmd/main --target native -- convert "${fixture}" --semantics wrapping --on-unresolved error`,
  );
  if (!dartCode.includes('mb32Add') && !dartCode.includes('List<')) {
    console.error('转换产物缺少预期结构，中止');
    process.exit(1);
  }

  console.log('[3/3] dart run (Dart SDK)');
  mkdirSync(WORK, { recursive: true });
  const dartPath = join(WORK, outFile);
  writeFileSync(dartPath, dartCode, 'utf8');
  const dartRes = runCapture(`dart run "${dartPath}"`);
  const dartLines = splitLines(dartRes.stdout);
  if (dartRes.status !== 0 || dartLines.length === 0) {
    console.error('Dart 端执行失败：\n' + dartRes.stderr);
    process.exit(1);
  }

  let pass = 0;
  let fail = 0;
  const rows = [];
  const n = Math.max(moonLines.length, dartLines.length, cases.length);
  for (let i = 0; i < n; i++) {
    const moonVal = moonLines[i] ?? '(无输出)';
    const dartVal = dartLines[i] ?? '(无输出)';
    const expr = cases[i] ? cases[i][0] : `line ${i + 1}`;
    const desc = cases[i] ? cases[i][1] : '';
    const ok = moonVal === dartVal;
    if (ok) pass++;
    else fail++;
    rows.push({ i: i + 1, expr, desc, moonVal, dartVal, ok });
  }

  const md = [];
  md.push(`# ${title} | Golden Dual-Runtime Comparison`);
  md.push('');
  md.push('> 生成：scripts/golden_check.mjs · 转换模式：wrapping + fail-closed（--on-unresolved error）· 真值端：MoonBit native · 执行端：`dart run`（Dart SDK 3.12.2, Dart VM）');
  md.push('');
  md.push(`> 同一份 MoonBit 源码（\`${fixture.replace(ROOT, '').replace(/\\/g, '/')}\`），两端各自**实际执行**。逐行输出对比：`);
  md.push('');
  md.push('| # | 输入表达式 | 说明 | MoonBit 输出 | Dart 输出 | 一致 |');
  md.push('|---|-----------|------|-------------|-----------|:----:|');
  for (const r of rows) {
    md.push(`| ${r.i} | \`${r.expr}\` | ${r.desc} | \`${r.moonVal}\` | \`${r.dartVal}\` | ${r.ok ? '✅' : '❌'} |`);
  }
  md.push('');
  md.push(`**结论**：${pass}/${rows.length} 行一致`);
  md.push('');
  writeFileSync(join(ROOT, 'docs', mdFile), md.join('\n'), 'utf8');

  console.log(`结果：${pass} 通过 / ${fail} 不一致（共 ${rows.length} 行）`);
  return { rows, pass, fail };
}

const arithmeticCases = [
  ['wrap_add(2147483647, 1)', '组委会反例：上界溢出回绕 → INT_MIN'],
  ['wrap_add(-2147483647, -1)', '下界回绕 → INT_MIN'],
  ['wrap_sub(-2147483647, 2)', '下界回绕 → INT_MAX'],
  ['wrap_mul(65536, 65536)', '2^32 回绕 → 0'],
  ['wrap_mul(100000, 100000)', '10^10 回绕 → 1410065408'],
  ['trunc_div(7, 2)', '正数整除（~/，非浮点除法）'],
  ['trunc_div(-7, 2)', '负被除数向零截断 → -3'],
  ['trunc_div(7, -2)', '负除数向零截断 → -3'],
  ['trunc_rem(-7, 2)', '截断余数符号跟被除数 → -1（Dart % 会得 1）'],
  ['trunc_rem(7, -2)', '截断余数符号跟被除数 → 1'],
  ['add64(1073741824, 1073741824)', 'Int64 64 位加法不溢出 → 2147483648（限 Dart VM）'],
  ['ratio(7.0, 2.0)', 'Double IEEE 754 除法 → 3.5'],
  ['lt(2147483647, -2147483647)', '回绕语义下比较一致 → false'],
  ['join_str("moon", "bit")', '字符串拼接 → moonbit'],
];

const businessCases = [
  ['sum([])', '空数组：循环 0 次 → 0'],
  ['sum([1, 2, 3, 4])', 'Array 求和（索引 + 累加）→ 10'],
  ['sum([2147483647, 1])', '数组元素参与 32 位回绕 → -2147483648'],
  ['count_positive([-2, 0, 5, 7])', '条件计数（if 表达式）→ 2'],
  ['max_or([3, 9, 2], -1)', 'while 求最大值 → 9'],
  ['max_or([], -1)', '空数组走默认分支 → -1'],
  ['build_squares(4).length()', 'push 构建数组，长度 → 4'],
  ['build_squares(4)[3]', '构建后索引 → 9'],
  ['first_or([42, 7], -1)', '首元素索引 → 42'],
  ['first_or([], -1)', '空数组索引保护 → -1'],
  ['same([1, 2], [1, 2])', '集合相等：逐元素比较（Dart == 默认引用比较）→ true'],
  ['same([1, 2], [2, 1])', '集合相等：顺序不同 → false'],
  ['same([], [])', '空集合相等 → true'],
];

// A. 算术语义
const a = checkGroup({
  title: 'golden 双端运行对比（算术语义）',
  goldenCmd: 'moon run golden --target native',
  fixture: join(ROOT, 'scripts', 'golden_fixture', 'fixture.mbt'),
  cases: arithmeticCases,
  outFile: 'main.dart',
  mdFile: 'golden_results.md',
});

// B. 业务函数（Array→List）
const b = checkGroup({
  title: 'golden 双端运行对比（业务函数 · Array→List）',
  goldenCmd: 'moon run golden_business --target native',
  fixture: join(ROOT, 'scripts', 'golden_fixture', 'business.mbt'),
  cases: businessCases,
  outFile: 'business.dart',
  mdFile: 'golden_results_business.md',
});

// C. trap 边界验证（Dart 端）
console.log('\n=== trap 边界验证 ===');
const dartCode = run(
  `moon run cmd/main --target native -- convert "${join(ROOT, 'scripts', 'golden_fixture', 'fixture.mbt')}" --semantics wrapping`,
);
const shimDefs = dartCode
  .split('\n')
  .filter((l) => l.startsWith('int mb32Div') || l.startsWith('int mb32Rem'))
  .join('\n');
const trapProbe = `${shimDefs}\nvoid main() {\n  try {\n    mb32Div(-2147483648, -1);\n    print('NO-TRAP');\n  } catch (e) {\n    print('TRAP');\n  }\n  try {\n    mb32Rem(7, 0);\n    print('NO-TRAP');\n  } catch (e) {\n    print('TRAP');\n  }\n}\n`;
const trapPath = join(WORK, 'trap_probe.dart');
writeFileSync(trapPath, trapProbe, 'utf8');
const trapLines = splitLines(runCapture(`dart run "${trapPath}"`).stdout);
const divTrap = trapLines[0] === 'TRAP';
const remTrap = trapLines[1] === 'TRAP';
console.log(`  mb32Div(INT_MIN, -1) → ${divTrap ? 'TRAP' : 'NO-TRAP'}；mb32Rem(7, 0) → ${remTrap ? 'TRAP' : 'NO-TRAP'}`);

console.log('\n=== 汇总 ===');
console.log(`算术语义：${a.pass}/${a.rows.length}`);
console.log(`业务函数：${b.pass}/${b.rows.length}`);
const totalFail = a.fail + b.fail;
if (totalFail > 0 || !divTrap || !remTrap) {
  console.error(`FAIL: ${totalFail} 行不一致，trap=${divTrap && remTrap}`);
  process.exit(1);
}
console.log('PASS: 全部一致');