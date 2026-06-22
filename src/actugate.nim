import data/[cells, spatial]
import core/[core, utils]
import std/[tables, rdstdin, strutils, terminal, strformat, os]
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

proc runGui*(world: var World, tick: var int) =
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

proc generateTestInit(lines: var seq[string], world: World) =
  lines.add("    var world = World()")
  for pos, cell in world.current:
    let x = pos.x
    let y = pos.y
    case cell.kind
    of ckActivator:
      lines.add(&"    world.place(newPos({x}, {y}), newActivator(CellID({cell.id}), keep = {cell.keep}))")
    of ckPiston:
      let dir = cell.direction
      let pri = cell.priority
      let act = cell.activated
      let rod = if cell.rod.is_some: &"CellID({cell.rod})" else: "NoneCellID"
      lines.add(&"    world.place(newPos({x}, {y}), newPiston(CellID({cell.id}), Direction.{dir}, priority = {pri}, activated = {act}, rod = {rod}, keep = {cell.keep}))")
    of ckRod:
      let pDir = cell.pistonDirection
      let pPos = cell.pistonPosition
      lines.add(&"    world.place(newPos({x}, {y}), newRod(CellID({cell.id}), Direction.{pDir}, newPos({pPos.x}, {pPos.y}), keep = {cell.keep}))")
    of ckNone:
      discard

proc generateTestChecks(lines: var seq[string], world: World) =
  for pos, cell in world.current:
    let x = pos.x
    let y = pos.y
    case cell.kind
    of ckActivator:
      lines.add(&"    check world.get(newPos({x}, {y})).matches(newActivator(CellID({cell.id}), keep = {cell.keep}))")
    of ckPiston:
      let dir = cell.direction
      let pri = cell.priority
      let act = cell.activated
      let rod = if cell.rod.is_some: &"CellID({cell.rod})" else: "NoneCellID"
      lines.add(&"    check world.get(newPos({x}, {y})).matches(newPiston(CellID({cell.id}), Direction.{dir}, priority = {pri}, activated = {act}, rod = {rod}, keep = {cell.keep}))")
    of ckRod:
      let pDir = cell.pistonDirection
      let pPos = cell.pistonPosition
      lines.add(&"    check world.get(newPos({x}, {y})).matches(newRod(CellID({cell.id}), Direction.{pDir}, newPos({pPos.x}, {pPos.y}), keep = {cell.keep}))")
    of ckNone:
      lines.add(&"    check world.get(newPos({x}, {y})).kind == ckNone")

var saves: Table[string, (int, World)]

proc generateTest(self: World, name: string, args: seq[string]) =
  var tests: seq[seq[string]] = @[]
  var cur: seq[string] = @[]

  for x in args:
    if x == "|":
      tests.add cur
      cur = @[]
    else:
      let xs = x.strip()
      if xs notin saves:
        echo "Save '" & xs & "' does not exists"
        return
      cur.add xs

  if cur.len > 0: tests.add cur

  var lines: seq[string] = @[
    &"# {name}.nim | Generated",
    "import unittest",
    "import core/core",
    "import data/[cells, spatial]",
    "",
    &"suite \"{name}\":"
  ]

  for test in tests:
    let init_name = test[0]
    var init_tick = saves[init_name][0]
    lines.add(&"  test \"{init_name}\":")
    generateTestInit(lines, saves[init_name][1])
    for expected_name in test[1..^1]:
      let (tick, expected_world) = saves[expected_name]
      let delta_ticks = tick - init_tick
      init_tick = tick
      lines.add("")
      lines.add(&"    # test expected \"{expected_name}\" after {delta_ticks} tick(-s):")
      lines.add(&"    for _ in 0..<{delta_ticks}: world.update()")
      generateTestChecks(lines, expected_world)
    lines.add("")

  let testsDir = "tests"
  if not dirExists(testsDir):
    try:
      createDir(testsDir)
      echo "Created directory: " & testsDir
    except IOError:
      echo "Failed to create directory: " & testsDir
      return

  let filePath = testsDir / (name & ".nim")
  try:
    writeFile(filePath, lines.join("\n"))
    echo "Test saved to: " & filePath
  except IOError:
    echo "Failed to save test to: " & filePath

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
  elif cmd[0] == 'S':
    if cmd.len <= 2:
      echo "Expected save name"
      return
    let name = cmd[2..^1].strip()
    saves[name] = (tick, world)
    echo "Saved world at tick " & $tick & " as '" & name & "'"
  elif cmd[0] == 'L':
    if cmd.len <= 2:
      echo "Expected save name"
      return
    let name = cmd[2..^1].strip()
    if name notin saves:
      echo "Save '" & name & "' not found"
      return
    (tick, world) = saves[name]
    echo "Loaded save '" & name & "' at tick " & $tick
  elif cmd == "ls":
    if saves.len == 0:
      echo "No saves"
    else:
      for name, (t, w) in saves:
        echo "  " & name & " (tick: " & $t & ", cells: " & $w.current.len & ")"
  elif cmd == "R":
    world = World()
    tick = 0
    echo "World reset"
  elif cmd.len >= 2 and cmd[0..1] == "RS":
    if cmd.len <= 2:
      saves.clear()
      echo "All saves cleared"
    else:
      let name = cmd[3..^1].strip()
      if name notin saves:
        echo "Save '" & name & "' not found"
        return
      saves.del(name)
      echo "Save '" & name & "' deleted"
  elif cmd[0] == 'T':
    if cmd.len < 2:
      echo "Using: T name initial_save expected_save | ..."
      return
    let args = cmd[2..^1].split(' ')
    generateTest(world, args[0], args[1..^1])
  elif cmd == "gui" or cmd == "G":
    runGui(world, tick)
  elif cmd == "h":
    echo "no :)"
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
  if userInput.len != 0:
    for cmd in userInput.split('/'):
      if cmd.strip().len != 0:
        handle(cmd.strip(), world, cx, cy, tick)
