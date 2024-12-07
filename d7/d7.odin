package d7

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

Binary_Op :: proc(int, int) -> int

concat :: proc(x, y: int) -> int {
  power_of_10 := 1
  for y >= power_of_10 do power_of_10 *= 10
  return x * power_of_10 + y
}

can_solve :: proc(
  ops: []Binary_Op,
  target: int,
  operands: []int,
  current: int = 0) -> bool {

  if current == 0 {
    return can_solve(ops, target, operands[1:], operands[0])
  }

  if len(operands) == 0 {
    return current == target
  }

  // Check if we can solve with either of the available operators.
  for op in ops {
    if can_solve(ops, target, operands[1:], op(current, operands[0])) {
      return true
    }
  }

  return false
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  total1, total2 := 0, 0

  p1_ops := []Binary_Op {
    proc(x, y: int) -> int { return x + y },
    proc(x, y: int) -> int { return x * y }
  }

  p2_ops := []Binary_Op {
    proc(x, y: int) -> int { return x + y },
    proc(x, y: int) -> int { return x * y },
    concat
  }

  for line in strings.split_lines_iterator(&s) {
    sides := strings.split(line, ": ")
    defer delete(sides)

    assert(len(sides) == 2)
    test_value := strconv.atoi(sides[0])
    operand_strs := strings.split(sides[1], " ")
    defer delete(operand_strs)

    operands := slice.mapper(
      operand_strs[:],
      proc(s: string) -> int { return strconv.atoi(s) })

    defer delete(operands)

    if can_solve(p1_ops, test_value, operands[:]) {
      total1 += test_value
      total2 += test_value
    }
    else if can_solve(p2_ops, test_value, operands[:]) {
      total2 += test_value
    }
  }

  fmt.println("P1:", total1, "P2:", total2)
}
