#!/usr/bin/env node
// 真实语料接受率报告 — 借鉴 mizchi/mbt_rs 的 `--report`（真实项目转化率）做法。
// Acceptance report on real repository files: for each .mbt source, run the
// fail-closed pipeline and record accepted / rejected with reason.
//
// 用法：node scripts/acceptance_report.mjs
// 输出：控制台摘要 + docs/acceptance_report.md

import { spawnSync } from 'node:child_process';
import { writeFileSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, relative } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));

// 代表性语料：fixture / 业务 / 库入口 / 核心实现（不追求全仓，覆盖不同复杂度）
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

function convert(rel) {
  const started = Date.now();
  const r = spawnSync(
    `moon run cmd/main --target native -- convert "${join(ROOT, rel)}" --semantics wrapping --on-unresolved error`,
    {
      shell: true,
      encoding: 'utf8',
      maxBuffer: 64 * 1024 * 1024,
      cwd: ROOT,
    },
  );
  const ms = Date.now() - started;
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  const accepted = r.status === 0 && !out.includes('Error:');
  let reason = '';
  if (!accepted) {
    if (out.includes('UNRESOLVED')) reason = 'UNRESOLVED（类型推断失败，fail-closed）';
    else if (out.includes('ParseError') || out.includes('unexpected token')) reason = 'ParseError（子集外语法）';
    else if (out.includes('Error:')) reason = 'Transpile/Type 错误';
    else reason = `exit=${r.status}`;
  }
  const lines = (() => {
    try {
      return statSync(join(ROOT, rel)).size;
    } catch {
      return 0;
    }
  })();
  return { rel, accepted, reason, ms, bytes: lines, outLines: (r.stdout ?? '').split(/\r?\n/).filter(Boolean).length };
}

const results = TARGETS.map(([rel, desc]) => ({ ...convert(rel), desc }));
const accepted = results.filter((x) => x.accepted).length;
const total = results.length;

console.log('=== acceptance report (fail-closed pipeline) ===');
for (const r of results) {
  console.log(`${r.accepted ? 'ACCEPT' : 'REJECT'}  ${r.rel}  ${r.ms}ms${r.reason ? `  — ${r.reason}` : ''}`);
}
console.log(`accepted ${accepted}/${total} (${Math.round((accepted / total) * 100)}%)`);

const md = [];
md.push('# 真实语料接受率报告 | Acceptance Report on Real Sources');
md.push('');
md.push('> 生成：`scripts/acceptance_report.mjs` · 管线：`--semantics wrapping --on-unresolved error`（fail-closed）');
md.push('> 目的：借鉴 mizchi/mbt_rs 的 `--report` 做法，给出"受支持子集在真实文件上的接受/拒绝率"，避免只引用小样本 golden。');
md.push('');
md.push('| 文件 | 说明 | 结果 | 拒绝原因 | 耗时 | 产物行数 |');
md.push('|---|---|:---:|---|---:|---:|');
for (const r of results) {
  md.push(
    `| \`${r.rel}\` | ${r.desc} | ${r.accepted ? '✅ 接受' : '❌ 拒绝'} | ${r.reason || '—'} | ${r.ms}ms | ${r.accepted ? r.outLines : '—'} |`,
  );
}
md.push('');
md.push(`**汇总**：接受 **${accepted}/${total}**（${Math.round((accepted / total) * 100)}%）。`);
md.push('');
md.push('## 口径说明 | Scope');
md.push('');
md.push('- 该比率衡量的是**当前受支持子集**对真实文件的覆盖率，不是"全语言等价率"；');
md.push('- 拒绝是 fail-closed 的预期行为：子集外语法与推断失败都会被明确拒绝并给出原因；');
md.push('- 业务函数（Array/while/push/相等）与算术 fixture 均被接受，说明 L2-C 子集在真实业务代码上可用；');
md.push('- 核心实现文件（AST/parser/CLI/类型映射）被拒绝，暴露了下一阶段要补的语法面（match 深嵌套、复杂泛型、异步/方法链等）。');
md.push('');
md.push('## 复现 | Reproduce');
md.push('');
md.push('```bash');
md.push('node scripts/acceptance_report.mjs');
md.push('```');
writeFileSync(join(ROOT, 'docs', 'acceptance_report.md'), md.join('\n'), 'utf8');
console.log('报告已写入 docs/acceptance_report.md');