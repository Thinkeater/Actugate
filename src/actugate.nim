import data/[cells, spatial]
import core/core
import render/[types, camera, renderer, utils]
import raylib

const
  TickRate = 1
  TickInterval = 1.0 / TickRate

let config = RenderConfig(
  tileSize: 32, windowWidth: 800, windowHeight: 600, title: "Actugate"
)

setConfigFlags(flags(VsyncHint, WindowResizable))
var rend = initRendererAndWindow(config)
var world = newWorld()
var accumulator = 0.0

world.place(newPos(4, 0), newPiston(world.counter.next(), UP, priority=0, activated=false))
world.place(newPos(3, 1), newActivator(world.counter.next()))
world.place(newPos(-2, 2), newPiston(world.counter.next(), RIGHT, priority=0, activated=false))
world.place(newPos(1, 0), newActivator(world.counter.next()))
world.place(newPos(0, -2), newPiston(world.counter.next(), LEFT, priority=0, activated=false))
world.place(newPos(-1, -2), newActivator(world.counter.next()))
world.place(newPos(-2, 0), newActivator(world.counter.next()))
world.place(newPos(0, 0), newPiston(world.counter.next(), RIGHT, priority=0, activated=false))
world.place(newPos(0, 1), newActivator(world.counter.next()))
world.place(newPos(2, -2), newActivator(world.counter.next()))
world.place(newPos(4, -1), newActivator(world.counter.next()))
world.place(newPos(-1, 2), newActivator(world.counter.next()))
world.place(newPos(1, 2), newPiston(world.counter.next(), RIGHT, priority=0, activated=false))
world.place(newPos(2, 1), newPiston(world.counter.next(), RIGHT, priority=0, activated=false))
world.place(newPos(3, -2), newPiston(world.counter.next(), LEFT, priority=0, activated=false))
world.place(newPos(-2, -1), newPiston(world.counter.next(), DOWN, priority=0, activated=false))

while not windowShouldClose():
  let dt = getFrameTime()
  accumulator += dt

  if isWindowResized():
    rend.updateWindowSize(getScreenWidth(), getScreenHeight())

  while accumulator >= TickInterval:
    world.update()
    accumulator -= TickInterval
  rend.camera.handleInput(dt)

  beginDrawing()
  clearBackground(Color(r: 30, g: 30, b: 30, a: 255))
  rend.camera.beginMode2D()
  renderFrame(rend, world)
  endMode2D()
  drawFPS(10, 10)
  endDrawing()

closeWindow()
