# moon2dart 项目关切问题回复 | Response to Committee Concerns

> **收件人**：组委会评审组 | **To**: Competition Review Committee
> **主题**：moon2dart 项目关切问题回复 — v0.10.0 语义等价验证体系 | **Subject**: Response to Concerns — v0.10.0 Semantic Equivalence Verification
> **日期**：2026-11-16 | **Date**: 2026-11-16

---

尊敬的组委会老师：

感谢对 moon2dart 项目的审阅与反馈。针对贵方提出的三个关切问题，我们在 v0.10.0 版本中完成了系统性回应，现将核心结论汇报如下：

---

## 一、可转换范围 | Convertible Scope

我们建立了 **L1-L4 四级语义等价分类**，对 28 个类型映射条目逐一定级，每条均有可执行断言验证：

| 等级 | 含义 | 数量 | 代表构造 | 往返可恢复 |
|------|------|:----:|---------|:---------:|
| **L1 完全等价** | 往返后语义完全一致 | 18 | Int→int, Bool→bool, String→String, Array→List, 单层Option[T]→T?, enum→sealed class, struct→class, trait→abstract class, fn→function, async fn→Future, 泛型→泛型, 闭包→箭头函数, Result[T,E]→sealed class, 嵌套Option→辅助类, Tuple→Record | ✅ |
| **L2 结构等价** | 结构可还原，操作有差异 | 2 | Char→int(rune), Int64→int | ⚠️ |
| **L3 受限等价** | 约束下等价，需用户配合 | 3 | UInt→int(丢unsigned), Float→double(精度提升) | 🔶 |
| **L4 不等价** | 语义丢失，不可往返 | 5 | FFI/Channel/Spawn/wasm intrinsics | ❌ |

**边界机制**：`--strict` CLI 选项拒绝所有 L4 映射（raise TypeError），只放行 L1-L3，确保用户明确知晓哪些构造不可安全转换。5 个 strict 拒绝测试全绿→拒绝率 **100%**。

**L1/L2 分界**：值域是否完全对应（Char 在 Dart 无独立类型，操作语义漂移）；
**L3/L4 分界**：约束下能否等价（UInt 加运行时检查可部分等价，Channel 无 Dart 对应物）。

---

## 二、语义保留方法 | Semantic Preservation

三级差异化策略 + 两重防线：

### 策略层 | Strategy Layer

- **L1 同构映射**：直接映射，零语义损失（18 项双向往返完全恢复）
- **L2/L3 辅助结构**：嵌套 Option→辅助类（三分态保留）；Result→DResult 结构化节点（ok/err 类型保留）；UInt/Float→正常映射 + `// [L3-CONSTRAINED]` 诊断注释
- **L4 拒绝/标注**：`--strict` 模式 raise TypeError 拒绝生成；默认模式生成代码 + `// [L4-INEQUIVALENT]` 诊断注释

### 防线一——编译期自动检查 | Defense Line 1: Compile-time Checks

4 个检查点自动串联：

1. `is_nested_option()` — 检测嵌套 Option，自动切换辅助类映射
2. `DResult(ok, err)` — 结构化节点替代 DCustom 字符串退化
3. `semantic_level()` — 每种 MoonType 自动获 L1-L4 标签
4. `emit_semantic_diagnostic()` — L3/L4 自动插入诊断注释

### 防线二——变异测试 | Defense Line 2: Mutation Testing

对每个防线注入已知缺陷，验证断言能检出：

| 变异操作 | 注入缺陷 | 检出结果 |
|---------|---------|---------|
| 嵌套 Option 塌缩 | 临时将辅助类改为 `T?` | round-trip 变红（Some(None)≠None 不可区分）→ 撤回变绿 ✅ |
| Result 结构退化 | 临时将 DResult 改回 DCustom | round-trip 变红（ok/err 类型结构丢失）→ 撤回变绿 ✅ |
| UInt 诊断缺失 | 临时移除 L3 标注 | strict 变红（L4 拒绝范围错误）→ 撤回变绿 ✅ |

**结论**：语义保留不是"理论上支持"——每个保留方法有可执行断言，每个防线有变异测试证明检错能力。

---

## 三、嵌套可选值 | Nested Option

`Option[Option[T]]` 是 transpiler 领域经典难题：Dart 的 `T??` 自动塌缩为 `T?`，`Some(None)` 与 `None` 不可区分。

### 问题本质 | The Problem

| MoonBit 值 | 语义 | Dart `int?` | 可区分 |
|-----------|------|------------|:------:|
| `Some(Some(42))` | 有值（内层有值） | `42` | ✅ |
| `Some(None)` | 有值（内层空） | `null` | ❌ 与 None 合并 |
| `None` | 空 | `null` | ❌ 与 Some(None) 合并 |

### 解决方案 | Solution

辅助 Option 包装类——检测到嵌套时自动生成：

```dart
class Option<T> {
  final T? _value; final bool _isSome;
  Option._internal(this._value, this._isSome);
  factory Option.some(T v) => Option._internal(v, true);
  factory Option.none() => Option._internal(null, false);
  bool get isSome => _isSome; bool get isNone => !_isSome;
}
```

### 三分态往返闭环 | Three-state Round-trip

| MoonBit 正向 | Dart 中间态 | MoonBit 反向恢复 | 等价 |
|-------------|-----------|---------------|:----:|
| `None` | `Option.none()` | `None` | ✅ |
| `Some(None)` | `Option.some(null)` | `Some(None)` | ✅ |
| `Some(Some(42))` | `Option.some(42)` | `Some(Some(42))` | ✅ |

### 设计权衡 | Design Trade-offs

- **单层 Option 保持 `T?`**（零开销）— 95%+ 用例是单层，辅助类会破坏地道 Dart 风格
- **仅嵌套场景生成辅助类**— `needs_option_class(decls)` 自动检测，无嵌套不生成
- **更深层自动递归**— `Option[Option[Option[T]]]` → `Option<Option<T?>?>`

8 个嵌套 Option 专项测试全绿。

---

## 验证数据 | Verification Data

| 指标 | 结果 |
|------|------|
| 测试总数 | **500**（native）/ 464（wasm+js+wasm-gc） |
| L1 往返恢复率 | **100%** |
| L4 strict 拒绝率 | **100%** |
| 变异测试 | 3 组全通过（注入缺陷→变红→撤回→变绿） |
| 工程门禁 | `moon check --target all --deny-warn` 零警告 |
| Sprint 迭代 | 55+ 轮（v0.1.0→v0.10.0，10 版本全交付） |

---

更新后的申报书已推送至 GitHub：https://github.com/walkzzz/moon2dart

如有进一步问题，我们随时补充说明。感谢组委会的审阅与指导！

此致
敬礼

**蒋本雄（walkzzz）**
📞 13689047817
✉️ 745244185@qq.com
