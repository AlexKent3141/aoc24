package d19

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

match :: proc(pattern: string, towels: []string, cache: []int) -> int {
  if len(pattern) == 0 do return 1

  if cache[len(pattern)] != -1 do return cache[len(pattern)]

  // Try to match each towel with the start of the remaining pattern.
  num_ways := 0
  for towel in towels {
    if len(towel) <= len(pattern) && strings.compare(towel, pattern[:len(towel)]) == 0 {
      num_ways += match(pattern[len(towel):], towels[:], cache)
    }
  }

  cache[len(pattern)] = num_ways

  return num_ways
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  towels := make([dynamic]string)
  defer delete(towels)

  index := 0
  p1, p2 := 0, 0
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 do continue

    if index == 0 {
      tokens := strings.split(line, ", ")
      defer delete(tokens)
      for towel in tokens do append(&towels, towel)
    }
    else {
      // Pattern to match.
      cache := make([]int, len(line) + 1)
      defer delete(cache)
      slice.fill(cache[:], -1)

      num_ways := match(line, towels[:], cache)
      if num_ways > 0 {
        p1 += 1
        p2 += num_ways
      }
    }

    index += 1
  }

  fmt.println("P1:", p1, "P2:", p2)
}
