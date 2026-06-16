import raylib

func newColor(r: uint8, g: uint8, b: uint8, a: uint8): Color {.inline.} =
  ## Helper to easily make `Color` from RGBA

  Color(r: r, b: b, g: g, a: a)


const
  Background* = newColor(23, 23, 24, 255)
  GridLine* = newColor(75, 75, 75, 255)
  Active* = newColor(48, 220, 100, 255)
  Inactive* = newColor(183, 48, 56, 255)

  Piston* = newColor(70, 72, 76, 255)
  StickyPiston* = newColor(50, 52, 86, 255)
  Rod* = newColor(233, 232, 234, 255)
