import raylib

const
  ZoomThreshold*   = 0.001
  WheelZoomFactor* = 0.1
  MouseBlend*      = 0.3
  MinZoom*         = 0.5
  MaxZoom*         = 4.0

type CameraController* = object
  camera*: Camera2D               ## Raylib camera
  targetZoom*: float32
  velocity*: Vector2              ## Current pan velocity (world units/s)
  zoomSpeed*: float32
  panFriction*: float32
  zoomAnchorScreen*: Vector2      ## Cursor screen position at last scroll

proc initController*(width, height: int32): CameraController =
  ## Create a camera centered in the window

  CameraController(
    camera: Camera2D(
      target: Vector2(x: 0, y: 0),
      offset: Vector2(x: width.float / 2, y: height.float / 2),
      rotation: 0,
      zoom: 1
    ),
    targetZoom: 1,
    zoomSpeed: 16,
    panFriction: 10
  )

proc update*(ctrl: var CameraController, dt: float32) =
  ## Handle camera input: MMB drag for panning, scroll for zoom

  # Zoom lerp
  if abs(ctrl.camera.zoom - ctrl.targetZoom) > ZoomThreshold:
    let oldZoom = ctrl.camera.zoom
    let t = min(ctrl.zoomSpeed * dt, 1)
    let newZoom = oldZoom + (ctrl.targetZoom - oldZoom) * t

    let dx = (ctrl.zoomAnchorScreen.x - ctrl.camera.offset.x) * (1/oldZoom - 1/newZoom)
    let dy = (ctrl.zoomAnchorScreen.y - ctrl.camera.offset.y) * (1/oldZoom - 1/newZoom)

    ctrl.camera.zoom = newZoom
    ctrl.camera.target.x += dx
    ctrl.camera.target.y += dy
  else:
    ctrl.camera.zoom = ctrl.targetZoom

  # MMB drag
  if isMouseButtonDown(MouseButton.MIDDLE):
    let delta = getMouseDelta()
    ctrl.camera.target.x -= delta.x / ctrl.camera.zoom
    ctrl.camera.target.y -= delta.y / ctrl.camera.zoom

    if dt > 0:
      let mouseVelX = -delta.x / ctrl.camera.zoom / dt
      let mouseVelY = -delta.y / ctrl.camera.zoom / dt
      ctrl.velocity.x = ctrl.velocity.x * (1 - MouseBlend) + mouseVelX * MouseBlend
      ctrl.velocity.y = ctrl.velocity.y * (1 - MouseBlend) + mouseVelY * MouseBlend
  else:
    let friction = max(0, 1 - ctrl.panFriction * dt)
    ctrl.velocity.x *= friction
    ctrl.velocity.y *= friction
    ctrl.camera.target.x += ctrl.velocity.x * dt
    ctrl.camera.target.y += ctrl.velocity.y * dt

  # Wheel
  let wheel = getMouseWheelMove()
  if wheel != 0:
    ctrl.zoomAnchorScreen = getMousePosition()
    ctrl.targetZoom *= (1 + wheel * WheelZoomFactor)
    ctrl.targetZoom = max(MinZoom, min(MaxZoom, ctrl.targetZoom))
