import data/[cells, spatial]
import core/core
import std/tables

var world = newWorld()
world.place_cell(newPos(0, 0), newPiston(Direction.RIGHT))
world.place_cell(newPos(0, 5), newActivator())

for n in 0..1:
  echo "tick", n, " ", world.current
  world.update