import std/tables
import spatial

type
  PlanKind* = enum
    pkExtendRod, pkRetractRod

  Plan* = ref object
    priority*: int
    case kind*: PlanKind
    of pkExtendRod:
      target*: Position
      chain*: OrderedTable[Position, Position]  # TODO: seq[(Position, Position)]
    of pkRetractRod:
      pistonPosition*: Position

func `$`*(plan: Plan): string =
  ## The method of bringing the plan to the line
  
  case plan.kind
  of pkExtendRod:
    "ExtendRodPlan(priority: " & $plan.priority &
    ", target: " & $plan.target &
    ", chain: " & $plan.chain & ")"
  of pkRetractRod:
    "RetractRodPlan(priority: " & $plan.priority &
    ", piston: " & $plan.pistonPosition & ")"

func newExtendRodPlan*(priority: int, target: Position, chain: OrderedTable[Position, Position]): Plan =
  Plan(kind: pkExtendRod, priority: priority, target: target, chain: chain)

func newRetractRodPlan*(pistonPosition: Position): Plan =
  Plan(kind: pkRetractRod, priority: 0, pistonPosition: pistonPosition)