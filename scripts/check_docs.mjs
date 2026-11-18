#!/usr/bin/env node
// check_docs.mjs — 文档数字一致性自检（最小闭环 · flutter-ohos-expert 思想 ②⑥③）
//
// 背景：README/AGENTS 的数字（测试数/版本）曾出现口径漂移（README 364 vs AGENTS 383）。
// 断言化根治：跨文档不一致，本脚本变红。
//
// 用法：node scripts/check_docs.mjs [--self-test]
// 退出码：全绿 0；任一断言失败 1。

import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

function cap(re, text, file, what) {
  const m = text.match(re);
  if (!m) throw new Error(`${what}: not found in ${file}`);
  return { value: m[1], evidence: { file, pattern: String(re), matched: m[0] } };
}

async function read(rel, root) {
  return readFile(path.join(root, rel), 'utf8');
}

function extractChangelogLatest(text) {
  const m = text.match(/^## \[?([\d.]+)\]?/m);
  if (!m) throw new Error('latest version not found in docs/changelog.md');
  return m[1];
}

const ASSERTIONS = [
  {
    id: 'B1', desc: 'moon.mod version == 0.1.1 且 docs/changelog.md 含版本双轨说明',
    async run(root) {
      const mod = cap(/^version = "([^"]+)"/m, await read('moon.mod', root), 'moon.mod', 'version').value;
      if (mod !== '0.1.1') throw new Error(`moon.mod=${mod} != 0.1.1（包版本沿 0.1.x 线：0.1.1 = 功能 v0.11.0）`);
      const cl = await read('docs/changelog.md', root);
      if (!cl.includes('版本双轨说明')) throw new Error('docs/changelog.md 缺「版本双轨说明」（0.1.x 重置映射）');
      return { moon_mod: mod, dual_track: 'present' };
    },
  },
  {
    id: 'B2', desc: 'README 测试数 == AGENTS.md 测试节数字（当前口径）',
    async run(root) {
      const readme = await read('README.md', root);
      const agents = await read('AGENTS.md', root);
      const readmeN = cap(/(\d+) 个测试/, readme, 'README.md', 'readme tests').value;
      const agentsN = cap(/### 测试\s*\n+\*{0,2}(\d+) 个测试/, agents, 'AGENTS.md', 'agents tests section').value;
      if (readmeN !== agentsN) throw new Error(`README=${readmeN} != AGENTS(测试节)=${agentsN}`);
      return { readme: readmeN, agents_section: agentsN };
    },
  },
  {
    id: 'B3', desc: 'README 文档表引用的 docs/*.md 全部存在（防死链）',
    async run(root) {
      const readme = await read('README.md', root);
      const links = [...readme.matchAll(/\]\((docs\/[\w.-]+\.md)\)/g)].map(m => m[1]);
      const missing = links.filter(f => !existsSync(path.join(root, f)));
      if (missing.length) throw new Error(`missing docs: ${missing.join(', ')}`);
      return { checked: links.length, files: links };
    },
  },
  {
    id: 'B4', desc: 'README 安装/快速开始引用的 mooncakes 包名 == moon.mod name',
    async run(root) {
      const mod = cap(/^name = "([^"]+)"/m, await read('moon.mod', root), 'moon.mod', 'name').value;
      const readme = await read('README.md', root);
      const addPkg = cap(/moon add (walkzzz\/[\w-]+)/, readme, 'README.md', 'moon add').value;
      if (mod !== addPkg) throw new Error(`moon.mod name=${mod} != README moon add=${addPkg}`);
      return { moon_mod: mod, readme_moon_add: addPkg };
    },
  },
];

async function runAssertions(root) {
  const results = [];
  for (const a of ASSERTIONS) {
    try {
      const evidence = await a.run(root);
      results.push({ id: a.id, desc: a.desc, ok: true, evidence });
    } catch (e) {
      results.push({ id: a.id, desc: a.desc, ok: false, fail: String(e.message) });
    }
  }
  const failed = results.filter(r => !r.ok).length;
  return { schema: 'check_docs@1', root, total: results.length, failed, results };
}

async function selfTest() {
  const tmp = path.join(os.tmpdir(), `checkdocs-selftest-${Date.now()}`);
  await mkdir(path.join(tmp, 'docs'), { recursive: true });
  const out = [];
  const writeFixtures = async (version, tests) => {
    await writeFile(path.join(tmp, 'moon.mod'), `name = "walkzzz/moon2dart"\n\nversion = "${version}"\n`);
    await writeFile(path.join(tmp, 'README.md'), `# moon2dart\n\n${tests} 个测试，native 后端全通过：\n\n\`\`\`bash\nmoon add walkzzz/moon2dart\n\`\`\`\n`);
    await writeFile(path.join(tmp, 'AGENTS.md'), `- **v0.9.1** ✅ 已完成 — 项目双向同步 + 冲突检测\n\n### 测试\n\n${tests} 个测试，native 后端全通过：\n`);
    await writeFile(path.join(tmp, 'docs', 'changelog.md'), `# Changelog\n\n> **版本双轨说明**（2026-11-13）：功能迭代版本（v0.1.0 → v0.9.1）为 Sprint 史；mooncakes 包版本重置为 0.1.0。\n\n## [${version}] - 2026-11-13\n`);
  };
  const assertThrows = async (id, expectId) => {
    const r = await runAssertions(tmp);
    const hit = r.results.find(x => x.id === expectId);
    if (!hit || hit.ok !== false) throw new Error(`${id}: expected ${expectId} to FAIL, but it passed`);
    out.push(`${id}: OK (${expectId} correctly failed: ${String(hit.fail).slice(0, 60)})`);
  };
  try {
    // 负向 1：moon.mod 与 changelog 最新条目不一致（0.1.1 vs 0.9.1 —— 版本重置场景的映射错误）
    await await writeFixtures('0.1.1', '383');
    await writeFile(path.join(tmp, 'docs', 'changelog.md'), '# Changelog\n\n## [0.9.1] - 2026-11-12\n');
    await assertThrows('ST1', 'B1');
    // 负向 2：README 测试数漂移（364 vs 383 —— 本项目真实发生过的漂移）
    await await writeFixtures('0.1.1', '383');
    await writeFile(path.join(tmp, 'README.md'), (await readFile(path.join(tmp, 'README.md'), 'utf8')).replace('383 个测试', '364 个测试'));
    await assertThrows('ST2', 'B2');
    // 负向 3：文档死链（fixture 追加文档表行，再制造坏链）
    await await writeFixtures('0.1.1', '383');
    await writeFile(path.join(tmp, 'README.md'), (await readFile(path.join(tmp, 'README.md'), 'utf8')) + '\n| [architecture](docs/architecture.md) | x |\n| [ghost](docs/ghost.md) | x |\n');
    await writeFile(path.join(tmp, 'README.md'), (await readFile(path.join(tmp, 'README.md'), 'utf8')).replace('docs/architecture.md', 'docs/ghost.md'));
    await assertThrows('ST3', 'B3');
    // 正向：全一致 → B1-B4 全绿
    await await writeFixtures('0.1.1', '383');
    const okRun = await runAssertions(tmp);
    for (const id of ['B1', 'B2', 'B3', 'B4']) {
      const hit = okRun.results.find(x => x.id === id);
      if (!hit || !hit.ok) throw new Error(`ST4: expected ${id} to PASS on consistent fixture`);
      out.push(`ST4: OK (${id} passed)`);
    }
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
  return { schema: 'check_docs-selftest@1', assertions: out };
}

const selftest = process.argv.includes('--self-test');
if (selftest) {
  selfTest().then(r => { console.log(JSON.stringify(r, null, 2)); process.exit(0); }).catch(e => { console.error(String(e.message)); process.exit(1); });
} else {
  runAssertions(ROOT).then(r => { console.log(JSON.stringify(r, null, 2)); process.exit(r.failed === 0 ? 0 : 1); });
}
