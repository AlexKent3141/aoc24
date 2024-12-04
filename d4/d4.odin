package d4

import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"

N :: 140
xmas := [4]u8 {'X', 'M', 'A', 'S'}
grid: [N][N]u8

on_grid :: proc(x, y: int) -> bool {
  return x >= 0 && y >= 0 && x < N && y < N
}

offset_matcher :: proc(x, y, dx, dy: int) -> bool {
  next_x, next_y := x, y
  for i in 0..<4 {
    if !on_grid(next_x, next_y) ||
       grid[next_y][next_x] != xmas[i] {
      return false
    }

    next_x, next_y = next_x + dx, next_y + dy
  }

  return true
}

// Check whether x, y is the centre of a MAS cross.
xmas_matcher :: proc(x, y: int) -> bool {
  if grid[y][x] != 'A' do return false

  if !on_grid(x - 1, y - 1) ||
     !on_grid(x - 1, y + 1) ||
     !on_grid(x + 1, y - 1) ||
     !on_grid(x + 1, y + 1) {
    return false
  }

  d1 := []u8 { grid[y - 1][x - 1], grid[y + 1][x + 1] }
  d2 := []u8 { grid[y + 1][x - 1], grid[y - 1][x + 1] }

  d1_str := string(d1)
  d2_str := string(d2)

  return (d1_str == "MS" || d1_str == "SM") &&
         (d2_str == "MS" || d2_str == "SM")
}

count_matches :: proc(matcher: proc(x, y: int) -> bool) -> int {
  total := 0
  for y in 0..<N {
    for x in 0..<N {
      if matcher(x, y) do total += 1
    }
  }
  return total
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy(grid[index][:], line)
    index += 1
  }

  total1 :=
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y,  0,  1) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y,  0, -1) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y,  1,  0) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y, -1,  0) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y,  1,  1) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y,  1, -1) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y, -1,  1) }) +
    count_matches(proc(x, y: int) -> bool { return offset_matcher(x, y, -1, -1) })

  total2 := count_matches(proc(x, y: int) -> bool { return xmas_matcher(x, y) })

  fmt.println("P1:", total1, "P2:", total2)
}
