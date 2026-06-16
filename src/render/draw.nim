import ../data/cells
import ../data/spatial
import raylib
import colors

proc drawCell*(cell: Cell, pos: Position, tileSize: int) =
  let ts: int32 = tileSize.int32
  let wx = pos.x.int32 * ts
  let wy = pos.y.int32 * ts
  const i: int32 = 4

  case cell.kind
  of ckActivator:
    drawRectangle(wx, wy, ts, ts, Active)
    drawRectangle(wx + i, wy + i, ts - i*2, ts - i*2, Active.colorBrightness(-0.3))
    drawRectangle(wx + i*2, wy + i*2, ts - i*4, ts - i*4, Active)

  of ckNone:
    discard

  of ckPiston:
    drawRectangle(wx, wy, ts, ts, Piston)
    drawRectangle(wx + i, wy + i, ts - i*2, ts - i*2, Piston.colorBrightness(-0.3))
    if cell.activated:
      drawRectangle(wx + i*2, wy + i*2, ts - i*4, ts - i*4, Active)
    else:
      drawRectangle(wx + i*2, wy + i*2, ts - i*4, ts - i*4, Inactive)
      case cell.direction
      of RIGHT:
        drawRectangle(wx + 28, wy + 4, 4, 24, Rod)
      of LEFT:
        drawRectangle(wx, wy + 4, 4, 24, Rod)
      of UP:
        drawRectangle(wx + 4, wy, 24, 4, Rod)
      of DOWN:
        drawRectangle(wx + 4, wy + 28, 24, 4, Rod)

  of ckRod:
    case cell.pistonDirection
    of RIGHT:
      drawRectangle(wx, wy + 12, ts, 8, Rod.colorBrightness(-0.3))
      drawRectangle(wx + 28, wy + 4, 4, 24, Rod)
    of LEFT:
      drawRectangle(wx, wy + 12, ts, 8, Rod.colorBrightness(-0.3))
      drawRectangle(wx, wy + 4, 4, 24, Rod)
    of UP:
      drawRectangle(wx + 12, wy, 8, ts, Rod.colorBrightness(-0.3))
      drawRectangle(wx + 4, wy, 24, 4, Rod)
    of DOWN:
      drawRectangle(wx + 12, wy, 8, ts, Rod.colorBrightness(-0.3))
      drawRectangle(wx + 4, wy + 28, 24, 4, Rod)
