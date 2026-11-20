// 业务函数 golden 素材（v0.12.0）— 覆盖 Array→List、索引、while、push、32 位回绕与边界。
// Business-function golden fixture: Array→List, indexing, while, push, 32-bit wrapping and boundaries.
// 注：本文件位于 scripts/ 下，不属于任何 moon 包，不会被 MoonBit 编译。

fn sum(xs : Array[Int]) -> Int {
  let mut i = 0
  let mut acc = 0
  while i < xs.length() {
    acc = acc + xs[i]
    i = i + 1
  }
  acc
}

fn count_positive(xs : Array[Int]) -> Int {
  let mut i = 0
  let mut n = 0
  while i < xs.length() {
    n = n + (if xs[i] > 0 { 1 } else { 0 })
    i = i + 1
  }
  n
}

fn max_or(xs : Array[Int], d : Int) -> Int {
  if xs.length() == 0 {
    d
  } else {
    let mut i = 1
    let mut best = xs[0]
    while i < xs.length() {
      best = if xs[i] > best { xs[i] } else { best }
      i = i + 1
    }
    best
  }
}

fn build_squares(n : Int) -> Array[Int] {
  let mut i = 0
  let out : Array[Int] = []
  while i < n {
    out.push(i * i)
    i = i + 1
  }
  out
}

fn first_or(xs : Array[Int], d : Int) -> Int {
  if xs.length() > 0 {
    xs[0]
  } else {
    d
  }
}

fn same(xs : Array[Int], ys : Array[Int]) -> Bool {
  xs == ys
}

fn main {
  println(sum([]))
  println(sum([1, 2, 3, 4]))
  println(sum([2147483647, 1]))
  println(count_positive([-2, 0, 5, 7]))
  println(max_or([3, 9, 2], -1))
  println(max_or([], -1))
  println(build_squares(4).length())
  println(build_squares(4)[3])
  println(first_or([42, 7], -1))
  println(first_or([], -1))
  println(same([1, 2], [1, 2]))
  println(same([1, 2], [2, 1]))
  println(same([], []))
}