#!/usr/bin/env node
// 安全边界门禁 — 验证 fail-closed、可审计报告、幂等性与集合相等语义（v0.12.0）
// Safety-boundary gate: fail-closed, auditable report, idempotence and collection equality.
//
// 用法：node scripts/safety_gate.mjs
// 前置：moon 工具链（native 目标）。

import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const WORK = join(ROOT, 'golden_out');
mkdirSync(WORK, { recursive: true });

function runCapture(cmd) {
  const r = spawnSync(cmd, {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    cwd: ROOT,
  });
  return { stdout: r.stdout ?? '', stderr: r.stderr ?? '', status: r.status };
}

function convert(fixture, extra) {
  return runCapture(
    `moon run cmd/main --target native -- convert "${join(ROOT, 'scripts', 'golden_fixture', fixture)}" ${extra ?? ''}`,
  );
}

let failures = 0;
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  (${detail})` : ''}`);
  if (!ok) failures++;
}

// 1. fail-closed：未注解算术必须拒绝且非零退出
const rejected = convert('unresolved.mbt', '--on-unresolved error');
check(
  'fail-closed: unannotated arithmetic rejected (non-zero exit + UNRESOLVED)',
  rejected.status !== 0 &&
    (rejected.stdout + rejected.stderr).includes('UNRESOLVED'),
  `status=${rejected.status}`,
);

// 2. warn：标注 + 报告落盘（JSON 可机读、MD 可审计）
const reportBase = join(WORK, 'safety');
const warned = convert('unresolved.mbt', `--on-unresolved warn --report "${reportBase}"`);
let reportJson = '';
try {
  reportJson = readFileSync(`${reportBase}.json`, 'utf8');
} catch {
  reportJson = '';
}
let reportMd = '';
try {
  reportMd = readFileSync(`${reportBase}.md`, 'utf8');
} catch {
  reportMd = '';
}
const reportObj = (() => {
  try {
    return JSON.parse(reportJson);
  } catch {
    return null;
  }
})();
check(
  'warn: conversion succeeds with [L2-UNRESOLVED] annotation',
  warned.status === 0 && warned.stdout.includes('[L2-UNRESOLVED]'),
  `status=${warned.status}`,
);
check(
  'warn: report JSON is machine-readable with unresolved count',
  !!reportObj && Array.isArray(reportObj.unresolved) && reportObj.unresolved.length === 1,
);
check(
  'warn: report Markdown is human-auditable',
  reportMd.includes('# moon2dart 安全报告') && reportMd.includes('UNRESOLVED_ARITH'),
);

// 3. 未支持语法 fail-closed（解析器不静默跳过）
const unsupported = convert('unsupported_for.mbt', '--on-unresolved error');
check(
  'fail-closed: unsupported syntax rejected (non-zero exit)',
  unsupported.status !== 0,
  `status=${unsupported.status}`,
);

// 4. 幂等性：同一输入两次转换 byte-identical
const a = convert('business.mbt', '--semantics wrapping --on-unresolved error');
const b = convert('business.mbt', '--semantics wrapping --on-unresolved error');
check(
  'idempotence: two conversions are byte-identical',
  a.status === 0 && b.status === 0 && a.stdout === b.stdout,
);

// 5. 集合相等语义：Array→List 必须发射 mbEquals（MoonBit 逐元素 vs Dart 引用）
check(
  'collection equality: mbEquals emitted and used',
  a.stdout.includes('bool mbEquals(dynamic a, dynamic b)') &&
    a.stdout.includes('mbEquals(xs, ys)'),
);

// 6. 32 位回绕在数组业务函数中保留
check(
  'wrapping survives array business functions',
  a.stdout.includes('mb32Add') && a.stdout.includes('mb32Mul'),
);

console.log(`\n=== safety gate: ${failures === 0 ? 'PASS' : `FAIL (${failures})`} ===`);
if (failures > 0) process.exit(1);