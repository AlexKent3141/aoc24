package d13

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math/linalg"

is_integer :: proc(x: f64) -> bool {
  return math.abs(math.round(x) - x) < 0.0001
}

solve :: proc(m: matrix[2, 2]f64, t: [2]f64) -> (a, b: u64, found: bool) {
  solutions := linalg.inverse(m) * t
  if is_integer(solutions[0]) && is_integer(solutions[1]) {
    return u64(math.round(solutions[0])), u64(math.round(solutions[1])), true
  }

  return 0, 0, false
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  m := matrix[2, 2]f64{}

  total1, total2 := u64(0), u64(0)
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 do continue

    tokens := strings.split(line, " ")
    defer delete(tokens)

    if tokens[0] == "Button" {
      row := tokens[1] == "A:" ? 0 : 1
      m[row][0] = strconv.atof(tokens[2][2:len(tokens[2]) - 1])
      m[row][1] = strconv.atof(tokens[3][2:])
    }
    else if tokens[0] == "Prize:" {
      x_target := u64(strconv.atoi(tokens[1][2:len(tokens[1]) - 1]))
      y_target := u64(strconv.atoi(tokens[2][2:]))

      t := [2]f64{f64(x_target), f64(y_target)}

      a, b, found := solve(m, t)
      if found do total1 += 3 * a + 1 * b

      a, b, found = solve(m, t + f64(10000000000000))
      if found do total2 += 3 * a + 1 * b
    }
  }

  fmt.println("P1:", total1, "P2:", total2)
}
