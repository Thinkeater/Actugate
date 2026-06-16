import raylib

func initCamera*(): Camera2D =
  Camera2D(
    target: Vector2(x: 0, y: 0),
    offset: Vector2(x: 400, y: 300),
    rotation: 0,
    zoom: 1
  )

proc handleInput*(camera: var Camera2D, dt: float32) =
  ## Handles move and zoom input for `camera`

  let speed = 400 * dt
  if isKeyDown(KeyboardKey.W): camera.target.y -= speed
  if isKeyDown(KeyboardKey.S): camera.target.y += speed
  if isKeyDown(KeyboardKey.A): camera.target.x -= speed
  if isKeyDown(KeyboardKey.D): camera.target.x += speed

  let wheel = getMouseWheelMove()
  if wheel != 0:
    camera.zoom *= (1 + wheel * 0.1)
    camera.zoom = camera.zoom.clamp(0.25, 2)
