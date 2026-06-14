import spatial
import std/options

type
  CellKind* = enum
    ckNull, ckActivator, ckPiston, ckRod

  CellId* = int

  Cell* = object
    id*: CellId
    keep*: bool = true
    case kind*: CellKind
    of ckActivator, ckNull: discard
    of ckPiston:
      direction*: Direction
      priority*: int
      activated*: bool
      rod*: Option[CellId] = none(CellId)
    of ckRod:
      pistonDirection*: Direction
      pistonPosition*: Position

const NullCell* = Cell(id: -1, kind: ckNull, keep: false)

func newActivator*(id: CellId): Cell = 
  Cell(id: id, kind: ckActivator)

func newPiston*(id: CellId, direction: Direction, priority: int = 0, activated: bool = false): Cell =
  Cell(id: id, kind: ckPiston, direction: direction, priority: priority, activated: activated)

func newRod*(id: CellId, pistonDirection: Direction, pistonPosition: Position): Cell =
  Cell(id: id, kind: ckRod, pistonDirection: pistonDirection, pistonPosition: pistonPosition)

func is_immovable*(cell: Cell): bool = 
  cell.kind == ckRod or (cell.kind == ckPiston and cell.activated)