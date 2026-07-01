## Sprite definitions

import raylib
import atlas, colors

const
  Cell* = 32.int32
  Border* = 4.int32

  InnerOffset = Border * 2              # 8
  InnerSizeOffset = Border * 4          # 16
  RodThickness = 4.int32
  RodTipThickness = 4.int32
  RodTipLength = Cell - RodTipThickness * 2  # 24
  RodOffset = (Cell - RodThickness) div 2    # 14
  TipOffset = Cell - RodTipThickness         # 28
  HalfCell = Cell div 2                      # 16

type
  Sprites* = object
    atlas*: Atlas
    activator*: SpriteID
    pistonActive*: SpriteID
    pistonInactive*: SpriteID
    rodTip*: SpriteID               ## Rod tip (RIGHT)
    rodBodyH*: SpriteID             ## Thin horizontal bar (full width)
    rodBodyV*: SpriteID             ## Thin vertical bar (full height)
    priorityUp*: SpriteID           ## Arrow up
    priorityDown*: SpriteID         ## Arrow down

proc initSprites*(): Sprites =
  ## Build the sprite atlas.
  ## Call this after `initWindow`.

  result.atlas = initAtlas(256, 128)
  result.atlas.beginBuild()

  # ---- Activator ----
  result.activator = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.activator)
    drawRectangle(ox, oy, Cell, Cell, Active)
    drawRectangle(ox + Border, oy + Border,
                  Cell - InnerOffset, Cell - InnerOffset,
                  colorBrightness(Active, -0.3))
    drawRectangle(ox + InnerOffset, oy + InnerOffset,
                  Cell - InnerSizeOffset, Cell - InnerSizeOffset, Active)

  # ---- Piston Active ----
  result.pistonActive = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.pistonActive)
    drawRectangle(ox, oy, Cell, Cell, Piston)
    drawRectangle(ox + Border, oy + Border,
                  Cell - InnerOffset, Cell - InnerOffset,
                  colorBrightness(Piston, -0.3))
    drawRectangle(ox + InnerOffset, oy + InnerOffset,
                  Cell - InnerSizeOffset, Cell - InnerSizeOffset, Active)

  # ---- Piston Inactive ----
  result.pistonInactive = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.pistonInactive)
    drawRectangle(ox, oy, Cell, Cell, Piston)
    drawRectangle(ox + Border, oy + Border,
                  Cell - InnerOffset, Cell - InnerOffset,
                  colorBrightness(Piston, -0.3))
    drawRectangle(ox + InnerOffset, oy + InnerOffset,
                  Cell - InnerSizeOffset, Cell - InnerSizeOffset, Inactive)

  # ---- Rod Tip (RIGHT) ----
  result.rodTip = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.rodTip)
    drawRectangle(ox + TipOffset, oy + Border,
                  RodTipThickness, RodTipLength, Rod)

  # ---- Rod Body H ----
  result.rodBodyH = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.rodBodyH)
    drawRectangle(ox, oy + RodOffset, Cell, RodThickness,
                  colorBrightness(Rod, -0.3))

  # ---- Rod Body V ----
  result.rodBodyV = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.rodBodyV)
    drawRectangle(ox + RodOffset, oy, RodThickness, Cell,
                  colorBrightness(Rod, -0.3))

  # ---- Arrow Down ----
  result.priorityDown = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.priorityDown)
    let p = HalfCell
    drawRectangle(ox + p - p div 4, oy, p div 2, p, White)
    drawTriangle(
      Vector2(x: (ox + p * 2).float32, y: p.float32 + oy.float32),
      Vector2(x: (ox).float32,         y: p.float32 + oy.float32),
      Vector2(x: (ox + p).float32,     y: (oy + Cell).float32),
      White)

  # ---- Arrow Up ----
  result.priorityUp = result.atlas.reserve(Cell, Cell)
  block:
    let (ox, oy) = result.atlas.offset(result.priorityUp)
    let p = HalfCell
    drawTriangle(
      Vector2(x: (ox).float32,         y: p.float32 + oy.float32),
      Vector2(x: (ox + p * 2).float32, y: p.float32 + oy.float32),
      Vector2(x: (ox + p).float32,     y: oy.float32),
      White)
    drawRectangle(ox + p - p div 4, oy + p, p div 2, p, White)

  result.atlas.endBuild()

proc destroy*(sprites: var Sprites) =
  sprites.atlas.destroy()
