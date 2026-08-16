## Animation system

import ../core/core
import ../data/[cells, spatial, plans]
import std/[tables, sets]
import draw, sprites

type
  RodAnim* = enum
    raNone,         ## No rod
    raStatic,       ## Rod already extended
    raExtending,    ## Rod extending this tick
    raRetracting,   ## Rod retracting this tick

  AnimKind* = enum
    akStatic,       ## Cell stays in place
    akMove,         ## Cell moves from fromPos to pos
    akAppear,       ## Cell appears
    akDisappear,    ## Cell disappears
    akPiston,       ## Piston with rod animation state

  AnimState* = object
    cell*: Cell
    pos*: Position
    case kind*: AnimKind
    of akStatic, akAppear, akDisappear:
      discard
    of akMove:
      fromPos*: Position
    of akPiston:
      rodAnim*: RodAnim

  AnimFrame* = object
    items*: seq[AnimState]

# Easing functions

func easeOutCubic*(t: float32): float32 {.inline.} =
  let t1 = 1.0f - t
  1.0f - t1 * t1 * t1

# Animation building

proc initFromWorld*(frame: var AnimFrame, world: World) =
  ## Build a static frame from the current world (without animations).

  frame.items.setLen(0)
  for pos, cell in world.current:
    if not cell.is_some: continue
    case cell.kind
    of ckRod:
      discard  # rods are drawn by their piston
    of ckPiston:
      let ra = if cell.activated and cell.rod.is_some: raStatic else: raNone
      frame.items.add(AnimState(cell: cell, kind: akPiston, pos: pos,
                                rodAnim: ra))
    else:
      frame.items.add(AnimState(cell: cell, kind: akStatic, pos: pos))

proc buildFromPlans*(frame: var AnimFrame, world: World) =
  ## Build an animation frame from resolved plans.

  frame.items.setLen(0)
  var handled: HashSet[Position]
  # Positions of pistons that retract (filled from RetractRod plans)
  var retractingPistons: HashSet[Position]

  for planPos, plan in world.plans:
    if plan.kind == pkRetractRod:
      handled.incl(planPos)
      retractingPistons.incl(plan.pistonPosition)

  for planPos, plan in world.plans:
    if plan.kind != pkExtendRod: continue

    handled.incl(planPos)
    frame.items.add(AnimState(
      cell: world.get(planPos), kind: akPiston, pos: planPos,
      rodAnim: raExtending))

    for (fromPos, toPos) in plan.chain:
      handled.incl(fromPos)
      frame.items.add(AnimState(
        cell: world.get(fromPos), kind: akMove,
        pos: toPos, fromPos: fromPos))

  for pos, cell in world.current:
    if not cell.is_some: continue
    if pos in handled: continue

    case cell.kind
    of ckRod:
      discard

    of ckPiston:
      if pos in retractingPistons:
        frame.items.add(AnimState(
          cell: cell, kind: akPiston, pos: pos,
          rodAnim: raRetracting))
      elif cell.activated and cell.rod.is_some:
        frame.items.add(AnimState(
          cell: cell, kind: akPiston, pos: pos,
          rodAnim: raStatic))
      else:
        frame.items.add(AnimState(
          cell: cell, kind: akPiston, pos: pos,
          rodAnim: raNone))

    else:
      if not cell.keep:
        frame.items.add(AnimState(
          cell: cell, kind: akDisappear, pos: pos))
      else:
        frame.items.add(AnimState(
          cell: cell, kind: akStatic, pos: pos))

# Drawing

proc draw*(frame: AnimFrame, spr: Sprites, tileSize: int, t: float32) =
  ## Draw all animated cells. `t` is tick progress in `0.0..1.0`.
  let eased = easeOutCubic(t)

  for anim in frame.items:
    case anim.kind
    of akStatic:
      spr.drawCell(anim.cell, anim.pos, tileSize)

    of akMove:
      let ts = tileSize.float32
      let ox = anim.fromPos.x.float32 * ts
      let oy = anim.fromPos.y.float32 * ts
      let nx = anim.pos.x.float32 * ts
      let ny = anim.pos.y.float32 * ts
      let x = ox + (nx - ox) * eased
      let y = oy + (ny - oy) * eased
      spr.drawCellAt(anim.cell, x, y, tileSize)

    of akAppear:
      spr.drawCellScaled(anim.cell, anim.pos, tileSize, eased)

    of akDisappear:
      spr.drawCellScaled(anim.cell, anim.pos, tileSize, 1.0f - eased)

    of akPiston:
      let ts = tileSize.float32
      let wx = anim.pos.x.float32 * ts
      let wy = anim.pos.y.float32 * ts
      let rodT = case anim.rodAnim
        of raNone:       0.0f
        of raStatic:     1.0f
        of raExtending:  eased
        of raRetracting: 1.0f - eased
      spr.drawPiston(anim.cell, wx, wy, tileSize, rodT)
