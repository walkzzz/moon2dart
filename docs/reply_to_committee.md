# moon2dart 第二轮初审驳回回应 | Response to Second Review

> **收件人**：组委会评审组 | **To**: Competition Review Committee
> **主题**：moon2dart 整改回应 — Array→List 集合语义（L2-C + mbEquals）、推断失败 fail-closed 安全边界、业务函数双端等价证据
> **日期**：2026-11-20 | **Date**: 2026-11-20
> **版本**：功能 v0.12.0（mooncakes 包 0.1.2）

---

尊敬的组委会老师：

感谢第二轮审阅。两条驳回理由都成立，且是上一版整改没有覆盖到的真实缺口：

1. **Array→List 的 L1 定级没有解释集合相等语义**——我们把"类型可映射"误当成了"语义等价"；
2. **推断失败时没有可靠安全边界**——上一版"保守裸发（fast 语义）"等于静默降级，产物看似可用但语义不再受保证。

本轮按"可验证的等价"重做这两块，并补齐了业务函数级的双端证据。以下逐条说明，所有数字均可在本地一条命令复现。

---

## 一、Array→List：从 L1 降为 L2-C，并修复相等语义

### 1.1 承认定级错误

我们实测了相等语义：

```moonbit
// MoonBit
let a : Array[Int] = [1, 2]
let b : Array[Int] = [1, 2]
println(a == b)   // true —— 逐元素比较
```

```dart
// Dart 原生
final a = [1, 2];
final b = [1, 2];
print(a == b);    // false —— 引用（identity）比较
```

因此**只做 `Array[T] → List<T>` 类型映射不可能等价**。原 L1 定级已撤回：

| 项 | 上一版 | 本版 |
| --- | --- | --- |
| Array→List | L1 完全等价 | **L2-C 条件等价** |
| 相等语义 | 未说明 | `mbEquals` 还原逐元素（Wrapping）；Fast 裸发并标注 |
| 越界 | 未说明 | 类别一致（trap / RangeError），类型/消息不同 → L2 |
| 证据 | 仅类型映射断言 | 业务函数双端实跑 **13/13** |

### 1.2 修复方式

Wrapping 模式对推断为集合的 `==` / `!=` 发射结构相等 helper：

```dart
bool mbEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) { /* 长度 + 逐元素递归 */ }
  if (a is Map && b is Map)   { /* 键集合 + 值递归 */ }
  if (a is Set && b is Set)   { /* 双向包含（递归） */ }
  return a == b;
}
```

生成代码示例（业务函数 `same`）：

```moonbit
fn same(xs : Array[Int], ys : Array[Int]) -> Bool { xs == ys }
```

```dart
bool same(List<int> xs, List<int> ys) {
  return mbEquals(xs, ys);
}
```

### 1.3 明确安全转换范围与人工介入条件

操作矩阵（详见 `docs/array_semantics.md`）：

| 操作 | 生成 | 等级 | 约束 |
| --- | --- | --- | --- |
| `length()` / 字面量 / `push` / `append` | `.length` / `[...]` / `.add` / `.addAll` | L1-C | 子集内 |
| 索引读 / `get` / `pop` | `xs[i]` / 越界检查三元 / `isEmpty ? null : removeLast()` | L2 | 不依赖异常类型/消息 |
| `==` / `!=` | `mbEquals` / `!mbEquals` | L1-C（Wrapping）/ L2（Fast） | 必须 Wrapping |
| 切片 / `for-in` / `sort` | **拒绝**（解析器报错） | 子集外 | 待实现 |
| 别名共享 | 引用共享一致 | L1 | 无并发 |

**必须人工介入**：Fast 模式的集合相等、依赖 Set/Map 迭代顺序、元素为函数/闭包/自定义对象、
跨函数签名无法确认、并发共享可变数组。

---

## 二、推断失败：fail-closed（默认拒绝），不再静默裸发

### 2.1 边界定义

- 默认 **`--on-unresolved error`**：任何"算术操作数类型不可推断"即**拒绝生成**，退出码非零，
  报错含 `UNRESOLVED (fail-closed)`；
- `--on-unresolved warn`：继续生成，代码头插入 `// [L2-UNRESOLVED] ...`，并写出 JSON/MD 报告；
- `--on-unresolved fast`：保留旧行为，仅供实验，不进入 CI；
- 未支持语法（`for`、位运算、复合赋值、切片等）由解析器**直接报错**，不跳过、不近似。

### 2.2 可审计报告

`--report <path>` 生成 `<path>.json`（机读）与 `<path>.md`（人读）：

```json
{
  "policy": "warn",
  "ok": true,
  "unresolved": [
    { "code": "UNRESOLVED_ARITH", "site": "f",
      "detail": "operator +: operand type not inferable (add a type annotation or avoid untyped arithmetic)" }
  ],
  "degraded": []
}
```

CI 门禁直接断言报告：JSON 可解析、`unresolved` 计数与代码标注一致、失败退出码非零。

### 2.3 人工介入条件（摘要）

`Warn/Fast` 下存在未解析项、L3（UInt/UInt64/Float/Char）、L4（FFI/Channel/Spawn）、
Fast 集合相等、Set/Map 顺序依赖、Web 目标 53 位、未支持操作被拒绝后手工改写——
均不得视为自动等价（完整清单见 `docs/safety_boundary.md` §5）。

---

## 三、业务函数：输入 → 转换产物 → 两端结果

同一份 MoonBit 源码（`scripts/golden_fixture/business.mbt`），
MoonBit 端 `moon run golden_business --target native` 原生求值；
Dart 端经 moon2dart（wrapping + fail-closed）转换后由 **Dart SDK 3.12.2 实跑**。逐行对比 **13/13 一致**：

| # | 输入 | MoonBit | Dart | 一致 |
| --- | --- | --- | --- | --- |
| 1 | `sum([])` | `0` | `0` | ✅ |
| 2 | `sum([1,2,3,4])` | `10` | `10` | ✅ |
| 3 | `sum([2147483647,1])` | `-2147483648` | `-2147483648` | ✅ |
| 4 | `count_positive([-2,0,5,7])` | `2` | `2` | ✅ |
| 5 | `max_or([3,9,2],-1)` | `9` | `9` | ✅ |
| 6 | `max_or([],-1)` | `-1` | `-1` | ✅ |
| 7 | `build_squares(4).length()` | `4` | `4` | ✅ |
| 8 | `build_squares(4)[3]` | `9` | `9` | ✅ |
| 9 | `first_or([42,7],-1)` | `42` | `42` | ✅ |
| 10 | `first_or([],-1)` | `-1` | `-1` | ✅ |
| 11 | `same([1,2],[1,2])` | `true` | `true` | ✅（`mbEquals`） |
| 12 | `same([1,2],[2,1])` | `false` | `false` | ✅ |
| 13 | `same([],[])` | `true` | `true` | ✅ |

转换产物（节选，`golden_out/business.dart`）：

```dart
int sum(List<int> xs) {
  var i = 0;
  var acc = 0;
  while (i < xs.length) {
    acc = mb32Add(acc, xs[i]);
    i = mb32Add(i, 1);
  }
  return acc;
}

bool same(List<int> xs, List<int> ys) {
  return mbEquals(xs, ys);
}
```

算术组 14/14 保持（溢出回绕、截断除法/余数、trap 边界）。合计 **27/27 行一致**。
报告：[`docs/golden_results.md`](../docs/golden_results.md) 与
[`docs/golden_results_business.md`](../docs/golden_results_business.md)。

---

## 四、生态做法对照（为什么这样改）

主流转换器不承诺"全语言自动等价"，而是：

| 生态 | 关键做法 | 本项目对应 |
| --- | --- | --- |
| TypeScript `strict` / `noImplicitAny` | 推断失败 = 编译错误 | `Error` 默认策略 |
| Babel | 不支持语法直接 `SyntaxError`，不静默 | 解析器 fail-closed |
| Scala.js / Kotlin/JS | 移植集合/整数语义（`Long` 包装、32 位 Int） | `mb32*` 回绕 + `mbEquals` 相等 |
| GopherJS / Emscripten | 运行时 shim / libc 移植 | 按需 shim，不整体移植 |
| c2rust | `unsafe` 显式标注 + 人工审阅 | L3/L4 诊断 + 人工介入清单 |
| Closure Compiler | 类型错误可升级为 error | CI 安全门禁把诊断升级为硬失败 |
| Haxe | 多目标 + 明确语义差异文档 | 禁止目标条件编译，改用 shim + 分级 |
| dart2js | web 上 `int` 53 位明确文档 | `Int64` 限 Dart VM，web 降级 L2 |

结论：本项目的整改方向（划子集、补 shim、fail-closed、留报告、差分实证）与成熟生态一致，
不再依赖"类型可映射即等价"的推断。详见 `docs/ecosystem_practices.md`。

**MoonBit 生态内的同类库对照**（本轮新增学习）：

| 同类库 | 做法 | 对本项目的采用 |
| --- | --- | --- |
| `mizchi/mbt_rs`（MoonBit↔Rust） | 明确"不追求完美转换"、WARNING 人工修复、`--report` 真实项目转化率 96-100%、行为等价 159+161、roundtrip 测试 | 采用"真实语料接受率"（`acceptance_report.md`）与 roundtrip 断言；保持 fail-closed 更严格的拒绝策略 |
| `mizchi/ts`（TS↔MoonBit） | parity / rule-equivalence / mangle-fuzzing / corpus / docs 分层 | 采用随机化属性测试（6 类）与"规则-证据"文档化 |
| `bobzhang/typify` | 生成 upstream-identical token 流、Rust 子包分层 | 采用"映射层信息完备"原则（属性测试发现并修复 `Int64` 往返丢失） |
| `moonbitlang/parser` | 官方 parser + 幂等格式化 | 列为 0.13.0 技术债：自研 parser 迁移/双 parser 一致性评估 |
| `moonbitlang/quickcheck` | 随机输入 + shrink + 修饰器 | 采用固定种子属性测试（零新依赖实现） |

---

## 五、主动补充：我们预判还可能被追问的点

不回避尚未完成的部分（完整清单见 `docs/review_anticipation.md`）：

- **位运算 / 复合赋值 / 一元负变量 / 切片 / `for-in` / `sort`**：尚未实现语义模拟，
  解析器**直接拒绝**（fail-closed），不静默近似；0.13.0 计划补 shim 或专用诊断码。
- **数值格式化**：`println(1.0)`、`NaN`、`Infinity`、`-0.0` 的两端格式尚未纳入 golden，
  存在格式差异风险；已列为 0.13.0 必补项。
- **字符串/Unicode**：`String→String` 仍定 L1，但代理对/码点差异未做专项差分（待补）。
- **样本规模**：当前 27 行是"业务函数级"证据上限，尚不足以代表整个语言；
  下一步做差分随机测试与真实项目 corpus 接受/拒绝率。
- **fixture 单源**：MoonBit 真值端与转换端仍为两份手写文件（`Int` vs `Int32`），
  计划由生成器从同一 `.mbt` 派生，消除 drift。
- **反向转换**：Dart→MoonBit 明确为 best-effort，不参与 L1-L4 定级。

---

## 六、验证数据（本轮实测）

| 指标 | 结果 |
| --- | --- |
| 单元测试 | **579/579**（native）；wasm / wasm-gc / js 各 529/529 |
| 四目标检查 | `moon check --target all --deny-warn` 零警告 |
| 双端 golden | **27/27**（算术 14 + 业务函数 13） |
| 安全边界门禁 | **8/8 PASS**（fail-closed / 报告 / 幂等 / `mbEquals` / 回绕） |
| Dart 静态分析 | `dart analyze golden_out --fatal-infos`：**No issues found** |
| 幂等 | 同一输入两次转换 byte-identical |
| 报告 | `golden_out/safety.json` / `.md`（CI 上传工件） |
| **真实语料接受率** | **4/9 = 44%**（fail-closed 子集覆盖；业务与算术 fixture 全接受，核心实现文件按子集外语法明确拒绝并给原因，见 `docs/acceptance_report.md`） |
| **生成物格式** | `dart format --output=none` 可解析；`dart analyze` 0 issues |

复现：

```bash
git clone https://github.com/walkzzz/moon2dart && cd moon2dart
moon update
moon check --target all --deny-warn
moon test --target native                 # 579/579
node scripts/golden_check.mjs             # 27/27（需 Dart SDK 3.x）
node scripts/safety_gate.mjs              # 8/8
node scripts/acceptance_report.mjs        # 真实语料接受率
dart analyze golden_out --fatal-infos     # 0 issues
```

---

## 七、仓库与材料

| 项 | 地址/位置 |
| --- | --- |
| GitHub 主仓 | https://github.com/walkzzz/moon2dart |
| GitCode 镜像 | https://gitcode.com/LOOYIABC/moon2dart |
| 集合语义规范 | `docs/array_semantics.md` |
| 安全边界规范 | `docs/safety_boundary.md` |
| 生态做法对照 | `docs/ecosystem_practices.md` |
| 评审预判清单 | `docs/review_anticipation.md` |
| 业务函数双端报告 | `docs/golden_results_business.md` |
| 申报书 | `hackathon2026_moon2dart_proposal.md`（已同步本轮口径） |

我们已按 2026-11-30 前的重新审核窗口准备材料。若仍需补充（例如扩大 corpus、
数值格式化差分、位运算实现），请告知优先项，我们按优先级继续。

再次感谢审阅与具体、可执行的驳回意见——它们直接推动了本次语义定级与安全边界的重做。

此致
敬礼

**蒋本雄（walkzzz）**
📞 13689047817
✉️ 745244185@qq.com