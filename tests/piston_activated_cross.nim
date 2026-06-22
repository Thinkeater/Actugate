# piston_activated_cross.nim | Generated
import unittest
import core/core
import data/[cells, spatial]

suite "piston_activated_cross":
  test "init":
    var world = World()
    world.place(newPos(-1, 1), newPiston(CellID(5), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(-1, -1), newPiston(CellID(6), Direction.DOWN, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(1, 0), newPiston(CellID(2), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(1, 1), newPiston(CellID(8), Direction.UP, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(0, 0), newActivator(CellID(0), keep = true))
    world.place(newPos(-1, 0), newPiston(CellID(4), Direction.LEFT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(0, 1), newPiston(CellID(3), Direction.DOWN, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(0, -1), newPiston(CellID(1), Direction.UP, priority = 0, activated = false, rod = NoneCellID, keep = true))
    world.place(newPos(1, -1), newPiston(CellID(7), Direction.LEFT, priority = 0, activated = false, rod = NoneCellID, keep = true))

    # test expected "after" after 1 tick(-s):
    for _ in 0..<1: world.update()
    check world.get(newPos(-1, 1)).matches(newPiston(CellID(5), Direction.RIGHT, priority = 0, activated = false, rod = NoneCellID, keep = true))
    check world.get(newPos(0, 2)).matches(newRod(CellID(11), Direction.DOWN, newPos(0, 1), keep = true))
    check world.get(newPos(-1, -1)).matches(newPiston(CellID(6), Direction.DOWN, priority = 0, activated = false, rod = NoneCellID, keep = true))
    check world.get(newPos(1, 0)).matches(newPiston(CellID(2), Direction.RIGHT, priority = 0, activated = true, rod = CellID(9), keep = true))
    check world.get(newPos(0, -2)).matches(newRod(CellID(12), Direction.UP, newPos(0, -1), keep = true))
    check world.get(newPos(1, 1)).matches(newPiston(CellID(8), Direction.UP, priority = 0, activated = false, rod = NoneCellID, keep = true))
    check world.get(newPos(-2, 0)).matches(newRod(CellID(10), Direction.LEFT, newPos(-1, 0), keep = true))
    check world.get(newPos(0, 0)).matches(newActivator(CellID(0), keep = true))
    check world.get(newPos(2, 0)).matches(newRod(CellID(9), Direction.RIGHT, newPos(1, 0), keep = true))
    check world.get(newPos(-1, 0)).matches(newPiston(CellID(4), Direction.LEFT, priority = 0, activated = true, rod = CellID(10), keep = true))
    check world.get(newPos(0, 1)).matches(newPiston(CellID(3), Direction.DOWN, priority = 0, activated = true, rod = CellID(11), keep = true))
    check world.get(newPos(0, -1)).matches(newPiston(CellID(1), Direction.UP, priority = 0, activated = true, rod = CellID(12), keep = true))
    check world.get(newPos(1, -1)).matches(newPiston(CellID(7), Direction.LEFT, priority = 0, activated = false, rod = NoneCellID, keep = true))
