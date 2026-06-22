# piston_activates_dif_dirs.nim | Generated
import unittest
import core/core
import data/[cells, spatial]

suite "piston_activates_dif_dirs":
  test "right_init":
    var world = World()
    world.place(newPos(1, 0), newActivator(CellID(1), keep = true))
    world.place(newPos(0, 0), newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))

    # test expected "right_after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(1, 0)).matches(newActivator(CellID(1), keep = true))
    check world.get(newPos(0, 0)).matches(newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))

  test "down_init":
    var world = World()
    world.place(newPos(0, 0), newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(0, 1), newActivator(CellID(1), keep = true))

    # test expected "down_after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(1, 0)).matches(newRod(CellID(2), Direction.RIGHT, newPos(0, 0), keep = true))
    check world.get(newPos(0, 0)).matches(newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = true, rod = CellID(2), keep = true))
    check world.get(newPos(0, 1)).matches(newActivator(CellID(1), keep = true))

  test "left_init":
    var world = World()
    world.place(newPos(0, 0), newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(-1, 0), newActivator(CellID(1), keep = true))

    # test expected "left_after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(1, 0)).matches(newRod(CellID(2), Direction.RIGHT, newPos(0, 0), keep = true))
    check world.get(newPos(0, 0)).matches(newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = true, rod = CellID(2), keep = true))
    check world.get(newPos(-1, 0)).matches(newActivator(CellID(1), keep = true))

  test "up_init":
    var world = World()
    world.place(newPos(0, 0), newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(0, -1), newActivator(CellID(1), keep = true))

    # test expected "up_after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(1, 0)).matches(newRod(CellID(2), Direction.RIGHT, newPos(0, 0), keep = true))
    check world.get(newPos(0, 0)).matches(newPiston(CellID(0), Direction.RIGHT, priority = 0, activated = true, rod = CellID(2), keep = true))
    check world.get(newPos(0, -1)).matches(newActivator(CellID(1), keep = true))
