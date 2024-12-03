package d3

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

State :: enum {
  DO,
  DONT
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  total1, total2 := 0, 0

  state := State.DO

  for i in 0..<len(s) {
    // Does this match any of the special strings?
    if i < len(s) - 3 && s[i:i+4] == "mul(" {
      // Need to do some parsing.
      tokens := strings.split(s[i+4:], ",")
      defer delete(tokens)
      a, ok := strconv.parse_int(tokens[0])
      if ok {
        // Got the first operand.
        tokens2 := strings.split(tokens[1], ")")
        defer delete(tokens2)

        b, ok2 := strconv.parse_int(tokens2[0])
        if ok2 {
          total1 += a * b
          if state == State.DO do total2 += a * b
        }
      }
    }

    if i < len(s) - 3 && s[i:i+4] == "do()" do state = State.DO
    if i < len(s) - 6 && s[i:i+7] == "don't()" do state = State.DONT
  }
  fmt.println("P1:", total1, "P2:", total2)
}
