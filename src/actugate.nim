import data/[cells, spatial]
import core/[core, utils]
import std/[tables, rdstdin, strutils, terminal]
import raylib
import render/[types, renderer, utils, grid, colors]

raylib.setTraceLogLevel(TraceLogLevel.None)

proc render*(world: World, cx: int, cy: int) =
  var minX = -1
  var maxX = 1
  var minY = -1
  var maxY = 1

  for pos in world.current.keys:
    minX = min(minX, pos.x)
    maxX = max(maxX, pos.x)
    minY = min(minY, pos.y)
    maxY = max(maxY, pos.y)

  minX = min(minX, cx)
  maxX = max(maxX, cx)
  minY = min(minY, cy)
  maxY = max(maxY, cy)

  for y in minY .. maxY:
    var line = ""
    for x in minX .. maxX:
      let pos = newPos(x, y)
      if (x, y) == (cx, cy):
        line.add "["
      elif (x, y) != (cx + 1, cy):
        line.add " "
      if pos in world.current:
        let cell = world.current[pos]
        case cell.kind
        of ckNone: discard
        of ckActivator:
          line.add "##"
        of ckRod:
          case cell.pistonDirection
          of RIGHT: line.add "->"
          of DOWN:  line.add " v"
          of LEFT:  line.add "<-"
          of UP:    line.add "^ "
        of ckPiston:
          let letter = if cell.activated: "P" else: "p"
          let has_rod = cell.rod.is_some
          case cell.direction
          of RIGHT: line.add letter & (if has_rod: "*" else: ">")
          of DOWN:  line.add letter & (if has_rod: "*" else: "v")
          of LEFT:  line.add (if has_rod: "*" else: "<") & letter
          of UP:    line.add (if has_rod: "*" else: "^") & letter
      else:
        line.add ".."
      if (x, y) == (cx, cy):
        line.add "]"
    echo " ", line

proc codedump*(world: World) =
  for pos, cell in world.current.pairs:
    case cell.kind
    of ckNone, ckRod:
      discard

    of ckActivator:
      echo "world.place(newPos(" & $pos.x & ", " & $pos.y &
           "), newActivator(world.counter.next()))"

    of ckPiston:
      echo "world.place(newPos(" & $pos.x & ", " & $pos.y &
           "), newPiston(" &
           "world.counter.next(), " &
           $cell.direction &
           ", priority=" & $cell.priority &
           ", activated=" & $cell.activated &
           "))"

proc handle(cmd: string, world: var World, cx: var int, cy: var int, tick: var int) =
  var dx, dy: int

  if cmd[0] in "wasd":
    for d in cmd:
      case d:
      of 'w': dy -= 1
      of 'a': dx -= 1
      of 's': dy += 1
      of 'd': dx += 1
      else:
        echo "Unknown direction: '" & d & "'"
        return
    echo "Cursor moved successfully from " & $cx & ':' & $cy
    cx += dx
    cy += dy
  elif cmd == "A":
    world.place(newPos(cx, cy), newActivator(world.counter.next()))
    echo "Successfully placed activator at " & $cx & ':' & $cy
  elif cmd[0] == 'P':
    if cmd.len != 2:
      echo "Expected direction"
      return
    var direction: Direction
    if cmd[1] in "wasd":
      case cmd[1]:
      of 'w': direction = Direction.UP
      of 'a': direction = Direction.LEFT
      of 's': direction = Direction.DOWN
      of 'd': direction = Direction.RIGHT
      else: discard
    else:
      echo "Unknown direction: '" & cmd[1] & "'"
      return
    world.place(newPos(cx, cy), newPiston(world.counter.next(), direction))
    echo "Successfully placed piston at " & $cx & ':' & $cy
  elif cmd == "E" or cmd == "e":
    world.remove(newPos(cx, cy))
    echo "Successfully erased cell at " & $cx & ':' & $cy
  elif cmd == "i":
    let cell = world.get(newPos(cx, cy))
    echo "Cell at " & $cx & ':' & $cy
    echo "  kind: " & $cell.kind
    echo "  id: " & $cell.id
    case cell.kind:
    of ckNone, ckActivator: discard
    of ckPiston:
      echo "  direction: " & $cell.direction
      echo "  priority: " & $cell.priority
      echo "  activated: " & $cell.activated
      echo "  rodID: " & (if cell.rod.is_some: $cell.rod else: "absent")
    of ckRod:
      echo "  pidtonDirection: " & $cell.pistonDirection
      echo "  pidtonPosition: " & $cell.pistonPosition
  elif cmd[0] == 'p':
    if cmd.len notin 2..3:
      echo "Expected priority"
      return
    var cell = world.get(newPos(cx, cy))
    var priority: int
    var sign = 1
    var n = 1
    if cmd[1] == '-':
      sign = -1
      n = 2
    try:
      priority = parseInt(cmd[n] & "") * sign
    except ValueError:
      echo "Invalid priority"
      return
    if not cell.is_some:
      echo "NoneCell does not have a priority field"
      return
    echo "Priority has been successfully changed " & $cell.priority & " -> " & $priority
    world.current.cell_mutation_it(newPos(cx, cy)):
      it.priority = priority
  elif cmd == "q":
    quit()
  elif cmd == "t":
    world.update
    echo "tick " & $tick
    tick.inc
  elif cmd == "D":
    codedump(world)
  elif cmd == "gui" or cmd == "G":
    const
      TickRate = 1
      TickInterval = 1.0 / TickRate
    
    let config = RenderConfig(
      tileSize: 32,
      windowWidth: 800,
      windowHeight: 600,
      title: "Actugate"
    )
    
    setConfigFlags(flags(VsyncHint, WindowResizable))
    var rend = initRendererAndWindow(config)
    var accumulator = 0.0
    var guiTick = tick
    
    echo "GUI has been successfully opened in a new window"
    while not windowShouldClose():
      let dt = getFrameTime()
      accumulator += dt
      
      if isWindowResized():
        rend.updateWindowSize(getScreenWidth(), getScreenHeight())
      
      while accumulator >= TickInterval:
        world.update()
        guiTick.inc
        accumulator -= TickInterval
      
      rend.handleInput(dt)

      beginDrawing()
      clearBackground(Background)
      drawGrid(rend)
      rend.beginMode()
      renderFrame(rend, world, dt)
      endMode2D()
      
      drawText("Tick: " & $guiTick, 10, 30, 20, WHITE)
      let mp = getMousePosition()
      let cp = rend.screenToCell(mp)
      drawText("Cell: " & $cp.x & ", " & $cp.y, 10, 50, 20, WHITE)
      let cell = world.get(cp)
      if cell.is_some:
        drawText(($cell.kind)[2..^1], 10, 70, 20, WHITE)
      drawFPS(10, 10)
      endDrawing()
    
    closeWindow()
    tick = guiTick
    echo "GUI closed at tick " & $tick
  elif cmd == "h" or cmd == "help":
    echo "Commands:"
    echo "  h or help  Show this message."
    echo "  wasd       Move cursor. Multiple letters are allowed (ddasd, wa, sss)."
    echo "  A          Place activator at cursor."
    echo "  P[w/a/s/d] Place piston facing up/left/down/right."
    echo "  E          Remove cell at cursor."
    echo "  i          Show information about selected cell."
    echo "  pN         Set cell priority. Example: p3, p-1."
    echo "  t, Enter   Advance simulation by one tick."
    echo "  /          Execute multiple commands in sequence."
    echo "               Example: dsw/A or ww/Ps."
    echo "  D          Code dump"
    echo "  G or gui   Open graphical renderer"
    echo "  q          Quit program."
  else: 
    echo "Unknown command: '" & cmd & "'"

var world = newWorld()

var
  cx = 0
  cy = 0
  tick = 0

terminal.erase_screen()
terminal.set_cursor_pos(0, 0)
echo "[" & $cx & ':' & $cy & "] > " & "help" & "\n"
handle("h", world, cx, cy, tick)
echo "\ntick " & $tick
tick.inc
while true:
  echo ""
  world.render(cx, cy)
  echo ""
  let prompt = "[" & $cx & ':' & $cy & "] > "
  let userInput = readLineFromStdin(prompt)
  terminal.erase_screen()
  terminal.set_cursor_pos(0, 0)
  echo prompt & userInput & "\n"
  if userInput.len == 0:
    world.update
    echo "tick " & $tick
    tick.inc
  else:
    for cmd in userInput.split('/'):
      if cmd.strip().len != 0:
        handle(cmd.strip(), world, cx, cy, tick)
