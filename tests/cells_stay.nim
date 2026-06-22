# cells_stay.nim | Generated
import unittest
import core/core
import data/[cells, spatial]

suite "cells_stay":
  test "init":
    var world = World()
    world.place(newPos(0, 0), newActivator(CellID(0), keep = true))

    # test expected "after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(0, 0)).matches(newActivator(CellID(0), keep = true))

  test "init2":
    var world = World()
    world.place(newPos(0, 0), newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))

    # test expected "after2" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(0, 0)).matches(newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
