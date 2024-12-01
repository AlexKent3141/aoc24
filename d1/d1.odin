package d1

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:sort"
import "core:strconv"
import "core:strings"

main :: proc() {

  N :: 1000

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  left, right := [N]int{}, [N]int{}
  index := 0
  for line in strings.split_lines_iterator(&s) {
    ids := strings.split(line, "   ")
    defer delete(ids)

    left[index] = strconv.atoi(ids[0])
    right[index] = strconv.atoi(ids[1])
    index += 1
  }

  sort.quick_sort(left[:])
  sort.quick_sort(right[:])

  total1, total2 := 0, 0
  for i in 0..<N {
    total1 += math.abs(left[i] - right[i])
    total2 += left[i] * slice.count(right[:], left[i])
  }

  fmt.println("P1:", total1, "P2:", total2)
}
