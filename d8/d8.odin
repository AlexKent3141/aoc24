package d8

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

N :: 50

on_grid :: proc(x, y: int) -> bool {
  return x >= 0 && x < N && y >= 0 && y < N
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  grid := [N*N]u8{}
  anti_nodes := [2][N*N]u8{}

  index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy(grid[N*index:], line)
    index += 1
  }
  
  // Need to examine every pair of antenna with the same frequency and generate antinodes.
  for loc1 in 0..<N*N {
    for loc2 in loc1+1..<N*N {
      if grid[loc1] == grid[loc2] && grid[loc1] != '.' {
        // We need to work in x, y coordinates for the `on_grid` check.
        x1, y1 := math.divmod(loc1, N)
        x2, y2 := math.divmod(loc2, N)

        x_diff := x2 - x1
        y_diff := y2 - y1

        // Step along the line in both directions.
        // For P1 we only want the immediate neighbours, but P2 needs the whole line.
        cand_x, cand_y, num_steps := x1, y1, 0
        for on_grid(cand_x, cand_y) {
          target := cand_y * N + cand_x
          if num_steps == 1 do anti_nodes[0][target] = 1
          anti_nodes[1][target] = 1
          cand_x -= x_diff
          cand_y -= y_diff
          num_steps += 1
        }

        cand_x, cand_y, num_steps = x2, y2, 0
        for on_grid(cand_x, cand_y) {
          target := cand_y * N + cand_x
          if num_steps == 1 do anti_nodes[0][target] = 1
          anti_nodes[1][target] = 1
          cand_x += x_diff
          cand_y += y_diff
          num_steps += 1
        }
      }
    }
  }

  total1 := slice.count(anti_nodes[0][:], 1)
  total2 := slice.count(anti_nodes[1][:], 1)

  fmt.println("P1:", total1, "P2:", total2)
}
