#!/usr/bin/env node
// 真实语料接受率报告（官方 parser 直连 vs 兼容模式）— 借鉴 mizchi/mbt_rs 的 `--report` 做法。
// Acceptance report on real files: official-parser-only vs compat (official + legacy fallback).
//
// 用法：node scripts/acceptance_report.mjs
// 输出：控制台摘要 + docs/acceptance_report.md

import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));

const TARGETS = [
  ['scripts/golden_fixture/fixture.mbt', '算术 fixture（14 行语义）'],
  ['scripts/golden_fixture/business.mbt', '业务函数 fixture（Array/while/push）'],
  ['golden/golden.mbt', '算术真值端'],
  ['golden_business/golden_business.mbt', '业务真值端'],
  ['moon2dart.mbt', '库入口（管线 + Options）'],
  ['ast/ast.mbt', 'AST 定义（struct/enum/derive）'],
  ['parser/parser.mbt', '手写 parser（大文件）'],
  ['cmd/main/main.mbt', 'CLI（async/match/方法）'],
  ['typesys/mapping.mbt', '类型映射（大量 match）'],
];

function convert(rel, extra) {
  const started = Date.now();
  const r = spawnSync(
    `moon run cmd/main --target native -- convert "${join(ROOT, rel)}" --semantics wrapping --on-unresolved error ${extra}`,
    { shell: true, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, cwd: ROOT },
  );
  const ms = Date.now() - started;
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  const accepted = r.status === 0 && !out.includes('Error:');
  let reason = '';
  if (!accepted) {
    if (out.includes('UNRESOLVED')) reason = 'UNRESOLVED（推断失败，fail-closed）';
    else if (out.includes('official parser: unsupported')) {
      reason = out.split('\n').find((l) => l.includes('unsupported'))?.replace('Error: ', '') ?? 'official parser unsupported';
    } else if (out.includes('official parser reported')) reason = '官方 parser 语法错误';
    else if (out.includes('ParseError') || out.includes('unexpected token')) reason = 'ParseError（子集外语法）';
    else if (out.includes('Error:')) reason = 'Transpile/Type 错误';
    else reason = `exit=${r.status}`;
  }
  return { accepted, reason, ms, outLines: (r.stdout ?? '').split(/\r?\n/).filter(Boolean).length };
}

const results = TARGETS.map(([rel, desc]) => {
  const official = convert(rel, '--official-only');
  const compat = convert(rel, '');
  return { rel, desc, official, compat };
});

const offOk = results.filter((x) => x.official.accepted).length;
const compatOk = results.filter((x) => x.compat.accepted).length;
const total = results.length;

console.log('=== acceptance report ===');
for (const r of results) {
  console.log(
    `${r.official.accepted ? 'OFFICIAL' : 'FALLBACK'}  ${r.rel}${r.official.reason ? `  — ${r.official.reason}` : ''}`,
  );
}
console.log(`official ${offOk}/${total} (${Math.round((offOk / total) * 100)}%), compat ${compatOk}/${total}`);

const md = [];
md.push('# 真实语料接受率报告 | Acceptance Report on Real Sources');
md.push('');
md.push('> 生成：`scripts/acceptance_report.mjs` · 管线：`--semantics wrapping --on-unresolved error`');
md.push('> 两列口径：**官方直连** = `--official-only`（moonbitlang/parser，不回落）；**兼容模式** = 官方优先 + 旧 parser 语法兜底。');
md.push('');
md.push('| 文件 | 说明 | 官方直连 | 兼容模式 | 官方拒绝原因 | 产物行数 |');
md.push('|---|---|:---:|:---:|---|---:|');
for (const r of results) {
  md.push(
    `| \`${r.rel}\` | ${r.desc} | ${r.official.accepted ? '✅' : '❌'} | ${r.compat.accepted ? '✅' : '❌'} | ${r.official.reason || '—'} | ${r.official.accepted ? r.official.outLines : r.compat.outLines} |`,
  );
}
md.push('');
md.push(`**汇总**：官方直连 **${offOk}/${total}**（${Math.round((offOk / total) * 100)}%）；兼容模式 **${compatOk}/${total}**（${Math.round((compatOk / total) * 100)}%）。`);
md.push('');
md.push('## 口径说明 | Scope');
md.push('');
md.push('- **官方直连**衡量"官方 parser + 适配层"的技术债剩余面；拒绝项是子集外语法/节点，属于显式 fail-closed；');
md.push('- **兼容模式**衡量当前可用范围：官方 parser 优先，仅在语法层失败时回退旧 parser（不改变语义策略）；');
md.push('- 业务函数（Array/while/push/相等）与算术 fixture 在官方直连下均应被接受；核心实现文件暴露下一阶段要补的语法面（match 深嵌套、复杂泛型、异步/方法链等）。');
md.push('');
md.push('## 复现 | Reproduce');
md.push('');
md.push('```bash');
md.push('node scripts/acceptance_report.mjs');
md.push('node scripts/acceptance_report.mjs   # 官方直连列由 --official-only 触发');
md.push('```');
writeFileSync(join(ROOT, 'docs', 'acceptance_report.md'), md.join('\n'), 'utf8');
console.log('报告已写入 docs/acceptance_report.md');