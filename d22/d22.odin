package d22

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// Next PRNG step.
step :: proc(n: u64) -> u64 {
  n := n

  // 1
  n ~= (n * 64)
  n %= 16777216

  // 2
  n ~= (n / 32)
  n %= 16777216

  // 3 
  n ~= (n * 2048)
  n %= 16777216

  return n
}

solve :: proc(s, d1, d2, d3, d4: int) -> (int, bool) {
  q := queue.Queue(int){}
  queue.init(&q)
  defer queue.destroy(&q)

  prev := step(u64(s))
  for _ in 1..<1999 {
    next := step(prev)
    defer prev = next

    queue.push_back(&q, int(next % 10) - int(prev % 10))

    if queue.len(q) > 4 do queue.pop_front(&q)

    assert(queue.len(q) <= 4)

    if queue.len(q) == 4 {
      if queue.get(&q, 0) == d1 && queue.get(&q, 1) == d2 &&
         queue.get(&q, 2) == d3 && queue.get(&q, 3) == d4 {
        return int(next % 10), true
      }
    }
  }

  return 0, false
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  seeds := make([dynamic]u64)
  defer delete(seeds)

  for line in strings.split_lines_iterator(&s) {
    n := u64(strconv.atoi(line))
    append(&seeds, n)
  }

  p1 := u64(0)
  for s in seeds {
    s := s
    for _ in 0..<2000 do s = step(s)
    p1 += s
  }

  fmt.println("P1:", p1)

  // Brute-force: iterate all possible sequences of four price changes and see how
  // many bananas we would get across all seeds.

  // Each price can go from -9..9 inclusive.
  p2 := -100000000
  for d1 in -9..=9 {
    fmt.println("Considering:", d1)
    for d2 in -9..=9 {
      for d3 in -9..=9 {
        for d4 in -9..=9 {
          total := 0
          for s in seeds {
            bananas, found := solve(int(s), d1, d2, d3, d4)
            if found do total += bananas
          }

          if total > p2 {
            p2 = total
            fmt.println("New best:", d1, d2, d3, d4, total)
          }
        }
      }
    }
  }

  fmt.println("P2:", p2)
}
