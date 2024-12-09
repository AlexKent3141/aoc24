package d9

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"

find_back_block :: proc(disk: []int, back_index: int) -> (block_start, block_length: int, found: bool) {
  back_index := back_index

  // Skip zeroes.
  for back_index >= 0 && disk[back_index] == 0 {
    back_index -= 1
  }

  if back_index < 0 do return -1, -1, false

  value := disk[back_index]
  length := 0
  for back_index >= 0 && disk[back_index] == value {
    length += 1
    back_index -= 1
  }

  return back_index + 1, length, true
}

earliest_container_block :: proc(disk: []int, block_start, block_length: int) -> (zero_block_start: int, found: bool) {

  // Find the earliest block of zeroes long enough to contain this target.
  zero_block_length := 0
  for i in 0..<block_start {
    if disk[i] == 0 {
      zero_block_length += 1

      // Is this block sufficient?
      if zero_block_length >= block_length {
        return i - block_length + 1, true
      }
    }
    else {
      zero_block_length = 0
    }
  }

  return -1, false
}

checksum :: proc(disk: []int) -> u64 {
  total := u64(0)
  for b, index in disk {
    if b != 0 {
      total += u64((b - 1) * index)
    }
  }

  return total
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  data = data[:len(data)-1]

  // First calc how much memory we need for the expanded string.
  required_size := 0
  for b in data do required_size += int(b - '0')

  // Expand the compressed data into a full disk.
  disk1 := make([]int, required_size)
  defer delete(disk1)
  disk2 := make([]int, required_size)
  defer delete(disk2)

  loc := 0
  id := 1 // Start from 1 do we can distinguish from the 0 "background".
  for b, index in data {
    if index % 2 == 0 {
      slice.fill(disk1[loc:loc + int(b) - 48], id)
      id += 1
    }

    loc += int(b) - 48
  }

  runtime.copy(disk2[:], disk1[:])

  // Now "fragment" for P1.
  current_index := len(disk1) - 1
  next_empty_index, found := slice.linear_search(disk1[:], 0)
  for found && next_empty_index < current_index {
    if disk1[current_index] == 0 {
      current_index -= 1
      continue
    }

    // Move this guy to the next zero loc.
    disk1[next_empty_index] = disk1[current_index]
    disk1[current_index] = 0
    current_index -= 1

    prev_empty_index := next_empty_index
    next_empty_index, found = slice.linear_search(disk1[(next_empty_index + 1):], 0)
    next_empty_index += (prev_empty_index + 1)
  }

  // Let's not do anything fancy for P2.
  earliest_for_length := [10]int{}
  block_start, block_length, found2 := find_back_block(disk2, len(disk1) - 1)
  for found2 {
    // Find the earliest zero block which will fit this one.
    earliest_start := earliest_for_length[block_length]
    zero_block, found_zero_block := earliest_container_block(
      disk2[earliest_start:],
      block_start - earliest_start,
      block_length)


    zero_block += earliest_start

    // If we managed to move it then zero this block.
    if found_zero_block {
      runtime.copy(disk2[zero_block:], disk2[block_start:block_start + block_length])
      slice.zero(disk2[block_start:block_start + block_length])
    }

    earliest_for_length[block_length] = zero_block + block_length

    // Step to the next block.
    back_index := block_start - 1
    block_start, block_length, found2 = find_back_block(disk2, back_index)
  }

  fmt.println("P1:", checksum(disk1), "P2:", checksum(disk2))
}
