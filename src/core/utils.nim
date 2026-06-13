func minBy*[T, K](items: openArray[T]; key: proc(x: T): K {.noSideEffect.}): T =
  assert items.len > 0
  result = items[0]
  var best = key(result)
  for i in 1..<items.len:
    let current = key(items[i])
    if current < best:
      best = current
      result = items[i]