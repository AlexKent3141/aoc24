package d17

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

Machine :: struct {
  registers: [3]u64,
  i: int
}

reset_machine :: proc(machine: ^Machine, a_register: u64) {
  machine.registers[0] = a_register
  machine.registers[1] = 0
  machine.registers[2] = 0
  machine.i = 0
}

eval_combo_operand :: proc(registers: [3]u64, arg: int) -> u64 {
  assert(arg >= 0 && arg < 8)
  assert(arg != 7)
  if arg < 4 do return u64(arg)
  return registers[arg - 4]
}

cycle :: proc(machine: ^Machine, instructions: []int) -> (out: Maybe(int), halted: bool) {
  op := instructions[machine.i]
  arg := instructions[machine.i + 1]

  switch op {
    case 0: // Division
      res := machine.registers[0]
      operand := eval_combo_operand(machine.registers, arg)
      for _ in 0..<operand do res >>= 1
      machine.registers[0] = res
      machine.i += 2
    case 1: // XOR
      machine.registers[1] ~= u64(arg)
      machine.i += 2
    case 2:  // bst
      machine.registers[1] = eval_combo_operand(machine.registers, arg) % 8
      machine.i += 2
    case 3: // jnz
      if machine.registers[0] != 0 {
        machine.i = arg
      }
      else {
        machine.i += 2
      }
    case 4: // bxc
      machine.registers[1] ~= machine.registers[2]
      machine.i += 2
    case 5: // out
      out = int(eval_combo_operand(machine.registers, arg) % 8)
      machine.i += 2
    case 6: // bdv
      res := machine.registers[0]
      operand := eval_combo_operand(machine.registers, arg)
      for _ in 0..<operand do res >>= 1
      machine.registers[1] = res
      machine.i += 2
    case 7: // cdv
      res := machine.registers[0]
      operand := eval_combo_operand(machine.registers, arg)
      for _ in 0..<operand do res >>= 1
      machine.registers[2] = res
      machine.i += 2
  }

  halted = machine.i >= len(instructions)

  return out, halted
}

run :: proc(machine: ^Machine, instructions: []int, output: ^[dynamic]int, target: bool) -> bool {
  out: Maybe(int)
  out_index := 0
  halted := false
  for !halted {
    out, halted = cycle(machine, instructions)
    if out != nil {
      if target && out.? != instructions[out_index] do return false
      out_index += 1
      append(output, out.?)
    }
  }

  if target && len(output) != len(instructions) do return false

  return true
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)
  s := string(data)

  machine := Machine{}

  instructions := make([dynamic]int)
  defer delete(instructions)

  for line in strings.split_lines_iterator(&s) {
    if len(line) == 0 do continue

    tokens := strings.split(line, ": ")
    defer delete(tokens)

    if tokens[0] == "Register A" do machine.registers[0] = u64(strconv.atoi(tokens[1]))
    else if tokens[0] == "Register B" do machine.registers[1] = u64(strconv.atoi(tokens[1]))
    else if tokens[0] == "Register C" do machine.registers[2] = u64(strconv.atoi(tokens[1]))
    else {
      instruction_strs := strings.split(tokens[1], ",")
      defer delete(instruction_strs)

      for instruction in instruction_strs do append(&instructions, strconv.atoi(instruction))
    }
  }

  output := make([dynamic]int)
  defer delete(output)

  run(&machine, instructions[:], &output, false)
  fmt.println(output) // P1

  // Somewhat manual search approach:
  // 1. Pick a range for the solution
  // 2. Run Monte Carlo simulations within that range to find the most promising area
  // 3. Narrow the range around that area
  // Samples are assessed by counting how many of the trailing digits are correct.

  min := u64(100000000000000)
  max := u64(110000000000000)

  best_val := max
  best_digit := 100
  for {
    current := rand.uint64() % (max - min)
    current += min

    reset_machine(&machine, current)
    clear(&output)

    run(&machine, instructions[:], &output, false)

    // How similar?
    if len(output) == len(instructions) {
      matching_digit_index := len(output) - 1
      for matching_digit_index >= 0 &&
          slice.equal(output[matching_digit_index:], instructions[matching_digit_index:]) {
        matching_digit_index -= 1
      }

      matching_digit_index += 1

      if matching_digit_index < best_digit ||
         (matching_digit_index == best_digit) && current < best_val {
        fmt.println(current, output, matching_digit_index)
        best_digit = matching_digit_index
        best_val = current
      }
    }
  }
}
