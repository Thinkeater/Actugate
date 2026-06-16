import ../core/core
import ../data/cells
import types, camera, draw
import tables
import raylib

proc initRendererAndWindow*(config: RenderConfig): Renderer =
  ## Creates a window using the specified `config`.
  ##
  ## Initializes the camera and returns it

  initWindow(config.windowWidth.int32, config.windowHeight.int32, config.title)
  Renderer(config: config, camera: initCamera())

proc renderFrame*(r: Renderer, world: World) =
  ## Iterates over `world`'s cells and renders them one-by-one by calling `drawCell`

  for pos, cell in world.current:
    if cell.kind != ckNone:
      drawCell(cell, pos, r.config.tileSize)

