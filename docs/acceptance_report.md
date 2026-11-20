# 真实语料接受率报告 | Acceptance Report on Real Sources

> 生成：`scripts/acceptance_report.mjs` · 管线：`--semantics wrapping --on-unresolved error`
> 两列口径：**官方直连** = `--official-only`（moonbitlang/parser，不回落）；**兼容模式** = 官方优先 + 旧 parser 语法兜底。

| 文件 | 说明 | 官方直连 | 兼容模式 | 官方拒绝原因 | 产物行数 |
|---|---|:---:|:---:|---|---:|
| `scripts/golden_fixture/fixture.mbt` | 算术 fixture（14 行语义） | ✅ | ✅ | — | 51 |
| `scripts/golden_fixture/business.mbt` | 业务函数 fixture（Array/while/push） | ✅ | ✅ | — | 90 |
| `golden/golden.mbt` | 算术真值端 | ✅ | ✅ | — | 51 |
| `golden_business/golden_business.mbt` | 业务真值端 | ✅ | ✅ | — | 90 |
| `moon2dart.mbt` | 库入口（管线 + Options） | ❌ | ❌ | official parser: unsupported try/catch | 1 |
| `ast/ast.mbt` | AST 定义（struct/enum/derive） | ❌ | ❌ | official parser: unsupported extend declaration | 1 |
| `parser/parser.mbt` | 手写 parser（大文件） | ❌ | ❌ | official parser: unsupported record literal | 1 |
| `cmd/main/main.mbt` | CLI（async/match/方法） | ❌ | ❌ | official parser: unsupported return expression | 1 |
| `typesys/mapping.mbt` | 类型映射（大量 match） | ❌ | ❌ | official parser: unsupported extend declaration | 1 |

**汇总**：官方直连 **4/9**（44%）；兼容模式 **4/9**（44%）。

## 口径说明 | Scope

- **官方直连**衡量"官方 parser + 适配层"的技术债剩余面；拒绝项是子集外语法/节点，属于显式 fail-closed；
- **兼容模式**衡量当前可用范围：官方 parser 优先，仅在语法层失败时回退旧 parser（不改变语义策略）；
- 业务函数（Array/while/push/相等）与算术 fixture 在官方直连下均应被接受；核心实现文件暴露下一阶段要补的语法面（match 深嵌套、复杂泛型、异步/方法链等）。

## 复现 | Reproduce

```bash
node scripts/acceptance_report.mjs
node scripts/acceptance_report.mjs   # 官方直连列由 --official-only 触发
```