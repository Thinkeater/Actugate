import data/[cells, spatial]
import core/core
import std/tables

var world = newWorld()
world.place(newPos(0, 0), newPiston(Direction.RIGHT))
world.place(newPos(1, 1), newPiston(Direction.UP))
world.place(newPos(0, 1), newActivator())

for n in 0..1:
  echo "tick ", n
  echo "  ", world.current
  world.update