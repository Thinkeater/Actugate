import spatial

type
  CellKind* = enum
    ckActivator, ckPiston, ckRod

  Cell* = object
    keep*: bool = true
    case kind*: CellKind
    of ckActivator: discard
    of ckPiston:
      direction*: Direction
      priority*: int
      activated*: bool
    of ckRod:
      pistonDirection*: Direction
      pistonPosition*: Position

func newActivator*(): Cell = Cell(kind: ckActivator)

func newPiston*(direction: Direction, priority: int = 0, activated: bool = false): Cell =
  Cell(kind: ckPiston, direction: direction, priority: priority, activated: activated)

func newRod*(pistonDirection: Direction, pistonPosition: Position): Cell =
  Cell(kind: ckRod, pistonDirection: pistonDirection, pistonPosition: pistonPosition)

func is_immovable*(cell: Cell): bool = 
  cell.kind == ckRod or (cell.kind == ckPiston and cell.activated)