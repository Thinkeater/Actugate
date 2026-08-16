import spatial

type
  PlanKind* = enum
    pkExtendRod, pkRetractRod, pkStickyRetractRod

  Plan* = ref object
    priority*: int
    case kind*: PlanKind
    of pkExtendRod:
      target*: Position
      chain*: seq[(Position, Position)]
    of pkRetractRod, pkStickyRetractRod:
      pistonPosition*: Position
      stuckTarget*: Position

func `$`*(plan: Plan): string =
  case plan.kind
  of pkExtendRod:
    "ExtendRodPlan(priority: " & $plan.priority &
    ", target: " & $plan.target &
    ", chain: " & $plan.chain & ")"
  of pkRetractRod:
    "RetractRodPlan(priority: " & $plan.priority &
    ", piston: " & $plan.pistonPosition & ")"
  of pkStickyRetractRod:
    "StickyRetractRodPlan(priority: " & $plan.priority &
    ", piston: " & $plan.pistonPosition &
    ", stuckTarget: " & $plan.stuckTarget & ")"

func newExtendRodPlan*(priority: int, target: Position, chain: seq[(Position, Position)]): Plan =
  Plan(kind: pkExtendRod, priority: priority, target: target, chain: chain)

func newRetractRodPlan*(pistonPosition: Position): Plan =
  Plan(kind: pkRetractRod, priority: 0, pistonPosition: pistonPosition)

func newStickyRetractRodPlan*(priority: int, pistonPosition: Position, stuckTarget: Position): Plan =
  Plan(kind: pkStickyRetractRod, priority: priority, pistonPosition: pistonPosition, stuckTarget: stuckTarget)