package d11

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

num_len :: proc(n: u64) -> int {
  assert(n != 0)
  len := 0
  power_of_10: u64 = 1
  for power_of_10 <= n {
    len += 1
    power_of_10 *= 10
  }

  return len
}

Key :: struct {
  n: u64,
  remaining: int
}

count_expanded :: proc(n: u64, remaining_blinks: int, cache: ^map[Key]u64) -> u64 {

  val, found := cache[Key{n, remaining_blinks}]
  if found do return val

  if remaining_blinks == 0 do return 1

  if n == 0 {
    val = count_expanded(1, remaining_blinks - 1, cache)
    cache[Key{0, remaining_blinks}] = val
    return val
  }

  n_len := num_len(n)
  if n_len % 2 == 0 {

    left := n / u64(math.pow10_f64(f64(n_len / 2)))
    right := n % u64(math.pow10_f64(f64(n_len / 2)))

    val = count_expanded(left, remaining_blinks - 1, cache) +
          count_expanded(right, remaining_blinks - 1, cache)

    cache[Key{n, remaining_blinks}] = val

    return val
  }

  val = count_expanded(n * 2024, remaining_blinks - 1, cache)
  cache[Key{n, remaining_blinks}] = val

  return val
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  tokens := strings.split(s, " ")
  defer delete(tokens)

  numbers := slice.mapper(tokens[:], proc(s: string) -> u64 {
    val, _ := strconv.parse_u64(s)
    return val
  })

  defer delete(numbers)

  // Each number can be considered independently.
  cache := make(map[Key]u64)
  defer delete(cache)

  total1, total2: u64 = 0, 0
  for n in numbers {
    total1 += count_expanded(n, 25, &cache)
    total2 += count_expanded(n, 75, &cache)
  }

  fmt.println("P1:", total1, "P2:", total2)
}
