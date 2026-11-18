int mb32Div(int a, int b) => (a == -2147483648 && b == -1 || b == 0) ? (throw StateError('mb32Div: integer overflow trap (INT_MIN/-1 or div by zero), mirrors MoonBit wasm i32.div_s')) : ((a ~/ b).toSigned(32));
int mb32Rem(int a, int b) => b == 0 ? (throw StateError('mb32Rem: division by zero trap, mirrors MoonBit wasm i32.rem_s')) : a.remainder(b).toSigned(32);
void main() {
  try {
    mb32Div(-2147483648, -1);
    print('NO-TRAP');
  } catch (e) {
    print('TRAP');
  }
  try {
    mb32Rem(7, 0);
    print('NO-TRAP');
  } catch (e) {
    print('TRAP');
  }
}
