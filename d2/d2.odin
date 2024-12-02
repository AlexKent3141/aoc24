package d2

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

is_safe :: proc(levels: []string, skip_index: int = -1) -> bool {
  if len(levels) == 1 do return true
  prev_sign: Maybe(bool) = nil
  prev := strconv.atoi(levels[skip_index == 0 ? 1 : 0])
  start := skip_index == 0 ? 2 : 1
  for i in start..<len(levels) {
    if i == skip_index do continue
    next := strconv.atoi(levels[i])
    next_sign := next > prev
    if prev_sign != nil && next_sign != prev_sign do return false
    prev_sign = next_sign
    diff := math.abs(next - prev)
    if diff < 1 || diff > 3 do return false
    prev = next
  }

  return true
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  total1, total2 := 0, 0
  for line in strings.split_lines_iterator(&s) {
    levels := strings.split(line, " ")
    defer delete(levels)

    if is_safe(levels) do total1 += 1

    for i in 0..<len(levels) {
      if is_safe(levels, i) {
        total2 += 1
        break
      }
    }
  }

  fmt.println("P1:", total1, "P2:", total2)
}
