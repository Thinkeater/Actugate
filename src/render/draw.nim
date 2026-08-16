## Cell drawing

import ../data/cells
import ../data/spatial
import raylib
import atlas, sprites

const
  # HalfCell = sprites.Cell.float32 * 0.5  # xlebore3o4ka: закомментировал, потому что не используется
  DirAngles: array[Direction, float32] = [0, 90, 180, 270]  # RIGHT DOWN LEFT UP
  # CenterOrigin = Vector2(x: HalfCell, y: HalfCell)  # xlebore3o4ka: закомментировал, потому что не используется


proc drawRodTip*(spr: Sprites, dir: Direction,
                 wx, wy, ts: float32) =
  let tipDest = Rectangle(x: wx + ts * 0.5, y: wy + ts * 0.5,
                           width: ts, height: ts)
  let origin = Vector2(x: ts * 0.5, y: ts * 0.5)
  spr.atlas.draw(spr.rodTip, tipDest,
                 origin = origin,
                 rotation = DirAngles[dir])


proc drawRodBody*(spr: Sprites, dir: Direction,
                  wx, wy, ts: float32) =
  ## Draw the thin rod bar at pixel position (wx, wy).
  let bodyDest = Rectangle(x: wx, y: wy, width: ts, height: ts)
  if dir in {Direction.RIGHT, Direction.LEFT}:
    spr.atlas.draw(spr.rodBodyH, bodyDest)
  else:
    spr.atlas.draw(spr.rodBodyV, bodyDest)


proc drawPistonBody*(spr: Sprites, cell: Cell,
                     wx, wy: float32, tileSize: int) =
  ## Draw just the piston body (active or inactive) at pixel position.
  ## Does NOT draw rod tip or rod body -- those are handled separately.
  let ts = tileSize.float32
  let dest = Rectangle(x: wx, y: wy, width: ts, height: ts)
  if cell.activated:
    spr.atlas.draw(spr.pistonActive, dest)
  else:
    spr.atlas.draw(spr.pistonInactive, dest)


proc drawPiston*(spr: Sprites, cell: Cell, wx, wy: float32,
                 tileSize: int, rodT: float32) =
  ## Draw a complete piston with rod animation.
  ## `rodT` controls rod extension

  let ts = tileSize.float32
  let dir = cell.direction

  # Lerp
  let rx = wx + dir.dx.float32 * ts * rodT
  let ry = wy + dir.dy.float32 * ts * rodT

  # rod body only when extending
  if rodT > 0:
    spr.drawRodBody(dir, rx, ry, ts)

  # piston body
  spr.drawPistonBody(cell, wx, wy, tileSize)

  # rod tip
  spr.drawRodTip(dir, rx, ry, ts)

proc drawCell*(spr: Sprites, cell: Cell, pos: Position, tileSize: int) =
  let ts = tileSize.float32
  let wx = pos.x.float32 * ts
  let wy = pos.y.float32 * ts
  let dest = Rectangle(x: wx, y: wy, width: ts, height: ts)
  case cell.kind
  of ckNone, ckRod, ckStickyPiston: # @xlebore3o4ka TODO: отрисовка ckStickyPiston
    discard
  of ckActivator:
    spr.atlas.draw(spr.activator, dest)
  of ckPiston:
    spr.drawPiston(cell, wx, wy, tileSize, 0)

proc drawCellAt*(spr: Sprites, cell: Cell, wx, wy: float32, tileSize: int) =
  let ts = tileSize.float32
  let dest = Rectangle(x: wx, y: wy, width: ts, height: ts)
  case cell.kind
  of ckNone, ckRod, ckStickyPiston: # @xlebore3o4ka TODO: отрисовка ckStickyPiston
    discard
  of ckActivator:
    spr.atlas.draw(spr.activator, dest)
  of ckPiston:
    spr.drawPiston(cell, wx, wy, tileSize, 0)

proc drawCellScaled*(spr: Sprites, cell: Cell, pos: Position,
                     tileSize: int, scale: float32) =
  if scale <= 0: return
  let ts = tileSize.float32
  let s = ts * scale
  let cx = pos.x.float32 * ts + (ts - s) * 0.5
  let cy = pos.y.float32 * ts + (ts - s) * 0.5
  let dest = Rectangle(x: cx, y: cy, width: s, height: s)
  case cell.kind
  of ckNone, ckRod, ckStickyPiston: # @xlebore3o4ka TODO: отрисовка ckStickyPiston
    discard
  of ckActivator:
    spr.atlas.draw(spr.activator, dest)
  of ckPiston:
    if cell.activated:
      spr.atlas.draw(spr.pistonActive, dest)
    else:
      spr.atlas.draw(spr.pistonInactive, dest)
