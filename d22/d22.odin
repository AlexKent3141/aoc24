package d22

import "core:container/queue"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

// Next PRNG step.
step :: proc(n: u64) -> u64 {
  K :: 16777216

  n := n

  n ~= n << 6
  n %= K

  n ~= n >> 5
  n %= K

  n ~= n << 11
  n %= K

  return n
}

ComboKey :: distinct int

make_key :: proc(d1, d2, d3, d4: int) -> ComboKey {
  return ComboKey(
    (d1 + 10) +
    (d2 + 10) << 4 +
    (d3 + 10) << 8 +
    (d4 + 10) << 12
  )
}

solve_seed :: proc(s: u64, results: ^map[ComboKey](int)) {
  q := queue.Queue(int){}
  queue.init(&q)
  defer queue.destroy(&q)

  prev := step(s)
  for _ in 1..<1999 {
    next := step(prev)
    defer prev = next

    queue.push_back(&q, int(next % 10) - int(prev % 10))

    if queue.len(q) > 4 do queue.pop_front(&q)

    assert(queue.len(q) <= 4)

    if queue.len(q) == 4 {
      // Update the cache with this new occurrence.
      key := make_key(
        queue.get(&q, 0),
        queue.get(&q, 1),
        queue.get(&q, 2),
        queue.get(&q, 3)
      ) 

      if key in results^ do continue

      results^[key] += int(next % 10)
    }
  }
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  cache := make(map[ComboKey](int))
  defer delete(cache)

  seed_cache := make(map[ComboKey](int))
  defer delete(seed_cache)

  p1 := u64(0)

  for line in strings.split_lines_iterator(&s) {
    seed := u64(strconv.atoi(line))

    next := seed
    for _ in 0..<2000 do next = step(next)
    p1 += next

    clear(&seed_cache)

    solve_seed(seed, &seed_cache)

    for k, v in seed_cache do cache[k] += v
  }

  // Find the largest cache entry.
  p2 := 0
  for _, v in cache {
    p2 = math.max(p2, v)
  }

  fmt.println("P1:", p1, "P2:", p2)
}
