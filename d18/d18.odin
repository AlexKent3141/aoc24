package d18

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

N :: 71
OFFSETS := [4][2]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

solve :: proc(
  start_x, start_y, target_x, target_y: int, grid: [N][N]u8) -> (length: int, found: bool) {

  Location :: struct { x, y, dist: int }

  todo := queue.Queue(Location){}
  queue.init(&todo)
  defer queue.destroy(&todo)

  queue.push_back(&todo, Location{x=start_x, y=start_y, dist=0})

  shortest_distances := [N][N]int{}
  for &row in shortest_distances do slice.fill(row[:], N * N)

  target_reached := false

  for queue.len(todo) > 0 {
    current := queue.pop_front(&todo)

    // Check: did we already reach this location faster?
    if shortest_distances[current.y][current.x] <= current.dist do continue

    shortest_distances[current.y][current.x] = current.dist

    if current.x == target_x && current.y == target_y {
      target_reached = true
      break
    }

    // Generate neighbours.
    for offset in OFFSETS {
      next_x, next_y := current.x + offset[0], current.y + offset[1]
      if next_x < 0 || next_x > N - 1 || next_y < 0 || next_y > N - 1 do continue
      if grid[next_y][next_x] != 0 do continue
      queue.push_back(&todo, Location{next_x, next_y, current.dist + 1})
    }
  }

  if target_reached do return shortest_distances[70][70], true
  else do return -1, false
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  grid := [N][N]u8{}

  // For P1 simulate just the first 1024 bytes falling.
  p1 := 0
  p2 := ""
  index := 0
  for line in strings.split_lines_iterator(&s) {

    tokens := strings.split(line, ",")
    defer delete(tokens)

    x := strconv.atoi(tokens[0])
    y := strconv.atoi(tokens[1])

    grid[y][x] = 1

    index += 1

    if index == 1024 {
      p1, _ = solve(0, 0, 70, 70, grid)
    }
    else if index > 1024 {
      // Can we still find a path?
      _, found := solve(0, 0, 70, 70, grid)
      if !found {
        p2 = line
        break
      }
    }
  }

  fmt.println("P1:", p1, "P2:", p2)
}
