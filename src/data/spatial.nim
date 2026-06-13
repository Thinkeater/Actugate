type 
  Direction* = enum RIGHT, DOWN, LEFT, UP
  Position* = tuple[x, y: int]

func newPos*(x: int, y: int): Position {.inline.} = (x: x, y: y)

const 
  dx_table: array[Direction, int] = [1, 0, -1, 0]
  dy_table: array[Direction, int] = [0, 1, 0, -1]
  angle_table: array[Direction, int] = [0, 90, 180, 270]

func dx*(d: Direction): int {.inline.} = dx_table[d]
func dy*(d: Direction): int {.inline.} = dy_table[d]
func angle*(d: Direction): int {.inline.} = angle_table[d]
func apply*(d: Direction, p: Position): Position {.inline.} = newPos(p.x + d.dx, p.y + d.dy)
