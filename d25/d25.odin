package d25

import "core:fmt"
import "core:os"
import "core:strings"

Columns :: struct {
  heights: [5]int
}

is_fit :: proc(lock, key: Columns) -> bool {
  // Check now intersections.
  for col in 0..<5 {
    if lock.heights[col] + key.heights[col] > 5 do return false
  }

  return true
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  locks := make([dynamic]Columns)
  defer delete(locks)

  keys := make([dynamic]Columns)
  defer delete(keys)

  current_grid := [7]string{}

  row := 0
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 {
      row = 0
      continue
    }

    // Include into the current grid.
    current_grid[row] = line

    row += 1

    if row == 7 {
      // Grid is full. Process it.
      is_lock := strings.compare(current_grid[0], "#####") == 0

      cols := Columns{}
      for col in 0..<5 {
        num_full := 0
        for row in current_grid {
          num_full += row[col] == '#'
        }

        cols.heights[col] = num_full - 1
      }

      if is_lock do append(&locks, cols)
      else do append(&keys, cols)
    }
  }

  p1 := 0
  for lock in locks {
    for key in keys {
      if is_fit(lock, key) do p1 += 1
    }
  }

  fmt.println("P1:", p1)
}
