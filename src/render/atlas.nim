## Texture atlas with shelf packing
##
## Packs sprites into a single RenderTexture2D

import raylib

type
  SpriteID* = distinct int32

  SpriteSlot = object
    x, y: int32
    w, h: int32

  Shelf = object
    y: int32            ## Pixels from top
    height: int32
    usedWidth: int32

  Atlas* = object
    texture*: RenderTexture2D
    width*, height*: int32
    slots: seq[SpriteSlot]
    shelves: seq[Shelf]
    building: bool

proc `==`*(a, b: SpriteID): bool {.borrow.}

# ===== Create / destroy =====

proc initAtlas*(width, height: int32): Atlas =
  ## Create an atlas with the given `width` and `height`.
  ## !!! Call `beginBuild` before drawing sprites into it.

  let tex = loadRenderTexture(width, height)
  Atlas(
    texture: tex,
    width: width,
    height: height,
    slots: @[],
    shelves: @[],
    building: false,
  )

proc destroy*(atlas: var Atlas) =
  reset(atlas.texture)

# ==== Building =====

proc beginBuild*(atlas: var Atlas) =
  ## Open the atlas texture for drawing

  assert not atlas.building, "atlas.beginBuild called while already building"
  atlas.building = true
  beginTextureMode(atlas.texture)
  clearBackground(Blank)

proc reserve*(atlas: var Atlas, w, h: int32): SpriteID =
  ## Reserve a slot in the atlas and return its `SpriteID`

  assert atlas.building, "atlas.reserve called outside beginBuild/endBuild"
  assert w > 0 and h > 0, "sprite sizes must be positive"

  for shelf in atlas.shelves.mitems:
    if shelf.usedWidth + w <= atlas.width and h <= shelf.height:
      let slot = SpriteSlot(x: shelf.usedWidth, y: shelf.y, w: w, h: h)
      shelf.usedWidth += w
      let id = SpriteID(atlas.slots.len.int32)
      atlas.slots.add(slot)
      return id

  # New shelf
  let shelfY =
    if atlas.shelves.len == 0: int32(0)
    else:
      let last = atlas.shelves[^1]
      last.y + last.height

  assert shelfY + h <= atlas.height,
    "atlas overflow: cannot fit " & $w & "x" & $h &
    " sprite (used " & $shelfY & "/" & $atlas.height & " vertical px)"

  var newShelf = Shelf(y: shelfY, height: h, usedWidth: w)
  let slot = SpriteSlot(x: 0, y: shelfY, w: w, h: h)
  atlas.shelves.add(newShelf)
  let id = SpriteID(atlas.slots.len.int32)
  atlas.slots.add(slot)
  return id

proc endBuild*(atlas: var Atlas) =
  assert atlas.building, "atlas.endBuild called without beginBuild"
  endTextureMode()
  setTextureFilter(atlas.texture.texture, Point)
  atlas.building = false

# ===== Readonly =====

proc offset*(atlas: Atlas, id: SpriteID): (int32, int32) {.inline.} =
  ## Get offset of sprite *id* inside the atlas.
  ## Use when building in draw calls

  let slot = atlas.slots[id.int32]
  (slot.x, slot.y)

proc spriteSize*(atlas: Atlas, id: SpriteID): (int32, int32) {.inline.} =
  let slot = atlas.slots[id.int32]
  (slot.w, slot.h)

proc sourceRect*(atlas: Atlas, id: SpriteID): Rectangle {.inline.} =
  ## Source rectangle for reading from the atlas texture

  let slot = atlas.slots[id.int32]
  Rectangle(
    x: slot.x.float32,
    y: (atlas.height - slot.y - slot.h).float32,      # some magic
    width: slot.w.float32,
    height: slot.h.float32,
  )

proc count*(atlas: Atlas): int {.inline.} =
  atlas.slots.len

# ===== Draw helpers =====

proc draw*(atlas: Atlas, id: SpriteID, dest: Rectangle,
           origin: Vector2 = Vector2(x: 0, y: 0),
           rotation: float32 = 0,
           tint: Color = White) {.inline.} =
  ## Draw sprite `id` into `dest` with optional params

  drawTexture(atlas.texture.texture, atlas.sourceRect(id),
              dest, origin, rotation, tint)

proc draw*(atlas: Atlas, id: SpriteID, x, y: float32,
           tint: Color = White) {.inline.} =
  ## Draw sprite `id` at position `(x, y)` at its original size

  let (w, h) = atlas.spriteSize(id)
  let dest = Rectangle(x: x, y: y, width: w.float32, height: h.float32)
  drawTexture(atlas.texture.texture, atlas.sourceRect(id),
              dest, Vector2(x: 0, y: 0), 0, tint)

