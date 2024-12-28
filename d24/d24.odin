package d24

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"

// Each wire either has a fixed value or has a value depending on a binary operation
// on two other wires.
Wire :: struct {
  name: string,
  id: int,
  input1, input2: Maybe(int),
  op: Maybe(string),
  val: Maybe(bool)
}

name_to_id :: proc(s: string) -> int {
  assert(len(s) == 3)
  return int(s[0]) << 16 + int(s[1]) << 8 + int(s[2])
}

// Recursively solve for the specified wire, reusing results where possible.
solve :: proc(id: int, wires: ^[]Wire, depth: int = 0) -> (bool, bool) {
  if depth > 100 do return false, true

  target := &wires[id]
  if target^.val != nil {
    return target^.val.?, false
  }

  assert(target^.input1 != nil && target^.input2 != nil && target^.op != nil)

  v1, has_cycle1 := solve(target^.input1.?, wires, depth + 1)
  if has_cycle1 do return false, true
  v2, has_cycle2 := solve(target^.input2.?, wires, depth + 1)
  if has_cycle2 do return false, true

  if target^.op.?[0] == 'O' {
    target^.val = v1 || v2
  }
  else if target^.op.?[0] == 'A' {
    target^.val = v1 && v2
  }
  else if target^.op.?[0] == 'X' {
    v1 ~= v2
    target^.val = v1
  }

  return target^.val.?, false
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  wires := make([]Wire, 1 << 25)
  defer delete(wires)

  parsing_initial_inputs := true
  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 {
      parsing_initial_inputs = false
      continue
    }

    if parsing_initial_inputs {
      // Create the wire and give it a value.
      name := line[0:3]
      val := line[5] == '1' ? true : false

      id := name_to_id(name)
      assert(wires[id].id == 0)
      wires[id] = Wire{name = name, id = id, val = val}
    }
    else {
      // Binary op.
      tokens := strings.split(line, " ")
      defer delete(tokens)

      input1 := tokens[0]
      input2 := tokens[2]
      op := tokens[1]
      output := tokens[4]

      id := name_to_id(output)
      assert(wires[id].id == 0)
      wires[id] = Wire{name = output, id = id, input1 = name_to_id(input1), input2 = name_to_id(input2), op = op}
    }
  }

  // Pick out the inputs and outputs to the adder.
  x_input := make([]^Wire, 45)
  defer delete(x_input)

  y_input := make([]^Wire, 45)
  defer delete(y_input)

  z_output := make([]^Wire, 46)
  defer delete(z_output)

  swappable := make([dynamic]^Wire)
  defer delete(swappable)

  for &w in wires {
    if w.id == 0 do continue
    if w.name[0] == 'x' {
      x_input[strconv.atoi(w.name[1:])] = &w
    }
    else if w.name[0] == 'y' {
      y_input[strconv.atoi(w.name[1:])] = &w
    }
    else {
      append(&swappable, &w)
      if w.name[0] == 'z' {
        z_output[strconv.atoi(w.name[1:])] = &w
      }
    }
  }

  get_output :: proc(output_wires: []^Wire, wires: ^[]Wire) -> (u64, bool) {
    out := u64(0)
    bit := u64(1)
    for w in output_wires {
      on, has_cycle := solve(w^.id, wires)
      if has_cycle do return 0, true
      if on {
        out |= bit
      }

      bit <<= 1
    }

    return out, false
  }

  fmt.println("P1:", get_output(z_output, &wires))

  clear_wires :: proc(wires: []^Wire) {
    for &w in wires do w.val = nil
  }

  write_value :: proc(val: u64, input_wires: []^Wire) {
    val := val
    bit_index := 0
    bit := u64(1)
    for bit_index < 45 {
      input_wires[bit_index].val = val & bit > 0
      bit_index += 1
      bit <<= 1
    }
  }

  bit_diff :: proc(a, b: u64) -> int {
    count := 0
    for i in 0..<64 {
      bit := u64(1) << u8(i)
      if (a & bit) != (b & bit) do count += 1
    }

    return count
  }

  // Swap the outputs from the wires
  swap :: proc(a, b: int, wires: []^Wire) {
    w1 := wires[a]
    w2 := wires[b]

    assert(w1^.input1 != nil && w1^.input2 != nil)
    assert(w2^.input1 != nil && w2^.input2 != nil)

    // Swap the input pairs.
    t1, t2, t3 := w1^.input1, w1^.input2, w1^.op
    w1^.input1 = w2^.input1
    w1^.input2 = w2^.input2
    w1^.op = w2^.op

    w2^.input1 = t1
    w2^.input2 = t2
    w2^.op = t3
  }

  swap_by_name :: proc(a, b: string, wires: []^Wire) {
    n1, n2: int
    for w, i in wires {
      if w^.name == a do n1 = i
      if w^.name == b do n2 = i
    }

    swap(n1, n2, wires)
  }

  // Errors:
  // nqk z07 4.854
  // srn z32 3.122
  // fpq z24 1.443
  // pcp fgt 0
  
  // P2: fgt,fpq,nqk,pcp,srn,z07,z24,z32

  swap_by_name("nqk", "z07", swappable[:])
  swap_by_name("srn", "z32", swappable[:])
  swap_by_name("fpq", "z24", swappable[:])
  swap_by_name("pcp", "fgt", swappable[:])

  lowest_error := 64.0
  for i in 0..<len(swappable) {
    for j in i + 1..<len(swappable) {
      swap(i, j, swappable[:])
      defer swap(i, j, swappable[:])

      // Collect stats for number of correct bits.
      av_bit_diff := 0.0
      N :: 100
      has_cycle := false
      for _ in 0..<N {
        v1 := rand.uint64() >> 21
        v2 := rand.uint64() >> 21
        res := v1 + v2

        clear_wires(swappable[:])

        write_value(v1, x_input)
        write_value(v2, y_input)

        out, has_cycle2 := get_output(z_output, &wires)
        if has_cycle2 {
          has_cycle = has_cycle2
          break
        }

        av_bit_diff += f64(bit_diff(out, res))
      }

      av_bit_diff /= N

      if !has_cycle && av_bit_diff < lowest_error {
        fmt.println(swappable[i]^.name, swappable[j]^.name, av_bit_diff)
        lowest_error = av_bit_diff
      }
    }
  }
}
