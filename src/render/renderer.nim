import ../core/core
import ../data/cells
import types, camera, draw, sprites
import tables
import raylib

proc initRendererAndWindow*(config: RenderConfig): Renderer =
  initWindow(config.windowWidth.int32, config.windowHeight.int32, config.title)
  result.config = config
  result.camCtrl = initController(config.windowWidth.int32, config.windowHeight.int32)
  result.sprites = initSprites()

proc renderFrame*(r: var Renderer, world: World, dt: float32) =
  for pos, cell in world.current:
    if cell.isSome():
      r.sprites.drawCell(cell, pos, r.config.tileSize)
