import ../data/[cells, spatial, plans]
import std/[tables, sets]
import ./utils

type 
  SmartCounter = object
    nextNew: CellID = 0
    deleted: HashSet[CellID]

  World* = object
    current*: Table[Position, Cell] = Table[Position, Cell]()
    pending*: Table[Position, Cell] = Table[Position, Cell]()
    plans*: Table[Position, Plan] = initTable[Position, Plan]()
    counter*: SmartCounter = SmartCounter(nextNew: 0, deleted: initHashSet[CellID]())

func next*(counter: var SmartCounter): CellID =
  if counter.deleted.len > 0:
    return counter.deleted.pop()
  result = counter.nextNew
  counter.nextNew += 1

func del*(counter: var SmartCounter, x: int) =
  counter.deleted.incl(x)

func newWorld*(): World =
  World()

func get*(self: World, p: Position): Cell {.inline.} =
  ## TODO: add doc
  
  self.current.getOrDefault(p, NoneCell)

func idGet*(self: World, id: CellID): Cell =
  ## TODO: add doc
  
  for pos, cell in self.current.pairs:
    if cell.id == id:
      return cell
  NoneCell

func place*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the current world
  
  self.current[p] = cell

func planPlace*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the pending world
  
  self.pending[p] = cell

func remove*(self: var World, p: Position) =
  ## Removes the cell by position in the current world
  
  let cell = self.get(p)
  if cell.isSome:
    if cell.kind == ckPiston and cell.rod.isSome:
      self.remove(cell.direction.apply p)
    self.counter.del(cell.id)
    self.current.del(p)

func planMove(self: var World, old: Position, new: Position) =
  ## Move cells from current world old position to pending world new position
  
  let cell = self.get(old)
  if cell.isSome:
    self.pending[new] = cell

func tryActivatePiston(self: var World, p: Position, cell: var Cell): bool =
  ## Checking the conditions for piston activation
  
  for d in Direction:
    if cell.direction == d: continue
    let neighbor = self.get(d.apply p)
    if neighbor.kind == ckActivator:
      return true
  false

func plan(self: var World, p: Position, plan: Plan) =
  self.plans[p] = plan

func tryExtendRod(self: var World, p: Position, piston: Cell) =
  ## He tries to create a plan for extending the rod from the piston, 
  ## observing the conditions of the chaining
  ## Important: Does not check whether the piston is activated
  
  let targetPos = piston.direction.apply p
  var chain: seq[(Position, Position)]
  var currentPos = targetPos

  block collectingChain:
    while (let cell = self.get(currentPos); cell.isSome):
      if cell.isImmovable(): break collectingChain
      let nextPos = piston.direction.apply currentPos
      chain.add((currentPos, nextPos))
      currentPos = nextPos
    self.plan(p, newExtendRodPlan(piston.priority, targetPos, chain))

func collectPlans*(self: var World) =
  ## Collects plans based on the current 
  ## state of the world, without changing it

  self.plans.clear

  for pos, cell in self.current.mpairs:
    cell.keep = true

    if cell.kind == ckPiston:
      cell.activated = self.tryActivatePiston(pos, cell)

      if cell.activated:
        self.tryExtendRod(pos, cell)

    if cell.kind == ckRod:
      let pistonPos = cell.pistonPosition
      let piston = self.get(pistonPos)
      if piston.kind == ckPiston and not piston.activated:
        cell.keep = false
        self.plan(pos, newRetractRodPlan(pistonPos))

func bestPlan(entry: tuple[pos: Position, plan: Plan]): (int, int, int) =
  (-entry.plan.priority, entry.pos.y, entry.pos.x)

func resolveConflicts*(self: var World) =
  var index = initTable[Position, seq[tuple[pos: Position, plan: Plan]]]()
  for pos, plan in self.plans.mpairs:
    var affected = initHashSet[Position]()
    case plan.kind:
    of pkExtendRod:
      affected = [plan.target, pos].toHashSet()
      for (_, pos) in plan.chain:
        affected.incl(pos)
    of pkRetractRod:
      continue
    for affPos in affected:
      index.mgetOrPut(affPos, @[]).add((pos: pos, plan: plan))

  var losers = initHashSet[Position]()
  for plans in index.values:
    if plans.len < 2: continue
    let best = plans.minBy(bestPlan)
    for data in plans:
      if data != best:
        losers.incl(data.pos)

  for pos in losers:
    self.plans.del(pos)

  for pos, plan in self.plans.mpairs:
    var affected = initHashSet[Position]()
    case plan.kind:
    of pkExtendRod:
      affected = [plan.target].toHashSet()
      for (_, pos) in plan.chain:
        affected.incl(pos)
    of pkRetractRod:
      affected = [pos].toHashSet()
    for affPos in affected:
      if not self.current.posExists(affPos): continue
      self.current.cellMutationIt(affPos):
        it.keep = false

func applyPlans*(self: var World) =
  ## Applies plans for a new world and 
  ## swaps new and old places
  
  self.pending.clear

  for pos, cell in self.current.pairs:
    if cell.keep:
      self.pending[pos] = cell

  for pos, plan in self.plans.mpairs:
    case plan.kind:
    of pkExtendRod:
      let piston = self.get(pos)
      for oldPos, newPos in plan.chain.reversedPairs:
        self.planMove(oldPos, newPos)
      let rod = newRod(self.counter.next(), piston.direction, pos, piston.kind)
      self.planPlace(plan.target, rod)
      self.pending.cellMutationIt(pos):
        it.rod = rod.id
    of pkRetractRod:
      self.pending.cellMutationIt(plan.pistonPosition):
        it.rod = NoneCellID

  swap(self.current, self.pending)

func update*(self: var World) =
  ## Performs one tick of the world

  self.collectPlans
  self.resolveConflicts
  self.applyPlans
