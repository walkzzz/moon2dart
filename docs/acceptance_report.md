# 真实语料接受率报告 | Acceptance Report on Real Sources

> 生成：`scripts/acceptance_report.mjs` · 管线：`--semantics wrapping --on-unresolved error`（fail-closed）
> 目的：借鉴 mizchi/mbt_rs 的 `--report` 做法，给出"受支持子集在真实文件上的接受/拒绝率"，避免只引用小样本 golden。

| 文件 | 说明 | 结果 | 拒绝原因 | 耗时 | 产物行数 |
|---|---|:---:|---|---:|---:|
| `scripts/golden_fixture/fixture.mbt` | 算术 fixture（14 行语义） | ✅ 接受 | — | 421ms | 51 |
| `scripts/golden_fixture/business.mbt` | 业务函数 fixture（Array/while/push） | ✅ 接受 | — | 460ms | 90 |
| `golden/golden.mbt` | 算术真值端 | ✅ 接受 | — | 342ms | 51 |
| `golden_business/golden_business.mbt` | 业务真值端 | ✅ 接受 | — | 450ms | 90 |
| `moon2dart.mbt` | 库入口（管线 + Options） | ❌ 拒绝 | ParseError（子集外语法） | 595ms | — |
| `ast/ast.mbt` | AST 定义（struct/enum/derive） | ❌ 拒绝 | Transpile/Type 错误 | 583ms | — |
| `parser/parser.mbt` | 手写 parser（大文件） | ❌ 拒绝 | ParseError（子集外语法） | 662ms | — |
| `cmd/main/main.mbt` | CLI（async/match/方法） | ❌ 拒绝 | ParseError（子集外语法） | 569ms | — |
| `typesys/mapping.mbt` | 类型映射（大量 match） | ❌ 拒绝 | ParseError（子集外语法） | 584ms | — |

**汇总**：接受 **4/9**（44%）。

## 口径说明 | Scope

- 该比率衡量的是**当前受支持子集**对真实文件的覆盖率，不是"全语言等价率"；
- 拒绝是 fail-closed 的预期行为：子集外语法与推断失败都会被明确拒绝并给出原因；
- 业务函数（Array/while/push/相等）与算术 fixture 均被接受，说明 L2-C 子集在真实业务代码上可用；
- 核心实现文件（AST/parser/CLI/类型映射）被拒绝，暴露了下一阶段要补的语法面（match 深嵌套、复杂泛型、异步/方法链等）。

## 复现 | Reproduce

```bash
node scripts/acceptance_report.mjs
```