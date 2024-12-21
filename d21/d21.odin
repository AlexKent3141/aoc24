package d21

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:container/avl"
import "core:container/priority_queue"
import "core:math"
import "core:strconv"

Transition_Key :: distinct int

make_key :: proc(from, to: u8) -> Transition_Key {
  return Transition_Key(int(from) << 8 + int(to))
}

print_key :: proc(tk: Transition_Key) {
  v := int(tk) & 0xFF
  k := int(tk) >> 8
  fmt.print(rune(k), ",", rune(v))
}

print_map :: proc(m: map[Transition_Key]($V)) {
  for k, v in m {
    print_key(k)
    fmt.println(",", v)
  }
  fmt.println()
}

ACTIONS := [5]u8{'<', '>', 'v', '^', 'A'}

Grid :: struct($W, $H: int) {
  data: []u8
}

shortest_path :: proc(
  start, target: u8,
  grid: Grid($W, $H),
  weights: map[Transition_Key](u64)) -> u64 {

  Node :: struct {
    location: int,
    prev_action: u8,
    dist: u64
  }

  q := priority_queue.Priority_Queue(Node){}
  priority_queue.init(&q,
    proc(a, b: Node) -> bool { return a.dist < b.dist },
    proc(arr: []Node, i, j: int) { slice.swap(arr, i, j) })

  defer priority_queue.destroy(&q)

  start_index, _ := slice.linear_search(grid.data[:], start)
  target_index, _ := slice.linear_search(grid.data[:], target)

  priority_queue.push(&q, Node{start_index, 'A', 0})

  for priority_queue.len(q) > 0 {
    current := priority_queue.pop(&q)
    assert(grid.data[current.location] != '#')

    if grid.data[current.location] == target {
      return current.dist + weights[make_key(current.prev_action, 'A')]
    }

    // Consider next move.
    if grid.data[current.location + 1] != '#' {
      priority_queue.push(
        &q,
        Node{
          current.location + 1, '>', current.dist + weights[make_key(current.prev_action, '>')]
          })
    }
    if grid.data[current.location - 1] != '#' {
      priority_queue.push(
        &q,
        Node{
          current.location - 1, '<', current.dist + weights[make_key(current.prev_action, '<')]
          })
    }
    if grid.data[current.location + W] != '#' {
      priority_queue.push(
        &q,
        Node{
          current.location + W, 'v', current.dist + weights[make_key(current.prev_action, 'v')]
          })
    }
    if grid.data[current.location - W] != '#' {
      priority_queue.push(
        &q,
        Node{
          current.location - W, '^', current.dist + weights[make_key(current.prev_action, '^')]
          })
    }
  }

  assert(false)
  return 0
}

solve :: proc(output: string, num_robots: int) -> u64 {

  // Our input cache.
  cache := map[Transition_Key](u64){}

  for from in ACTIONS {
    for to in ACTIONS {
      key := make_key(from, to)
      cache[key] = 1
    }
  }

  direction_grid_str := "#######^A##<v>######"
  directional_grid := Grid(5, 4){transmute([]u8)direction_grid_str}

  for _ in 0..<num_robots {
    cache2 := map[Transition_Key](u64){}

    for from in ACTIONS {
      for to in ACTIONS {
        key := make_key(from, to)

        dist := shortest_path(from, to, directional_grid, cache)
        cache2[key] = dist
      }
    }

    delete(cache)
    cache = cache2
  }

  print_map(cache)

  // Finally we can use these edge weights to assess the numeric pad.
  numeric_grid_str := "######789##456##123###0A######"
  numeric_grid := Grid(5, 6){transmute([]u8)numeric_grid_str}

  current := 'A'
  total := u64(0)
  for target in output {
    dist := shortest_path(u8(current), u8(target), numeric_grid, cache)
    total += dist
    current = target
  }

  delete(cache)

  return total
}

main :: proc() {

/*

  < | >
  A | >>A
  A | vAA^A

  A | <
  A | v<<A
  A | v<A<AA>>^A
    
*/

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  p1, p2 := u64(0), u64(0)
  for line in strings.split_lines_iterator(&s) {
    count1, count2 := solve(line, 2), solve(line, 25)
    fmt.println(count1, count2)
    p1 += count1 * u64(strconv.atoi(line[0:3]))
    p2 += count2 * u64(strconv.atoi(line[0:3]))

    fmt.println(p1, p2)
  }

  fmt.println("P1:", p1, "P2:", p2)
}
