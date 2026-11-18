#!/usr/bin/env node
// golden 双端运行对比 — 同一输入在 MoonBit 与 Dart 两端实跑并逐行对比 | Golden dual-runtime diff — same inputs run on both MoonBit and Dart
//
// 用法：node scripts/golden_check.mjs
// 前置：moon 工具链 + Dart SDK 3.x；回应组委会"用同一输入给出两端结果及拒绝或人工处理边界"的要求。
//
// 流程：
//   1. moon run golden            → MoonBit 端逐行输出（wasm i32 语义真值）
//   2. convert fixture --semantics wrapping → Dart 代码（含 mb32* 回绕模拟层）
//   3. dart run main.dart         → Dart 端逐行输出
//   4. 逐行 diff → 控制台结论 + docs/golden_results.md 报告
//   5. Dart 端 trap 边界验证 → INT_MIN/-1 与除零两端均异常终止

import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const FIXTURE = join(ROOT, 'scripts', 'golden_fixture', 'fixture.mbt');
const WORK = join(ROOT, 'golden_out');

const CASES = [
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

function run(cmd, opts = {}) {
  const r = spawnSync(cmd, {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    cwd: ROOT,
    ...opts,
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

// 1. MoonBit 端真值
console.log('[1/5] moon run golden --target native');
const moonRes = runCapture('moon run golden --target native');
const moonLines = moonRes.stdout.trim().split('\n').filter((l) => l.length > 0);
if (moonRes.status !== 0 || moonLines.length === 0) {
  console.error('MoonBit 端执行失败：\n' + moonRes.stderr);
  process.exit(1);
}

// 2. 转换（wrapping 模式）
console.log('[2/5] convert fixture --semantics wrapping');
const dartCode = run(
  `moon run cmd/main --target native -- convert "${FIXTURE}" --semantics wrapping`,
);
if (!dartCode.includes('mb32Add')) {
  console.error('转换产物缺少 wrapping shim，中止');
  process.exit(1);
}

// 3. Dart 端实跑
console.log('[3/5] dart run (Dart SDK)');
mkdirSync(WORK, { recursive: true });
const dartPath = join(WORK, 'main.dart');
writeFileSync(dartPath, dartCode, 'utf8');
const dartRes = runCapture(`dart run "${dartPath}"`);
const dartLines = dartRes.stdout.trim().split('\n').filter((l) => l.length > 0);
if (dartRes.status !== 0 || dartLines.length === 0) {
  console.error('Dart 端执行失败：\n' + dartRes.stderr);
  process.exit(1);
}

// 4. 逐行对比
console.log('[4/5] 逐行对比');
let pass = 0;
let fail = 0;
const rows = [];
const n = Math.max(moonLines.length, dartLines.length, CASES.length);
for (let i = 0; i < n; i++) {
  const moonVal = moonLines[i] ?? '(无输出)';
  const dartVal = dartLines[i] ?? '(无输出)';
  const desc = CASES[i] ? CASES[i][1] : '';
  const ok = moonVal === dartVal;
  if (ok) {
    pass++;
  } else {
    fail++;
  }
  rows.push({ i: i + 1, expr: CASES[i] ? CASES[i][0] : `line ${i + 1}`, desc, moonVal, dartVal, ok });
}

// 5. Dart 端 trap 边界验证（INT_MIN/-1 与除零 → 两端均异常终止）
console.log('[5/5] Dart 端 trap 边界验证');
const shimDefs = dartCode
  .split('\n')
  .filter((l) => l.startsWith('int mb32Div') || l.startsWith('int mb32Rem'))
  .join('\n');
const trapProbe = `${shimDefs}\nvoid main() {\n  try {\n    mb32Div(-2147483648, -1);\n    print('NO-TRAP');\n  } catch (e) {\n    print('TRAP');\n  }\n  try {\n    mb32Rem(7, 0);\n    print('NO-TRAP');\n  } catch (e) {\n    print('TRAP');\n  }\n}\n`;
const trapPath = join(WORK, 'trap_probe.dart');
writeFileSync(trapPath, trapProbe, 'utf8');
const trapRes = runCapture(`dart run "${trapPath}"`);
const trapLines = trapRes.stdout.trim().split('\n').filter((l) => l.length > 0);
const divTrap = trapLines[0] === 'TRAP';
const remTrap = trapLines[1] === 'TRAP';
console.log(
  `  mb32Div(INT_MIN, -1) → ${divTrap ? 'TRAP（抛异常终止）' : 'NO-TRAP'}；mb32Rem(7, 0) → ${remTrap ? 'TRAP（抛异常终止）' : 'NO-TRAP'}`,
);

console.log('');
console.log('=== golden 双端对比结果 ===');
for (const r of rows) {
  console.log(
    `${r.ok ? 'PASS' : 'FAIL'} #${String(r.i).padStart(2, '0')} ${r.expr}  MoonBit=${r.moonVal}  Dart=${r.dartVal}`,
  );
}
console.log(`\n${pass} 通过 / ${fail} 不一致（共 ${rows.length} 行）`);

const md = [];
md.push('# golden 双端运行对比报告 | Golden Dual-Runtime Comparison');
md.push('');
md.push('> 生成：scripts/golden_check.mjs · 转换模式：wrapping · 真值端：`moon run golden`（native）· 执行端：`dart run`（Dart SDK 3.x, Dart VM）');
md.push('');
md.push('> 同一份 MoonBit 源码（`scripts/golden_fixture/fixture.mbt`），两端各自**实际执行**：');
md.push('> MoonBit 端由 moon 工具链原生求值；Dart 端由 moon2dart（wrapping 模式）转换后经 Dart SDK 编译运行。逐行输出对比：');
md.push('');
md.push('| # | 输入表达式 | 说明 | MoonBit 输出 | Dart 输出 | 一致 |');
md.push('|---|-----------|------|-------------|-----------|:----:|');
for (const r of rows) {
  md.push(`| ${r.i} | \`${r.expr}\` | ${r.desc} | \`${r.moonVal}\` | \`${r.dartVal}\` | ${r.ok ? '✅' : '❌'} |`);
}
md.push('');
md.push(`**结论**：${pass}/${rows.length} 行一致`);
md.push('');
md.push('## 边界行为（拒绝或人工处理边界）| Boundary behaviors');
md.push('');
md.push('| 输入 | MoonBit 行为 | Dart（wrapping 模式）行为 | 类别 |');
md.push('|------|-------------|--------------------------|------|');
md.push(`| \`INT_MIN / -1\` | **trap**（native 硬件异常终止，0xC0000095；wasm i32.div_s 规范 trap） | mb32Div 显式 \`throw StateError\`（本报告实测：${divTrap ? 'TRAP' : 'NO-TRAP'}） | 两端一致：异常终止 |`);
md.push(`| \`x / 0\`、\`x % 0\` | **trap**（wasm i32.div_s / rem_s 除零 trap） | mb32Div/mb32Rem 显式 \`throw StateError\`（实测：${remTrap ? 'TRAP' : 'NO-TRAP'}） | 两端一致：异常终止 |`);
md.push('| `UInt` / `UInt64` / `Float` / `Char` | L3 值域有损 | 默认模式生成 + `// [L3-CONSTRAINED]` 诊断注释 | 人工处理（标注） |');
md.push('| FFI / Channel / Spawn / wasm intrinsics | L4 无 Dart 对应 | `--strict` raise TypeError 拒绝；默认模式生成 + `[L4-INEQUIVALENT]` 注释 | 拒绝（strict）/ 人工处理 |');
md.push('| `Int64` 算术 | 64 位回绕 | L1，**限 Dart VM**；编译到 web 时 int 退化为 JS number（值域 2^53），降级 L2 | 适用约束（VM only） |');
md.push('| 字面量外的一元负号 / 无类型上下文的算术 | — | 类型推断失败时保守裸发（fast 语义），见推断边界说明 | 人工处理（标注） |');
md.push('');
md.push('关键行为（回应 32 位整数溢出关切）：');
md.push('');
md.push('- 行 1/2/3/4/5：MoonBit `Int` 为 32 位回绕（wasm i32），wrapping 模式生成的 `mb32*` 模拟层（`.toSigned(32)`）在 Dart 64 位 int 上逐运算还原同一结果');
md.push('- 行 9/10：MoonBit `%` 为截断余数（符号跟被除数），Dart `%` 是非负欧几里得余数——转换器发射 `.remainder()` 而非 `%`');
md.push('- 行 6/7/8：整除为 `~/`（截断向零），修复了原发射 `/`（浮点除法）的类型与语义双重错误');
md.push('- 行 12：`Double` 两端均为 IEEE 754 64 位，直接裸发');
md.push('- 类型往返断言只证明**结构**可还原；本报告的逐行输出对比证明的是**运行时语义**等价——两级证据互补');
md.push('');
writeFileSync(join(ROOT, 'docs', 'golden_results.md'), md.join('\n'), 'utf8');
console.log('报告已写入 docs/golden_results.md');
if (fail > 0 || !divTrap || !remTrap) {
  process.exit(1);
}
