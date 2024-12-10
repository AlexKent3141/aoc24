package d10

import "base:runtime"
import "core:container/avl"
import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

N :: 48
DIRECTIONS :: [4][2]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

on_grid :: proc(x, y: int) -> bool {
  return x >= 0 && x < N && y >= 0 && y < N
}

find_trails :: proc(
  grid: []u8,
  current_index: int,
  tree: ^avl.Tree(int)) -> int {

  current_val := grid[current_index]
  if current_val == '9' {
    avl.find_or_insert(tree, current_index)
    return 1
  }

  // Consider neighbours that are 1 higher than the current.
  total := 0
  y, x := math.divmod(current_index, N)
  for offset in DIRECTIONS {
    next_x, next_y := x + offset[0], y + offset[1]
    next_index := next_y * N + next_x
    if on_grid(next_x, next_y) && grid[next_index] == current_val + 1 {
      total += find_trails(
        grid,
        next_index,
        tree)
    }
  }

  return total
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  grid := [N * N]u8{}

  row_index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy(grid[row_index * N:], line[:])
    row_index += 1
  }

  total1, total2 := 0, 0
  next_index, found := slice.linear_search(grid[:], '0')
  prev_index := next_index
  for found {
    // Count the possible trail destinations from here.
    tree: avl.Tree(int)
    avl.init(&tree)
    defer avl.destroy(&tree)

    total2 += find_trails(grid[:], next_index, &tree)
    total1 += avl.len(&tree)

    next_index, found = slice.linear_search(grid[next_index + 1:], '0')
    next_index += prev_index + 1
    prev_index = next_index
  }

  fmt.println("P1:", total1, "P2:", total2)
}
