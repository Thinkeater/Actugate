import raylib, math
import ../data/spatial

func screenToCell*(screen: Vector2, camera: Camera2D, tileSize: int): Position =
  ## Convert screen coordinates to the cell `Position` under the cursor

  let world = getScreenToWorld2D(screen, camera)
  let cx = floor(world.x.float / tileSize.float).int
  let cy = floor(world.y.float / tileSize.float).int
  newPos(cx, cy)
