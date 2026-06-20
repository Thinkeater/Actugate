import spatial

type
  CellKind* = enum
    ckNone, ckActivator, ckPiston, ckRod

  CellID* = int

  Cell* = object
    id*: CellID
    keep*: bool = true
    case kind*: CellKind
    of ckActivator, ckNone: discard
    of ckPiston:
      direction*: Direction
      priority*: int
      activated*: bool
      rod*: CellID
    of ckRod:
      pistonDirection*: Direction
      pistonPosition*: Position

const NoneCellID* = CellID(-1)
const NoneCell* = Cell(id: NoneCellID, keep: false)

func is_some*(cell: Cell): bool {.inline.} =
  cell.kind != ckNone

func is_some*(cell: CellID): bool {.inline.} =
  cell >= 0
  
func newActivator*(id: CellID, keep: bool = true): Cell = 
  Cell(id: id, kind: ckActivator, keep: keep)

func newPiston*(id: CellID, direction: Direction, priority: int = 0, activated: bool = false, rod: CellID = NoneCellID, keep: bool = true): Cell =
  Cell(id: id, kind: ckPiston, direction: direction, priority: priority, activated: activated, rod: rod, keep: keep)

func newRod*(id: CellID, pistonDirection: Direction, pistonPosition: Position, keep: bool = true): Cell =
  Cell(id: id, kind: ckRod, pistonDirection: pistonDirection, pistonPosition: pistonPosition, keep: keep)

func is_immovable*(cell: Cell): bool = 
  cell.kind == ckRod or (cell.kind == ckPiston and cell.activated)

func matches*(cell: Cell, other: Cell): bool =
  if cell.kind != other.kind or cell.keep != other.keep: return false
  
  case cell.kind
  of ckNone, ckActivator:
    return true
  of ckPiston:
    return cell.direction == other.direction and
           cell.priority == other.priority and
           cell.activated == other.activated and
           cell.rod.is_some == other.rod.is_some
  of ckRod:
    return cell.pistonDirection == other.pistonDirection and
           cell.pistonPosition == other.pistonPosition
