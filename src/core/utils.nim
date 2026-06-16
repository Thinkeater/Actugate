import std/[tables, macros]
import ../data/[cells, spatial]

func minBy*[T, K](items: openArray[T]; key: proc(x: T): K {.noSideEffect.}): T =
  assert items.len > 0
  result = items[0]
  var best = key(result)
  for i in 1..<items.len:
    let current = key(items[i])
    if current < best:
      best = current
      result = items[i]

iterator reversedPairs*[T, V](t: OrderedTable[T, V]): (T, V) =
  var keys = newSeq[T]()
  for key in t.keys:
    keys.add(key)
  for i in countdown(keys.len - 1, 0):
    let key = keys[i]
    yield (key, t[key])

macro cell_mutation_it*(world_container: untyped, pos: untyped, body: untyped): untyped =
  let cellVar = ident("it")
  let posVar = genSym(nskLet, "pos")
  
  result = quote do:
    let `posVar` = `pos`
    var `cellVar`: Cell = `world_container`[`posVar`]
    block:
      `body`
    `world_container`[`posVar`] = `cellVar`

func pos_exists*[T, V](world_container: Table[T, V], pos: Position): bool =
  pos in world_container

macro dlog*(args: varargs[untyped]): untyped =
  result = quote do:
    debugEcho `args`