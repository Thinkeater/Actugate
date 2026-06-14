import data/[cells, spatial]
import core/core
import std/[tables, options]

proc render*(world: World) =
  var minX = 0
  var maxX = 2
  var minY = 0
  var maxY = 2

  for pos in world.current.keys:
    minX = min(minX, pos.x)
    maxX = max(maxX, pos.x)
    minY = min(minY, pos.y)
    maxY = max(maxY, pos.y)

  for y in minY .. maxY:
    var line = ""
    for x in minX .. maxX:
      let pos = newPos(x, y)
      if line.len > 0: line.add " "
      if pos in world.current:
        let cell = world.current[pos]
        case cell.kind
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
    echo line

var world = newWorld()
world.place(newPos(0, 0), newPiston(world.counter.next(), Direction.UP))
world.place(newPos(1, -1), newPiston(world.counter.next(), Direction.LEFT))
world.place(newPos(0, 1), newActivator(world.counter.next()))
world.place(newPos(1, -2), newActivator(world.counter.next()))

for n in 0..3:
  echo "--- tick ", n
  world.render

  if n == 2:
    world.remove(newPos(0, 1))

  world.update
