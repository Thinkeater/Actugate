import types
import raylib

proc updateWindowSize*(rend: var Renderer, w: int32, h: int32) =
  ## Updates window size in `renderer.config` and recalculates camera offset

  rend.config.windowWidth = w
  rend.config.windowHeight = h
  rend.camera.offset.x = w / 2
  rend.camera.offset.y = h / 2
