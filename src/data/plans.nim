import std/tables
import spatial

type
  PlanKind* = enum
    pkExtendRod

  Plan* = ref object
    priority*: int
    case kind*: PlanKind
    of pkExtendRod:
      target*: Position
      chain*: Table[Position, Position]

func `$`*(plan: Plan): string =
  ## The method of bringing the plan to the line
  
  case plan.kind
  of pkExtendRod:
    "Plan(kind: pkExtendRod, priority: " & $plan.priority &
    ", target: " & $plan.target &
    ", chain: " & $plan.chain & ")"

func newExtendRodPlan*(priority: int, target: Position, chain: Table[Position, Position]): Plan =
  Plan(kind: pkExtendRod, priority: priority, target: target, chain: chain)