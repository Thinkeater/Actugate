import data/[cells, spatial]
import core/core
import std/[tables, rdstdin]

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

  for y in minY .. maxY:
    var line = ""
    for x in minX .. maxX:
      let pos = newPos(x, y)
      if (x, y) == (cx, cy):
        line.add "["
      elif (x-1, y) == (cx, cy):
        line.add "]"
      else:
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
    echo " ", line

var world = newWorld()
world.place(newPos(0, 0), newPiston(world.counter.next(), Direction.RIGHT))
world.place(newPos(0, 1), newActivator(world.counter.next()))
world.place(newPos(1, 1), newPiston(world.counter.next(), Direction.UP))

var
  cx = 1
  cy = 1

for n in 0..5:
  echo ""
  world.render(cx, cy)
  echo ""
  let cmd = readLineFromStdin('[' & $cx & ':' & $cy & "] >")

  world.update
