# 安全转换边界与人工介入 | Safety Boundary & Human Intervention

> v0.12.0 · 2026-11-20 · 直接回应第二轮初审："推断失败时的处理也未建立可靠的安全边界"
> 交叉参考：[array_semantics.md](array_semantics.md)、[review_anticipation.md](review_anticipation.md)

## 1. 原则：fail-closed（失败即拒绝，不静默降级）

旧版（v0.11.0）在类型推断失败时"保守裸发（fast 语义）"——转换继续、产物看似可用，
但算术回绕/比较语义不再受保证，且没有报告。这是不可审计的安全边界。

v0.12.0 起默认 **Error 策略**：

- 任何"算术操作数类型不可推断"都**拒绝生成**，退出码非零，报错含 `UNRESOLVED (fail-closed)`；
- 未知语法（`for`、位运算、复合赋值、切片等）由解析器直接报错，**不跳过、不近似**；
- 只有显式选择 `--on-unresolved warn` 或 `fast` 才允许继续，且必须留下可审计记录。

## 2. 三档策略 | Policies

| 策略 | CLI | 行为 | 用途 |
| --- | --- | --- | --- |
| `Error`（默认） | `--on-unresolved error` | 拒绝生成 + 非零退出 + 首条诊断详情 | CI / 生产复用 |
| `Warn` | `--on-unresolved warn` | 继续生成，代码头部插入 `// [L2-UNRESOLVED] ...`，写 JSON/MD 报告 | 迁移过渡、人工复核 |
| `Fast` | `--on-unresolved fast` | 保留旧版裸发，仅在报告中记录 | 实验，不进入 CI |

配套：`--semantics wrapping|fast` 控制整数/集合语义模拟；`--report <path>` 输出
`<path>.json`（机读）与 `<path>.md`（人读）。

## 3. 什么算"推断失败" | Unresolved Cases

| 场景 | 示例 | 旧行为 | 新行为（默认） |
| --- | --- | --- | --- |
| 无声明函数参与算术 | `g() + h()` | 裸发 `g() + h()` | 拒绝 |
| 仅一侧未知 | `g() + 1` | 裸发（伪装成功） | 拒绝（要求签名） |
| 无注解局部变量 | `let acc = f()` 后 `acc + 1` | 裸发 | 拒绝 |
| lambda 未注解参数 | `fn(x) { x + 1 }` | 裸发 | 拒绝（参数补类型即可） |
| 空数组无类型注解 | `let a = []` 后 `a[0] + 1` | 裸发 | 拒绝（写 `let a : Array[Int] = []`） |
| 索引来源类型未知 | `xs[i] + 1`，`xs` 无签名 | 裸发 | 拒绝 |
| 未支持语法 | `for` / `+=` / `x << 1` | 解析错误（部分） | 解析错误（统一 fail-closed） |

**豁免**：函数参数/返回值、`let` 显式注解、字面量与已绑定局部变量均可推断，
不会误报（测试 `typesys/safety_boundary_wbtest.mbt` 覆盖）。

## 4. 报告格式 | Auditable Report

`--report golden_out/safety` 生成：

```json
{
  "policy": "warn",
  "ok": true,
  "unresolved": [
    { "code": "UNRESOLVED_ARITH", "site": "f",
      "detail": "operator +: operand type not inferable (add a type annotation ...)" }
  ],
  "degraded": []
}
```

- `code`：`UNRESOLVED_ARITH` / `L3_TYPE` / `L4_TYPE`（扩展位：`DROPPED_FFI`）
- `site`：函数名或 `Type::method`
- 报告本身参与门禁：`scripts/safety_gate.mjs` 断言 JSON 可解析、unresolved 计数与代码标注一致。

Markdown 报告示例（自动生成）：`golden_out/safety.md`，含 policy、通过状态、逐条表格。

## 5. 人工介入清单 | Mandatory Human Review

以下情况转换成功也**不得**视为自动等价，必须人工审阅：

1. `--on-unresolved warn/fast` 下存在任何 `UNRESOLVED`；
2. L3 构造：`UInt` / `UInt64` / `Float` / `Char`（值域/表示有损）；
3. L4 构造：FFI / Channel / Spawn / wasm intrinsics；
4. 集合相等依赖：Fast 模式下的 `==` / `!=`；元素为函数/闭包/自定义对象；
5. `Set` / `Map` 迭代顺序参与业务语义；
6. Web 目标下的 `Int` / `Int64`（53 位值域）；
7. 未支持操作被拒绝后手工改写（切片、`sort`、`for-in`、位运算）；
8. 跨包/跨项目类型无法从签名确认。

## 6. 与传统生态的对应 | Ecosystem Mapping

| 生态实践 | 对应机制 |
| --- | --- |
| TypeScript `strict` / `noImplicitAny`（推断失败即编译错误） | `Error` 默认策略 |
| Babel 不支持语法直接 `SyntaxError`（不静默） | 解析器 fail-closed |
| c2rust 用 `unsafe` 显式标注边界 | L3/L4 诊断注释 + 人工清单 |
| Scala.js/Kotlin-js 移植运行时库处理集合/整数 | `mb32*` + `mbEquals` shim |
| Closure Compiler 把类型错误升级为 error | CI 安全门禁（`safety_gate.mjs`） |

## 7. 证据 | Evidence

`node scripts/safety_gate.mjs`（8/8 PASS）：

1. 未注解算术 → 非零退出 + `UNRESOLVED`
2. warn → 成功 + `[L2-UNRESOLVED]` 标注
3. 报告 JSON 可机读且 unresolved=1
4. 报告 Markdown 可审计
5. 未支持语法 → 非零退出
6. 同一输入两次转换 byte-identical
7. `mbEquals` 生成并被调用
8. `mb32Add` / `mb32Mul` 在数组业务函数中保留

CI：`.github/workflows/ci.yml` 的 `golden-dual-runtime` job 执行上述门禁并上传报告工件。