# moon2dart 项目驳回回应 | Response to Review Feedback

> **收件人**：组委会评审组 | **To**: Competition Review Committee
> **主题**：moon2dart 驳回回应 — v0.11.0 运行时语义保持体系（32 位溢出 / 适用约束 / 双端实证） | **Subject**: Response to Rejection — v0.11.0 Runtime Semantic Preservation
> **日期**：2026-11-18 | **Date**: 2026-11-18

---

尊敬的组委会老师：

感谢对 moon2dart 项目的严格审阅。驳回理由指出的核心问题——**"类型往返恢复支撑零语义损失"不成立、运行语义未说明、32 位整数溢出即可使转换前后结果不同、分级未建立可靠复用边界**——完全成立。类型往返确实只证明**结构**可还原，不证明**运算行为**一致。我们在 v0.11.0 中按驳回要求的三个方向完成整改，逐条回应如下：

---

## 一、语义保留方法 | Semantic Preservation（回应"未说明完全等价构造的运行语义如何保持"）

### 1.1 承认问题：MoonBit `Int` 是 32 位回绕，Dart `int` 是 64 位

`2147483647 + 1` 在 MoonBit 得 `-2147483648`（wasm i32 回绕），在 Dart 得 `2147483648`。仅做 `Int → int` 类型映射，运算结果必然不同。原 L1 定级"零语义损失"是错误的，已修正。

### 1.2 解决方案：类型 × 运算双层建模 + 回绕模拟层（v0.11.0 已实现）

**运算层**——mini 类型推断器（变量环境 + 全局函数签名表，typesys/infer.mbt）在发射期判定算术操作数类型；**Wrapping 模式（默认）**为 Int 算术生成回绕模拟层（按需生成，仅含程序实际用到的运算）：

```dart
int mb32Add(int a, int b) => (a + b).toSigned(32); // 加/减/乘：回绕
int mb32Div(int a, int b) => (a == -2147483648 && b == -1 || b == 0)
    ? (throw StateError('integer overflow trap'))   // INT_MIN/-1 与除零：trap 模拟
    : ((a ~/ b).toSigned(32));                      // 除法：截断向零
int mb32Rem(int a, int b) => b == 0
    ? (throw StateError('division by zero trap'))
    : a.remainder(b).toSigned(32);                  // 余数：符号跟被除数
```

三个此前静默丢失/错误的语义点已修正：
1. **溢出回绕**：`+ - *` 经 `.toSigned(32)` 还原 wasm i32 语义
2. **整数除法**：原发射 `/` 是 Dart 浮点除法（`7/2 = 2.5`，类型与语义双重错误），修正为 `~/`
3. **取余语义**：MoonBit `%` 是截断余数（`-7 % 2 = -1`），Dart `%` 是欧几里得余数（`-7 % 2 = 1`）——发射 `.remainder()` 而非 `%`

**INT_MIN/-1 与除零**按 wasm i32.div_s 规范是 **trap**（实测 MoonBit native 端为硬件异常终止 0xC0000095）——mb32Div/mb32Rem 显式抛异常模拟，两端行为**类别**一致（异常终止），不伪造数值。

### 1.3 双模式：语义忠实与地道 Dart 的显式取舍

| 模式 | 行为 | 适用 |
|------|------|------|
| `--semantics wrapping`（默认） | Int 算术经 mb32* 模拟层，两端结果一致 | 复用逻辑正确性优先 |
| `--semantics fast` | 裸发地道 Dart，Int 自动降级 **L2** 并插入 `[L2-SEMANTICS]` 诊断注释 | 性能优先，接受 64 位语义 |

---

## 二、受限转换的适用约束 | Constraints（回应"分级未能建立可靠的复用边界"）

分级表已修正（修正点加粗）：

| 等级 | 含义 | 数量 | 代表构造 | 边界条件 |
|------|------|:----:|---------|---------|
| **L1 运行时验证等价** | 类型映射 + 运算模拟层 | 18 | **Int→int(32位回绕模拟层)**, Bool, String, Double, Array, Map, Set, 单层Option, enum, struct, trait, fn, async fn, 泛型, 闭包, Result, 嵌套Option辅助类, Tuple | golden 双端 14/14 实测 |
| L2 结构等价 | 结构可还原，操作有差异 | 2 | Char→int(rune), **Int64→int** | Int64 限 **Dart VM**（编译到 web 时 int 退化为 JS number，值域 2^53） |
| L3 受限等价 | 约束下等价，需用户配合 | **4** | UInt→int, **UInt64→int（原漏判 L1，已修正）**, Float→double, Char运算 | 无符号丢失 / 精度提升 / 码点表示 |
| L4 不等价 | 语义丢失 | 5 | FFI, Channel, Spawn, extern "C", wasm intrinsics | `--strict` raise TypeError 拒绝 |

**推断边界（明确声明）**：类型推断失败的场景（无类型上下文的算术、跨函数未知返回值、闭包体内部）**保守裸发**（fast 语义），不做伪装的语义保证——依赖用户在函数签名上提供类型注解（MoonBit 常规写法）。

**修复的既有解析缺口**：parser 此前不识别 `Int64`/`UInt`/`UInt64`/`Float` 类型注解（fallback 到 MCustom，发射出无效 Dart 类型 `Int64`）、不支持 Double 字面量与负数字面量、不支持多语句块——均已修复并补测试。

---

## 三、同一输入的两端结果 | Same-Input Dual-Runtime Results（回应"用同一输入给出两端结果"）

同一份 MoonBit 源码（`scripts/golden_fixture/fixture.mbt`），**两端各自实际执行**：MoonBit 端 `moon run golden --target native` 原生求值；Dart 端经 moon2dart（wrapping 模式）转换后由 **Dart SDK 3.12.2 实跑**。逐行对比 **14/14 一致**：

| # | 输入表达式 | 说明 | MoonBit 输出 | Dart 输出 | 一致 |
|---|-----------|------|-------------|-----------|:----:|
| 1 | `wrap_add(2147483647, 1)` | **组委会反例：溢出回绕** | `-2147483648` | `-2147483648` | ✅ |
| 2 | `wrap_add(-2147483647, -1)` | 下界回绕 | `-2147483648` | `-2147483648` | ✅ |
| 3 | `wrap_sub(-2147483647, 2)` | 回绕到上界 | `2147483647` | `2147483647` | ✅ |
| 4 | `wrap_mul(65536, 65536)` | 2^32 回绕 | `0` | `0` | ✅ |
| 5 | `wrap_mul(100000, 100000)` | 10^10 回绕 | `1410065408` | `1410065408` | ✅ |
| 6-8 | `trunc_div(7,2) / (-7,2) / (7,-2)` | 截断除法（向零） | `3 / -3 / -3` | `3 / -3 / -3` | ✅ |
| 9-10 | `trunc_rem(-7,2) / (7,-2)` | 截断余数（Dart 裸 `%` 会得 `1`） | `-1 / 1` | `-1 / 1` | ✅ |
| 11 | `add64(1073741824, 1073741824)` | Int64 64 位（限 VM） | `2147483648` | `2147483648` | ✅ |
| 12 | `ratio(7.0, 2.0)` | IEEE 754 | `3.5` | `3.5` | ✅ |
| 13-14 | `lt(...)` / `join_str(...)` | 比较 / 字符串 | `false / moonbit` | `false / moonbit` | ✅ |

**拒绝或人工处理边界**：

| 输入/构造 | MoonBit 行为 | Dart（wrapping）行为 | 类别 |
|-----------|-------------|---------------------|------|
| `INT_MIN / -1` | **trap**（native 硬件异常 0xC0000095；wasm 规范 trap） | mb32Div 抛 StateError（实测 TRAP） | 两端一致：异常终止 |
| `x / 0`、`x % 0` | **trap**（wasm i32.div_s/rem_s） | 抛 StateError（实测 TRAP） | 两端一致：异常终止 |
| UInt/UInt64/Float/Char | 值域有损 | `[L3-CONSTRAINED]` 注释标注 | 人工处理 |
| FFI/Channel/Spawn/wasm intrinsics | 无 Dart 对应 | `--strict` 拒绝；默认 `[L4-INEQUIVALENT]` 注释 | 拒绝 / 人工处理 |
| Int64 算术 | 64 位回绕 | 一致，**限 Dart VM**；web 目标降级 L2 | 适用约束 |

复现命令：`node scripts/golden_check.mjs`（完整报告自动生成于 `docs/golden_results.md`）。

---

## 四、验证数据 | Verification Data

| 指标 | 结果 |
|------|------|
| 测试总数 | **541**（native 全绿，四后端 check 零警告） |
| golden 双端对比 | **14/14 一致**（含溢出回绕 / 截断除法 / 截断余数 / trap 边界） |
| L1 往返恢复率 / L4 strict 拒绝率 | 100% / 100% |
| 变异测试 | 3 组全通过（注入→变红→撤回→变绿） |
| 新增专项测试 | 类型推断 / shim 生成 / 双模式 / golden 真值断言（+41） |
| 语义分级修正 | Int wrapping=L1/fast=L2；UInt64 漏判修复为 L3；Int64 注明 VM 约束 |

申报书已同步更新（三大关切回应重写），仓库：https://github.com/walkzzz/moon2dart

## 五、仓库与持续集成状态 | Repository & CI Status

| 仓库 | 地址 | 状态 |
|------|------|------|
| GitHub 主仓 | https://github.com/walkzzz/moon2dart | HEAD = v0.11.0 整改提交；CI 九步全绿（deny-warn 全目标 / 四后端测试 / fmt gate / mbti 契约校验 / coverage） |
| GitCode 镜像 | https://gitcode.com/LOOYIABC/moon2dart | 与 GitHub 主仓 HEAD 一致（跟随同步） |
| mooncakes | `walkzzz/moon2dart` | 旧功能线 0.8.0 已发布；语义保持线 0.1.1 = 功能 v0.11.0，随本轮重提发布 |

本回应的所有实证均可复现：

```bash
git clone https://github.com/walkzzz/moon2dart && cd moon2dart
moon check --target all --deny-warn   # 四目标零警告
moon test                              # 541 测试全绿
node scripts/golden_check.mjs          # golden 双端 14/14（需 Dart SDK）
node scripts/check_docs.mjs            # 材料数字自检 4/4
```

如有进一步问题，我们随时补充说明。感谢组委会的审阅与指导！

此致
敬礼

**蒋本雄（walkzzz）**
📞 13689047817
✉️ 745244185@qq.com
