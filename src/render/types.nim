import raylib
import camera, coords, sprites
import ../data/spatial

type
  RenderConfig* = object
    tileSize*: int
    windowWidth*: int
    windowHeight*: int
    title*: string

  Renderer* = object
    config*: RenderConfig
    camCtrl*: CameraController
    sprites*: Sprites

proc handleInput*(rend: var Renderer, dt: float32) =
  rend.camCtrl.update(dt)

proc beginMode*(rend: Renderer) =
  beginMode2D(rend.camCtrl.camera)

proc screenToCell*(rend: Renderer, screen: Vector2): Position =
  coords.screenToCell(screen, rend.camCtrl.camera, rend.config.tileSize)
