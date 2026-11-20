// 安全边界材料 — 未注解算术（推断失败），用于 fail-closed 验证。
// Safety-boundary fixture: unannotated arithmetic (inference failure) for fail-closed verification.

fn f() -> Int { g() + h() }