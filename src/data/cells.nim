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

func newActivator*(id: CellID): Cell = 
  Cell(id: id, kind: ckActivator)

func newPiston*(id: CellID, direction: Direction, priority: int = 0, activated: bool = false): Cell =
  Cell(id: id, kind: ckPiston, direction: direction, priority: priority, activated: activated, rod: NoneCellID)

func newRod*(id: CellID, pistonDirection: Direction, pistonPosition: Position): Cell =
  Cell(id: id, kind: ckRod, pistonDirection: pistonDirection, pistonPosition: pistonPosition)

func is_immovable*(cell: Cell): bool = 
  cell.kind == ckRod or (cell.kind == ckPiston and cell.activated)