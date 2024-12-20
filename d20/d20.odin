package d20

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:container/avl"
import "core:container/queue"
import "core:math"

W :: 141
H :: 141
TARGET_SAVING :: 100

OFFSETS := [4][2]int{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

is_empty :: proc(c: rune) -> bool {
  return strings.index_rune(".SE", c) != -1
}

// Standard BFS from the start location and filling the entire grid.
// When this completes we will know how far away each location is from the start.
path :: proc(
  start_index: int,
  grid: []u8,
  distance_from_start: []int) {

  assert(grid[start_index] != '#')

  Node :: struct {
    location_index: int,
    dist: int
  }

  q := queue.Queue(Node){}
  queue.init(&q)
  defer queue.destroy(&q)

  queue.push_back(&q, Node{start_index, 0})

  // Cache shortest distances so far.
  slice.fill(distance_from_start[:], -1)
  distance_from_start[start_index] = 0

  for queue.len(q) > 0 {
    current := queue.pop_front(&q)

    // Consider neighbours.
    for offset in OFFSETS {
      next_index := current.location_index + offset[0] + offset[1] * W
      if !is_empty(rune(grid[next_index])) do continue

      next_dist := current.dist + 1
      if distance_from_start[next_index] == -1 || next_dist < distance_from_start[next_index] {
        distance_from_start[next_index] = next_dist
        queue.push_back(&q, Node{next_index, next_dist})
      }
    }
  }
}

Cheat :: struct {
  start_index, end_index: int,
  length: int
}

populate_cheats :: proc(
  start_index, max_cheat_length: int,
  grid: []u8,
  cheat_targets: ^[dynamic]Cheat) {

  assert(is_empty(rune(grid[start_index])))

  Node :: struct {
    location_index: int,
    num_steps: int
  }

  considered := avl.Tree(int){}
  avl.init(&considered)
  defer avl.destroy(&considered)

  avl.find_or_insert(&considered, start_index)

  q := queue.Queue(Node){}
  queue.init(&q)
  defer queue.destroy(&q)

  queue.push_back(&q, Node{start_index, 0})

  for queue.len(q) > 0 {
    current := queue.pop_front(&q)
    if current.num_steps > max_cheat_length do break

    if is_empty(rune(grid[current.location_index])) {
      // Cheat target.
      append(cheat_targets, Cheat{start_index, current.location_index, current.num_steps})
    }

    // Generate neighbours.
    y, x := math.divmod(current.location_index, W)
    for offset in OFFSETS {
      // Need to do an on-grid check.
      next_x, next_y := x + offset[0], y + offset[1]
      if next_x < 0 || next_x >= W || next_y < 0 || next_y >= H do continue

      // If we haven't already considered it then enqueue.
      next_index := next_y * W + next_x
      _, inserted, _ := avl.find_or_insert(&considered, next_index)
      if inserted {
        queue.push_back(&q, Node{next_index, current.num_steps + 1})
      }
    }
  }
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  grid := make([]u8, W * H)
  defer delete(grid)

  row_index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy_slice(grid[row_index * W:], transmute([]u8)line)
    row_index += 1
  }

  // Find the start and end vertices.
  start_index, _ := slice.linear_search(grid[:], 'S')
  end_index, _ := slice.linear_search(grid[:], 'E')

  // Start with calculating shortest paths from each location to the start and the end.
  distance_from_start := make([]int, W * H)
  defer delete(distance_from_start)
  path(start_index, grid[:], distance_from_start[:])

  distance_from_end := make([]int, W * H)
  defer delete(distance_from_end)
  path(end_index, grid[:], distance_from_end[:])

  assert(distance_from_start[end_index] == distance_from_end[start_index])

  baseline_path_length := distance_from_start[end_index]

  // For each empty location in the grid consider available cheats.
  p1, p2 := 0, 0
  for location_index in 0..<len(grid) {
    if !is_empty(rune(grid[location_index])) do continue

    cheats := make([dynamic]Cheat)
    defer delete(cheats)

    populate_cheats(location_index, 2, grid[:], &cheats)

    // For each shortcut, does it save enough time?
    for cheat in cheats {
      length := distance_from_start[cheat.start_index] +
                cheat.length +
                distance_from_end[cheat.end_index]
      if length <= baseline_path_length - TARGET_SAVING {
        p1 += 1
      }
    }

    clear(&cheats)
    populate_cheats(location_index, 20, grid[:], &cheats)

    // For each shortcut, does it save enough time?
    for cheat in cheats {
      length := distance_from_start[cheat.start_index] +
                cheat.length +
                distance_from_end[cheat.end_index]
      if length <= baseline_path_length - TARGET_SAVING {
        p2 += 1
      }
    }
  }

  fmt.println("P1:", p1, "P2:", p2)
}
