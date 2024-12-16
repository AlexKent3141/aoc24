package d16

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:container/priority_queue"
import "core:container/avl"

is_empty :: proc(c: rune) -> bool {
  return strings.index_rune(".SE", c) != -1
}

Orientation :: enum {
  HORIZONTAL,
  VERTICAL
}

Edge :: struct {
  end_vertex_ids: [2]int,
  orientation: Orientation,
  length: int,
  best_score: int
}

other_end :: proc(e: Edge, vertex_index: int) -> int {
  return vertex_index == e.end_vertex_ids[0] ? e.end_vertex_ids[1] : e.end_vertex_ids[0]
}

Vertex :: struct {
  x, y: int,
  num_edges: int,
  edge_ids: [4]int
}

is_raw_vertex :: proc(x, y: int, raw_grid: []string) -> bool {
  if !is_empty(rune(raw_grid[y][x])) do return false

  Location :: struct { x, y: int }

  num_neighbours := 0
  empty_neighbours := [4]Location{}

  if is_empty(rune(raw_grid[y][x + 1])) {
    empty_neighbours[num_neighbours] = { x + 1, y }
    num_neighbours += 1
  }

  if is_empty(rune(raw_grid[y][x - 1])) {
    empty_neighbours[num_neighbours] = { x - 1, y }
    num_neighbours += 1
  }

  if is_empty(rune(raw_grid[y + 1][x])) {
    empty_neighbours[num_neighbours] = { x, y + 1 }
    num_neighbours += 1
  }

  if is_empty(rune(raw_grid[y - 1][x])) {
    empty_neighbours[num_neighbours] = { x, y - 1 }
    num_neighbours += 1
  }

  if num_neighbours != 2 {
    // Must be a junction (or dead end).
    return true
  }

  // Check for a change of direction.
  if empty_neighbours[0].x != empty_neighbours[1].x &&
     empty_neighbours[0].y != empty_neighbours[1].y {
    return true
  }

  return false
}

// For each edge we need to keep track of the shortest path edges leading to it.
Path_Edges :: struct {
  num_edges: int,
  edge_ids: [4]int,
  min_score: int
}

path_cache_insert :: proc(path_edges: ^Path_Edges, edge_id, score: int) {
  for index in 0..<path_edges.num_edges {
    if path_edges.edge_ids[index] == edge_id do return
  }

  if path_edges.min_score == 0 do path_edges.min_score = score

  if score < path_edges.min_score {
    // This is better than all previous edges.
    path_edges.edge_ids[0] = edge_id
    path_edges.num_edges = 1
    path_edges.min_score = score
  }
  else if score == path_edges.min_score {
    path_edges.edge_ids[path_edges.num_edges] = edge_id
    path_edges.num_edges += 1
  }
}

aggregate_affected_edges :: proc(target_id: int, cache: []Path_Edges, tree: ^avl.Tree(int)) {
  if target_id == -1 do return
  entry := cache[target_id]
  if entry.num_edges > 0 {
    avl.find_or_insert(tree, target_id)
  }

  for i in 0..<entry.num_edges {
    aggregate_affected_edges(entry.edge_ids[i], cache, tree)
  }
}

path_score :: proc(start_index, end_index: int, vertices: []Vertex, edges: ^[dynamic]Edge) -> (lowest_score, tiles_in_best_paths: int) {

  // Moving to edge-centric approach to deal with issues generating multiple paths.
  // The problem is that different paths can reach the same vertex with scores that are
  // off by one rotation. When the rotation happens then they have the same score.
  Node :: struct {
    edge_index: int,
    score_so_far: int,
    from_vertex_index: int
  }

  q := priority_queue.Priority_Queue(Node){}
  priority_queue.init(&q,
    proc(a, b: Node) -> bool { return a.score_so_far < b.score_so_far },
    proc(arr: []Node, i, j: int) { slice.swap(arr, i, j) })
 
  defer priority_queue.destroy(&q)

  edge_path_edges := make([]Path_Edges, len(edges))
  defer delete(edge_path_edges)

  start := vertices[start_index]
  for i in 0..<start.num_edges {
    edge := edges[start.edge_ids[i]]
    score := edge.orientation == Orientation.HORIZONTAL ? 0 : 1000
    priority_queue.push(&q, Node{start.edge_ids[i], score, start_index})
    path_cache_insert(&edge_path_edges[start.edge_ids[i]], -1, score)
  }

  known_best_score: Maybe(int) = nil

  edges_past_end := Path_Edges{}

  for priority_queue.len(q) > 0 {
    n := priority_queue.pop(&q)

    current_edge := edges[n.edge_index]
    next_base_score := n.score_so_far + current_edge.length

    if current_edge.end_vertex_ids[0] == end_index || current_edge.end_vertex_ids[1] == end_index {
      if known_best_score == nil {
        known_best_score = next_base_score
        path_cache_insert(&edges_past_end, n.edge_index, next_base_score)
      }
    }

    if known_best_score != nil && next_base_score > known_best_score.? do break

    // Add neighbours to the Q.
    end := other_end(current_edge, n.from_vertex_index)
    end_vertex := vertices[end]
    for i in 0..<end_vertex.num_edges {

      neighbour_edge_index := end_vertex.edge_ids[i]
      if neighbour_edge_index == n.edge_index do continue

      neighbour_edge := edges[neighbour_edge_index]

      next_score := next_base_score + (current_edge.orientation == neighbour_edge.orientation ? 0 : 1000)
      // Check that we haven't already reached this vertex with a lower score.
      if next_score <= neighbour_edge.best_score {
        priority_queue.push(&q, Node{neighbour_edge_index, next_score, end})

        edges[neighbour_edge_index].best_score = next_score

        // Add this route to the edge path cache for the target.
        path_cache_insert(&edge_path_edges[neighbour_edge_index], n.edge_index, next_score)
      }
    }
  }

  // Now backtrack from the edges leading to the target and find all affected paths.
  tree := avl.Tree(int){}
  avl.init(&tree)
  defer avl.destroy(&tree)

  for i in 0..<edges_past_end.num_edges {
    aggregate_affected_edges(edges_past_end.edge_ids[i], edge_path_edges, &tree)
  }

  // We also need to be careful around vertices that are included twice.
  // Calculate a set of these.
  vertex_tree := avl.Tree(int){}
  avl.init(&vertex_tree)
  defer avl.destroy(&vertex_tree)

  total := 0
  it := avl.iterator(&tree, avl.Direction.Forward)
  node, _ := avl.iterator_next(&it)
  for node != nil {
    edge := edges[node.value]

    total += edge.length - 1
    node, _ = avl.iterator_next(&it)

    avl.find_or_insert(&vertex_tree, edge.end_vertex_ids[0])
    avl.find_or_insert(&vertex_tree, edge.end_vertex_ids[1])
  }

  total += avl.len(&vertex_tree)

  return known_best_score.?, total
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  raw_grid := make([dynamic]string)
  defer delete(raw_grid)

  // First challenge: construct a graph from the map data.
  // In the graph the vertices will be junctions in the maze and edges will be
  // corridors between junctions.
  // We need to be able to distinguish between vertical and horizontal edges in
  // order to account for the turning score.
  for line in strings.split_lines_iterator(&s) do append(&raw_grid, line)

  vertices := make([dynamic]Vertex)
  defer delete(vertices)

  edges := make([dynamic]Edge)
  defer delete(edges)

  // First pass: detect junctions and create the vertices.
  width := len(raw_grid[0])
  height := len(raw_grid)

  for y in 0..<height {
    for x in 0..<width {
      if is_raw_vertex(x, y, raw_grid[:]) {
        append(&vertices, Vertex { x, y, 0, {} })
      }
    }
  }

  // Next go over the vertices. Create edges by iterating outwards from each vertex.
  for &v, start_index in vertices {
    // Consider edges coming out to the right and downwards from this edges.
    x, y := v.x + 1, v.y
    length := 0
    for is_empty(rune(raw_grid[y][x])) && !is_raw_vertex(x, y, raw_grid[:]) {
      length += 1
      x += 1
    }

    if length > 0 { // Find the vertex at the far end.
      end_index := -1
      for v2, i in vertices {
        if v2.x == x && v2.y == y {
          end_index = i
          break
        }
      }

      edge := Edge{{start_index, end_index}, Orientation.HORIZONTAL, length + 1, 1000000}

      v.edge_ids[v.num_edges] = len(edges)
      v.num_edges += 1
      vertices[end_index].edge_ids[vertices[end_index].num_edges] = len(edges)
      vertices[end_index].num_edges += 1
      append(&edges, edge)
    }

    x, y = v.x, v.y + 1
    length = 0
    for is_empty(rune(raw_grid[y][x])) && !is_raw_vertex(x, y, raw_grid[:]) {
      length += 1
      y += 1
    }

    if length > 0 {
      // Find the vertex at the far end.
      end_index := -1
      for v2, i in vertices {
        if v2.x == x && v2.y == y {
          end_index = i
          break
        }
      }

      edge := Edge{{start_index, end_index}, Orientation.VERTICAL, length + 1, 1000000}

      v.edge_ids[v.num_edges] = len(edges)
      v.num_edges += 1
      vertices[end_index].edge_ids[vertices[end_index].num_edges] = len(edges)
      vertices[end_index].num_edges += 1
      append(&edges, edge)
    }
  }

  // Find the start and end vertices.
  start_index, end_index: int
  for v, i in vertices {
    if raw_grid[v.y][v.x] == 'S' do start_index = i
    if raw_grid[v.y][v.x] == 'E' do end_index = i
  }

  p1, p2 := path_score(start_index, end_index, vertices[:], &edges)
  fmt.println("P1:", p1, "P2:", p2)
}
