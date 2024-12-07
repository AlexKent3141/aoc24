package d6

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"
import "base:runtime"
import "core:container/avl"

Direction :: enum {
  NORTH,
  EAST,
  SOUTH,
  WEST
}

N :: 130

DIRECTION_STEPS := [4][2]int { {0, -1}, {1, 0}, {0, 1}, {-1, 0} }

Guard :: struct {
  x, y: int,
  dir: Direction
}

guard_cmp :: proc(g1, g2: Guard) -> slice.Ordering {
  if g1.x != g2.x do return g1.x < g2.x ? slice.Ordering.Less : slice.Ordering.Greater
  if g1.y != g2.y do return g1.y < g2.y ? slice.Ordering.Less : slice.Ordering.Greater
  if int(g1.dir) != int(g2.dir) {
    return int(g1.dir) < int(g2.dir) ? slice.Ordering.Less : slice.Ordering.Greater
  }
  return slice.Ordering.Equal
}

on_grid :: proc(x, y: int) -> bool {
  return x >= 0 && x < N && y >= 0 && y < N
}

guard_step :: proc(guard: ^Guard, grid: [N][N]u8) -> bool {
  for {
    d := DIRECTION_STEPS[guard^.dir]
    next_x := guard^.x + d[0]
    next_y := guard^.y + d[1]
    if !on_grid(next_x, next_y) do return false

    // Is this loc blocked?
    if grid[next_y][next_x] == '#' {
      // Increment direction and try again.
      guard^.dir = Direction((int(guard^.dir) + 1) % 4)
    }
    else {
      guard^.x = next_x
      guard^.y = next_y
      return true
    }
  }
}

main :: proc() {
  // Setup an arena allocator as we've got some pretty complex allocation needs.
  buffer := make([]u8, 1_000_000)
  defer delete(buffer)

  a := mem.Arena{}
  mem.arena_init(&a, buffer[:])
  alloc := mem.arena_allocator(&a)

  data := os.read_entire_file("input.txt", allocator = alloc) or_else os.exit(1)

  s := string(data)

  grid := [N][N]u8{}
  visited := [N][N]u8{}
  initial_guard: Guard

  index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy(grid[index][:], line)

    // Fill in the guard's details if they're on this line.
    guard_col, found := slice.linear_search(grid[index][:], '^')
    if found do initial_guard = Guard { guard_col, index, Direction.NORTH }
    index += 1
  }

  guard := initial_guard
  visited[guard.y][guard.x] = 1
  for guard_step(&guard, grid) do visited[guard.y][guard.x] = 1

  total1, total2 := 0, 0
  for row, r in visited {
    for v, c in row {
      // If this location isn't part of the original path then skip it.
      if v == 0 do continue

      total1 += 1

      // Does placing an obstruction here create a cycle?
      if grid[r][c] == '#' do continue

      grid[r][c] = '#'
      defer grid[r][c] = '.'

      arena_temp := mem.begin_arena_temp_memory(&a)
      defer mem.end_arena_temp_memory(arena_temp)

      tree: avl.Tree(Guard)
      avl.init_cmp(&tree, guard_cmp, node_allocator = alloc)

      // Note: we could optimise this further by not inserting every iteration into
      // the tree: we would still be able to detect cycles, and if the guard does
      // escape the grid then we will have avoided some wasted effort.
      cycle := false
      guard := initial_guard
      avl.find_or_insert(&tree, guard)
      for !cycle && guard_step(&guard, grid) {
        _, inserted, err := avl.find_or_insert(&tree, guard)
        if err != runtime.Allocator_Error.None {
          fmt.println("Memory error:", err)
          os.exit(1)
        }

        cycle = !inserted
      }

      if cycle do total2 += 1
    }
  }

  fmt.println("P1:", total1, "P2:", total2)
}
