package d23

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:slice"

Id :: distinct int

Vertex :: struct {
  id: Id,
  name: string,
  num_connections: int,
  connections: [100]Id,
  considered: bool,
  count: int
}

add_connection :: proc(v: ^Vertex, target: Id) {
  _, found := slice.linear_search(v^.connections[:v^.num_connections], target)
  if found do return
  v^.connections[v^.num_connections] = target
  v^.num_connections += 1
}

string_to_id :: proc(s: string) -> Id {
  assert(len(s) == 2)
  return Id((int(s[0]) - 'a') * 26 + (int(s[1]) - 'a'))
}

random_walk :: proc(start: ^Vertex, vertices: ^[]Vertex, depth: int) {

  step_to_neighbour :: proc(current: ^Vertex, vertices: ^[]Vertex) -> ^Vertex {
    index := rand.uint32() % u32(current^.num_connections)
    return &vertices[current^.connections[index]]
  }

  current := start

  // Move twice such that we're not a the start.
  for {
    current = step_to_neighbour(start, vertices)
    current = step_to_neighbour(current, vertices)
    if current != start do break
  }

  // Execute a random walk from there.
  for _ in 0..<depth {
    current = step_to_neighbour(current, vertices)
  }

  // If we're back at the start, or at one of the neighbours of start, then this is
  // evidence that we're in a densely connected component.
  _, found := slice.linear_search(start^.connections[:start^.num_connections], current^.id)
  if current == start || found {
    start^.count += 1
  }
}

initialise_vertex :: proc(name: string, vertices: ^[]Vertex) -> (^Vertex, Id) {
  id := string_to_id(name)
  v := &vertices[id]
  if v^.id == 0 {
    v^.id = id
    v^.name = name
  }

  return v, id
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  vertices := make([]Vertex, 26 * 26)
  defer delete(vertices)

  for line in strings.split_lines_iterator(&s) {
    v1_name := line[0:2]
    v2_name := line[3:5]

    // Initialise these vertices if they haven't been yet and connect them.
    v1, id1 := initialise_vertex(v1_name, &vertices)
    v2, id2 := initialise_vertex(v2_name, &vertices)

    add_connection(v1, id2)
    add_connection(v2, id1)
  }

  total := 0
  for &v in vertices {
    for n1 in 0..<v.num_connections {
      v1 := vertices[v.connections[n1]]
      if v1.considered do continue

      for n2 in n1 + 1..<v.num_connections {
        v2 := vertices[v.connections[n2]]
        if v2.considered do continue

        // v1 & v2 are distinct neighbours of v.
        // If there are linked to each other then we have a triple.

        _, found1 := slice.linear_search(v1.connections[:v1.num_connections], v2.id)
        _, found2 := slice.linear_search(v2.connections[:v2.num_connections], v1.id)

        if found1 && found2 {
          // Do any of these start with `t`?
          if v.name[0] == 't' || v1.name[0] == 't' || v2.name[0] == 't' {
            fmt.println(v.name, v1.name, v2.name)
            total += 1
          }
        }
      }
    }

    v.considered = true
  }

  fmt.println("P1:", total)

  // All vertices have exactly 13 connections. This means that the LAN party must have
  // at most 14 elements.
  // In fact, I know experimentally that the whole graph is connected, so at least one
  // neighbour is faces outward from the component. The maximum component size is 13.

  // Use Monte-Carlo simulations again.
  // My idea: do random walks from each location. If the location is part of a large 
  // fully-connected component then there's a particularly high probability that we will
  // get back to the starting point in a few steps.
  for &v in vertices {
    if v.id == 0 do continue
    for _ in 0..<100000 {
      random_walk(&v, &vertices, 4)
    }
  }

  slice.sort_by_cmp(vertices[:], proc(v1, v2: Vertex) -> slice.Ordering {
    if v1.count != v2.count {
      return v1.count > v2.count ? slice.Ordering.Less : slice.Ordering.Greater
    }

    return slice.Ordering.Equal
  })

  fmt.println("Top stats:")
  for v, i in vertices[0:30] {
    fmt.println(i, v.name, v.count)
  }

  names := slice.mapper(vertices[0:13], proc(v: Vertex) -> string { return v.name })
  defer delete(names)

  slice.sort(names)

  fmt.print("P2: ")
  for name, i in names {
    fmt.print(name)
    if i < len(names) - 1 do fmt.print(",")
  }
  fmt.println()
}
