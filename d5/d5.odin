package d5

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"
import "base:runtime"

// If a page order error is found then return the affected indices.
find_ordering_error :: proc(
  pages: []int,
  ordering_rules: map[int][dynamic]int) -> (index1, index2: int, found: bool) {

  for p, page_index in pages {
    later := ordering_rules[p]

    // Make sure none of the "later" pages occur before this one.
    for l in later {
      error_index, found := slice.linear_search(pages[0:page_index], l)
      if found do return page_index, error_index, true
    }
  }

  return 0, 0, false
}

main :: proc() {
  // Setup an arena allocator as we've got some pretty complex allocation needs.
  buffer := make([]u8, 10_000_000)
  defer delete(buffer)

  a := mem.Arena{}
  mem.arena_init(&a, buffer[:])
  alloc := mem.arena_allocator(&a)

  data := os.read_entire_file("input.txt", allocator = alloc) or_else os.exit(1)

  s := string(data)

  ordering_rules := make(map[int][dynamic]int, allocator = alloc)

  total1, total2 := 0, 0
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 do continue
    else if line[2] == '|' {
      k := strconv.atoi(line[0:2])
      v := strconv.atoi(line[3:])

      _, ok := ordering_rules[k]
      if !ok do ordering_rules[k] = make([dynamic]int, allocator = alloc)

      append(&ordering_rules[k], v)
    }
    else {
      // We've got all the ordering rules. Assess this sequence.
      pages := make([dynamic]int, allocator = alloc)

      tokens := strings.split(line, ",", allocator = alloc)

      assert(len(tokens) % 2 == 1)

      for token in tokens do append(&pages, strconv.atoi(token))

      index1, index2, found := find_ordering_error(pages[:], ordering_rules)
      if !found do total1 += pages[len(pages) / 2]
      else {
        for found {
          slice.swap(pages[:], index1, index2)
          index1, index2, found = find_ordering_error(pages[:], ordering_rules)
        }

        total2 += pages[len(pages) / 2]
      }
    }
  }

  fmt.println("P1:", total1, "P2", total2)
}
