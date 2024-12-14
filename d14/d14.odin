package d14

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

W :: 101
H :: 103

Robot :: struct {
  x, y, vx, vy: int
}

// Get quadrant 0..<4 (or nil).
get_quadrant :: proc(x, y: int) -> Maybe(int) {
  if x < W / 2 && y < H / 2 do return 0
  if x > W / 2 && y < H / 2 do return 1
  if x < W / 2 && y > H / 2 do return 2
  if x > W / 2 && y > H / 2 do return 3
  return nil
}

pos_after_steps :: proc(r: Robot, steps: int) -> (x, y: int) {
  next_x := (r.x + steps * r.vx) % W
  if next_x < 0 do next_x += W
  next_y := (r.y + steps * r.vy) % H
  if next_y < 0 do next_y += H
  return next_x, next_y
}

step_robot :: proc(r: ^Robot) {
  next_x, next_y := pos_after_steps(r^, 1)
  r^.x = next_x
  r^.y = next_y
}

show_grid :: proc(robots: []Robot) {
  rows := [H][W]u8{}
  for &r in rows do slice.fill(r[:], '.')
  for r in robots do rows[r.y][r.x] = 'X'
  for &r in rows do fmt.println(string(r[:]))
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  robots := make([dynamic]Robot)
  defer delete(robots)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")
    defer delete(tokens)

    pos := tokens[0]
    vel := tokens[1]

    pos_tokens := strings.split(pos, ",")
    defer delete(pos_tokens)

    x := strconv.atoi(pos_tokens[0][2:])
    y := strconv.atoi(pos_tokens[1])

    vel_tokens := strings.split(vel, ",")
    defer delete(vel_tokens)

    vx := strconv.atoi(vel_tokens[0][2:])
    vy := strconv.atoi(vel_tokens[1])

    append(&robots, Robot { x, y, vx, vy })
  }

  quadrant_counts := [4]int{}
  for r in robots {
    pos_x, pos_y := pos_after_steps(r, 100)
    q := get_quadrant(pos_x, pos_y)
    if q != nil do quadrant_counts[q.?] += 1
  }

  p1 := slice.reduce(quadrant_counts[:], 1, proc(a, b: int) -> int { return a * b })

  // P2 requires some visual inspection to make sure.
  // Given the emphasis of P1, it makes sense to use the quadrant totals to identify
  // candidates for the Christmas tree image.
  // Assumption: the pattern causes the image's quadrant totals to become unbalanced i.e.
  // we want maximise the difference between quadrant totals.
  best_step, biggest_diff := 0, 0
  step := 0
  for _ in 0..<W*H {
    slice.fill(quadrant_counts[:], 0)
    step += 1
    for &r in robots {
      step_robot(&r)

      q := get_quadrant(r.x, r.y)
      if q != nil do quadrant_counts[q.?] += 1
    }

    diff := slice.max(quadrant_counts[:]) - slice.min(quadrant_counts[:])
    if diff > biggest_diff {
      biggest_diff = diff
      best_step = step
      fmt.println("Step:", step, "Diff:", diff)
    //show_grid(robots[:])
    }
  }

  fmt.println("P1:", p1, "P2 (probably):", best_step)
}
