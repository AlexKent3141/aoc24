package d12

import "base:runtime"
import "core:container/avl"
import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

N :: 140

// A location in the grid and the direction the fence is facing.
// Directions are indices into the OFFSETS array.
Fence :: struct {
  loc, dir: int,
  visited: bool
}

fence_cmp :: proc(a, b: Fence) -> slice.Ordering {
  if a.dir != b.dir {
    return a.dir < b.dir ? slice.Ordering.Less : slice.Ordering.Greater
  }
  if a.loc != b.loc {
    return a.loc < b.loc ? slice.Ordering.Less : slice.Ordering.Greater
  }

  return slice.Ordering.Equal
}

on_grid :: proc(x, y: int) -> bool {
  return x >= 0 && x < N && y >= 0 && y < N
}

flood_fill :: proc(
  loc: int,
  grid: []u8,
  overall_considered: ^avl.Tree(int),
  area: ^int,
  perimeter: ^avl.Tree(Fence)) {

  OFFSETS :: [4][2]int {{0, 1}, {0, -1}, {1, 0}, {-1, 0}}
  area^ += 1

  // Consider neighbours of this loc.
  y, x := math.divmod(loc, N)
  for offset, i in OFFSETS {
    next_x, next_y := x + offset[0], y + offset[1]
    if !on_grid(next_x, next_y) {
      // The grid boundary is part of the perimeter.
      avl.find_or_insert(perimeter, Fence { loc, i, false })
    }
    else {
      next_loc := next_y * N + next_x
      if grid[next_loc] == grid[loc] {
        // Part of the same region. Have we already considered it?
        _, inserted, _ := avl.find_or_insert(overall_considered, next_loc)
        if inserted {
          flood_fill(next_loc, grid, overall_considered, area, perimeter)
        }
      }
      else {
        avl.find_or_insert(perimeter, Fence { loc, i, false })
      }
    }
  }
}

count_sides :: proc(perimeter: ^avl.Tree(Fence)) -> int {
  ALONG_EDGE_OFFSETS := [4][2]int {{1, 0}, {1, 0}, {0, 1}, {0, 1}}
  it := avl.iterator(perimeter, avl.Direction.Forward)
  n, found := avl.iterator_next(&it)
  sides := 0
  for found {
    if n.value.visited {
      n, found = avl.iterator_next(&it)
      continue
    }

    // Count this side.
    // Due to the ordering: we will always start in the upper-left of an edge.
    // Due to the direction: we know what the steps along the edge should be.
    sides += 1

    dir := n.value.dir
    loc := n.value.loc
    offset := ALONG_EDGE_OFFSETS[dir]

    next_y, next_x := math.divmod(loc, N)

    next_node := n
    for next_node != nil {
      next_node.value.visited = true
      next_x, next_y = next_x + offset[0], next_y + offset[1]
      if !on_grid(next_x, next_y) do break
      next_loc := next_x + N * next_y
      next_node = avl.find(perimeter, Fence { next_loc, dir, false })
    }
  }

  return sides
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  grid := [N * N]u8{}

  index := 0
  for line in strings.split_lines_iterator(&s) {
    runtime.copy(grid[N * index:], line[:])
    index += 1
  }

  overall_considered: avl.Tree(int)
  avl.init(&overall_considered)
  defer avl.destroy(&overall_considered)

  total1, total2 := 0, 0
  for loc in 0..<N * N {
    _, inserted, _ := avl.find_or_insert(&overall_considered, loc)
    if !inserted do continue

    area := 0
    perimeter: avl.Tree(Fence)
    avl.init_cmp(&perimeter, fence_cmp)
    defer avl.destroy(&perimeter)

    flood_fill(loc, grid[:], &overall_considered, &area, &perimeter)
    total1 += area * avl.len(&perimeter)
    total2 += area * count_sides(&perimeter)
  }

  fmt.println("P1:", total1, "P2:", total2)
}
