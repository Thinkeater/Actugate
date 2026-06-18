import raylib, types, math, colors

const
  MinScreenSpacing = 30.0       ## Min pixels between grid lines before skip
  GridMajorColor = newColor(75, 75, 75, 255)
  GridMinorColor = newColor(50, 50, 50, 255)
  MajorEvery = 4                ## Every Nth line is brighter

proc drawGrid*(rend: Renderer) =
  let cam = rend.camCtrl.camera
  let sw = getScreenWidth().int32
  let sh = getScreenHeight().int32
  let ts = rend.config.tileSize.float

  let rawScreenSpacing = ts * cam.zoom
  let mult = max(1, (MinScreenSpacing / rawScreenSpacing).ceil()).int
  let step = ts * mult.float

  # Viewport corners in world space
  let worldX0 = -cam.offset.x.float / cam.zoom + cam.target.x.float
  let worldY0 = -cam.offset.y.float / cam.zoom + cam.target.y.float
  let worldX1 = (sw.float - cam.offset.x.float) / cam.zoom + cam.target.x.float
  let worldY1 = (sh.float - cam.offset.y.float) / cam.zoom + cam.target.y.float

  let i0 = floor(worldX0 / step).int
  let i1 = ceil(worldX1 / step).int
  let j0 = floor(worldY0 / step).int
  let j1 = ceil(worldY1 / step).int

  for i in i0 .. i1:
    let wx = i.float * step
    let sx = ((wx - cam.target.x.float) * cam.zoom + cam.offset.x.float).round.int32
    let c = if i mod (MajorEvery * mult) == 0: GridMajorColor else: GridMinorColor
    drawLine(sx, 0, sx, sh, c)

  for j in j0 .. j1:
    let wy = j.float * step
    let sy = ((wy - cam.target.y.float) * cam.zoom + cam.offset.y.float).round.int32
    let c = if j mod (MajorEvery * mult) == 0: GridMajorColor else: GridMinorColor
    drawLine(0, sy, sw, sy, c)
