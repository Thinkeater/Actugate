import std/tables
import spatial

type
  PlanKind* = enum
    pkExtendRod

  Plan* = object
    priority*: int
    case kind*: PlanKind
    of pkExtendRod:
      target*: Position
      chain*: Table[Position, Position]

func newExtendRodPlan*(priority: int, target: Position, chain: Table[Position, Position]): Plan =
  Plan(kind: pkExtendRod, priority: priority, target: target, chain: chain)