import types
import raylib

proc updateWindowSize*(rend: var Renderer, w: int32, h: int32) =
  rend.config.windowWidth = w
  rend.config.windowHeight = h
  rend.camCtrl.camera.offset.x = w / 2
  rend.camCtrl.camera.offset.y = h / 2
