package d15

import "base:runtime"
import "core:container/queue"
import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

N :: 50

do_move_with_offset :: proc(grid: ^[$T]u8, offset: int) {
  robot_index, found := slice.linear_search(grid[:], '@')
  assert(found)

  next_index := robot_index + offset

  // If it's a wall then no action.
  if grid[next_index] == '#' do return

  // If it's empty then just move there.
  if grid[next_index] == '.' {
    grid[robot_index] = '.'
    grid[next_index] = '@'
    return
  }

  when T == N * N {
    // We've got a box.
    // Iterate to the next empty spot.
    // If along the way we encounter a wall then no action.
    // If we find an empty spot then shift all intervening boxes.
    for grid[next_index] == 'O' {
      next_index += offset
    }

    if grid[next_index] == '#' do return

    grid[robot_index] = '.'
    grid[robot_index + offset] = '@'
    grid[next_index] = 'O'
  }
  else when T == 2 * N * N {
    // We've got a box.
    // If we're going left or right things are relatively easy with similar logic to before.
    // If we're going vertically then we need to carefully consider "multi-push" moves.
    if math.abs(offset) == 1 {
      // Iterate to the next empty spot.
      // If along the way we encounter a wall then no action.
      // If we find an empty spot then shift all intervening boxes.
      for grid[next_index] == '[' || grid[next_index] == ']' {
        next_index += offset
      }

      if grid[next_index] == '#' do return

      // Shift this slice by the offset.
      if offset == -1 do runtime.copy(grid[next_index:], grid[next_index+1:robot_index])
      else            do runtime.copy(grid[robot_index+2:], grid[robot_index+1:next_index])
    }
    else {
      // Do a BFS to find all of the affected box locations.
      // Along the way we'll consider the targets, so we'll know if this move is blocked.
      indices_to_move := make([dynamic]int)
      defer delete(indices_to_move)

      // In the todo queue store the left brace index for each box.
      todo: queue.Queue(int)
      queue.init(&todo)
      defer queue.destroy(&todo)

      if grid[next_index] == '[' do queue.push_back(&todo, next_index)
      else                       do queue.push_back(&todo, next_index - 1)

      for queue.len(todo) > 0 {
        box_index := queue.pop_front(&todo)

        append(&indices_to_move, box_index)
        append(&indices_to_move, box_index + 1)

        // Consider the locations directly adjacent to this box in the offset dir.
        next_index1 := box_index + offset
        next_index2 := box_index + offset + 1

        // Check whether we've found a blocker.
        if grid[next_index1] == '#' || grid[next_index2] == '#' do return

        // Does this box push other boxes?
        if grid[next_index1] == '[' {
          // Pushing single box.
          queue.push_back(&todo, next_index1)
        }
        else if grid[next_index1] == ']' {
          // Pushing box on the left.
          queue.push_back(&todo, next_index1 - 1)
        }

        // We could also be pushing a box on the right.
        if grid[next_index2] == '[' {
          queue.push_back(&todo, next_index2)
        }
      }

      // Now update the box positions.
      // It should be safe to start from the back of the array and check that we haven't
      // already moved a box.
      #reverse for i in indices_to_move {
        // Move this box in the offset dir.
        if grid[i] != '.' {
          grid[i + offset] = grid[i]
          grid[i] = '.'
        }
      }
    }

    grid[robot_index] = '.'
    grid[robot_index + offset] = '@'
  }
}

do_move :: proc(grid: ^[$T]u8, dir: rune) {
  switch dir {
    case '<':
      do_move_with_offset(grid, -1)
    case '>':
      do_move_with_offset(grid, 1)
    case '^':
      do_move_with_offset(grid, -T / N)
    case 'v':
      do_move_with_offset(grid, T / N)
  }
}

score :: proc(grid: [$T]u8, target: u8) -> int {
  total := 0
  for c, i in grid {
    if c == target {
      y, x := math.divmod(i, T / N)
      total += 100 * y + x
    }
  }

  return total
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  grid1 := [N * N]u8{}
  grid2 := [2 * N * N]u8{}

  row := 0
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 do continue
    else if len(line) == N {
      runtime.copy(grid1[N * row:], line[:])

      // Do the mapping required for the P2 grid.
      index := 2 * N * row
      for c in line {
        switch c {
          case '#':
            grid2[index] = '#'
            grid2[index + 1] = '#'
          case 'O':
            grid2[index] = '['
            grid2[index + 1] = ']'
          case '.':
            grid2[index] = '.'
            grid2[index  + 1] = '.'
          case '@':
            grid2[index] = '@'
            grid2[index + 1] = '.'
        }

        index += 2
      }

      row += 1
    }
    else {
      // Do these instructions.
      for dir in line {
        do_move(&grid1, dir)
        do_move(&grid2, dir)
      }
    }
  }

  fmt.println("P1:", score(grid1, 'O'), "P2:", score(grid2, '['))
}
