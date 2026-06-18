import ../data/cells
import ../data/spatial
import raylib
import colors

const
  CELL_SIZE = 32

  BORDER_SIZE = 4
  ROD_THICKNESS = 4
  ROD_TIP_THICKNESS = 4

  INNER_OFFSET = BORDER_SIZE * 2
  INNER_SIZE_OFFSET = BORDER_SIZE * 4
  ROD_TIP_LENGTH = CELL_SIZE - ROD_TIP_THICKNESS * 2
  ROD_OFFSET = (CELL_SIZE - ROD_THICKNESS) div 2
  TIP_OFFSET = CELL_SIZE - ROD_TIP_THICKNESS

proc drawCell*(cell: Cell, pos: Position, tileSize: int) =
  let ts: int32 = tileSize.int32
  let wx = pos.x.int32 * ts
  let wy = pos.y.int32 * ts

  case cell.kind
  of ckActivator:
    drawRectangle(wx, wy, ts, ts, Active)
    drawRectangle(wx + BORDER_SIZE, wy + BORDER_SIZE, ts - INNER_OFFSET, ts - INNER_OFFSET, Active.colorBrightness(-0.3))
    drawRectangle(wx + INNER_OFFSET, wy + INNER_OFFSET, ts - INNER_SIZE_OFFSET, ts - INNER_SIZE_OFFSET, Active)

  of ckNone:
    discard

  of ckPiston:
    drawRectangle(wx, wy, ts, ts, Piston)
    drawRectangle(wx + BORDER_SIZE, wy + BORDER_SIZE, ts - INNER_OFFSET, ts - INNER_OFFSET, Piston.colorBrightness(-0.3))
    if cell.activated:
      drawRectangle(wx + INNER_OFFSET, wy + INNER_OFFSET, ts - INNER_SIZE_OFFSET, ts - INNER_SIZE_OFFSET, Active)
    else:
      drawRectangle(wx + INNER_OFFSET, wy + INNER_OFFSET, ts - INNER_SIZE_OFFSET, ts - INNER_SIZE_OFFSET, Inactive)
      case cell.direction
      of RIGHT:
        drawRectangle(wx + TIP_OFFSET, wy + BORDER_SIZE, ROD_TIP_THICKNESS, ROD_TIP_LENGTH, Rod)
      of LEFT:
        drawRectangle(wx, wy + BORDER_SIZE, ROD_TIP_THICKNESS, ROD_TIP_LENGTH, Rod)
      of UP:
        drawRectangle(wx + BORDER_SIZE, wy, ROD_TIP_LENGTH, ROD_TIP_THICKNESS, Rod)
      of DOWN:
        drawRectangle(wx + BORDER_SIZE, wy + TIP_OFFSET, ROD_TIP_LENGTH, ROD_TIP_THICKNESS, Rod)

  of ckRod:
    case cell.pistonDirection
    of RIGHT:
      drawRectangle(wx, wy + ROD_OFFSET, ts, ROD_THICKNESS, Rod.colorBrightness(-0.3))
      drawRectangle(wx + TIP_OFFSET, wy + BORDER_SIZE, ROD_TIP_THICKNESS, ROD_TIP_LENGTH, Rod)
    of LEFT:
      drawRectangle(wx, wy + ROD_OFFSET, ts, ROD_THICKNESS, Rod.colorBrightness(-0.3))
      drawRectangle(wx, wy + BORDER_SIZE, ROD_TIP_THICKNESS, ROD_TIP_LENGTH, Rod)
    of UP:
      drawRectangle(wx + ROD_OFFSET, wy, ROD_THICKNESS, ts, Rod.colorBrightness(-0.3))
      drawRectangle(wx + BORDER_SIZE, wy, ROD_TIP_LENGTH, ROD_TIP_THICKNESS, Rod)
    of DOWN:
      drawRectangle(wx + ROD_OFFSET, wy, ROD_THICKNESS, ts, Rod.colorBrightness(-0.3))
      drawRectangle(wx + BORDER_SIZE, wy + TIP_OFFSET, ROD_TIP_LENGTH, ROD_TIP_THICKNESS, Rod)
