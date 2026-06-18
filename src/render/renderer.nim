import ../core/core
import ../data/cells
import types, camera, draw
import tables
import raylib

proc initRendererAndWindow*(config: RenderConfig): Renderer =
  initWindow(config.windowWidth.int32, config.windowHeight.int32, config.title)
  Renderer(config: config, camCtrl: initController(config.windowWidth.int32, config.windowHeight.int32))

proc renderFrame*(r: Renderer, world: World, dt: float32) =
  for pos, cell in world.current:
    if cell.isSome():
      drawCell(cell, pos, r.config.tileSize)
