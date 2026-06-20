import ../data/[cells, spatial, plans]
import std/[tables, sets]
import ./utils

type 
  SmartCounter = object
    nextNew: CellID = 0  # always zero
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

func idget*(self: World, id: CellID): Cell =
  ## TODO: add doc
  
  for pos, cell in self.current.pairs:
    if cell.id == id:
      return cell
  NoneCell

func place*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the current world
  
  self.current[p] = cell

func plan_place*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the pending world
  
  self.pending[p] = cell

func remove*(self: var World, p: Position) =
  ## Removes the cell by position in the current world
  
  let cell = self.get(p)
  if cell.is_some:
    if cell.kind == ckPiston and cell.rod.is_some:
      self.remove(cell.direction.apply p)
    self.counter.del(cell.id)
    self.current.del(p)

func plan_move(self: var World, old: Position, new: Position) =
  ## Move cells from current world old position to pending world new position
  
  let cell = self.get(old)
  if cell.is_some:
    self.pending[new] = cell

func try_activate_piston(self: var World, p: Position, cell: var Cell): bool =
  ## Checking the conditions for piston activation
  
  for d in Direction:
    if cell.direction == d: continue
    let cell = self.get(d.apply p)
    if cell.kind == ckActivator:
      return true
  false

func plan(self: var World, p: Position, plan: Plan) =
  self.plans[p] = plan

func try_extend_rod(self: var World, p: Position, piston: Cell) =
  ## He tries to create a plan for extending the rod from the piston, 
  ## observing the conditions of the chaining
  ## Important: Does not check whether the piston is activated
  
  let target_pos = piston.direction.apply p
  var chain = initOrderedTable[Position, Position]()
  var current_pos = target_pos

  block collecting_chain:
    while (let cell = self.get(current_pos); cell.is_some):
      if cell.is_immovable(): break collecting_chain
      let next_pos = piston.direction.apply current_pos
      chain[current_pos] = next_pos
      current_pos = next_pos
    self.plan(p, newExtendRodPlan(piston.priority, target_pos, chain))

func collect_plans(self: var World) =
  ## Collects plans based on the current 
  ## state of the world, without changing it

  self.plans.clear

  for pos, cell in self.current.mpairs:
    cell.keep = true

    if cell.kind == ckPiston:
      cell.activated = self.try_activate_piston(pos, cell)

      if cell.activated:
        self.try_extend_rod(pos, cell)

    if cell.kind == ckRod:
      let piston_pos = cell.pistonPosition
      let piston = self.get(piston_pos)
      if piston.kind == ckPiston and not piston.activated:
        cell.keep = false
        self.plan(pos, newRetractRodPlan(piston_pos))

func best_plan(entry: tuple[pos: Position, plan: Plan]): (int, int, int) =
  (-entry.plan.priority, entry.pos.y, entry.pos.x)

func resolve_conflicts(self: var World) =
  var index = initTable[Position, seq[tuple[pos: Position, plan: Plan]]]()
  for pos, plan in self.plans.mpairs:
    var affected = initHashSet[Position]()
    case plan.kind:
    of pkExtendRod:
      affected = [plan.target, pos].toHashSet()
      for pos in plan.chain.values:
        affected.incl(pos)
    of pkRetractRod:
      continue
    for aff_pos in affected:
      index.mgetOrPut(aff_pos, @[]).add((pos: pos, plan: plan))

  var losers = initHashSet[Position]()
  for plans in index.values:
    if plans.len < 2: continue
    let best = plans.minBy(best_plan)
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
      for pos in plan.chain.values:
        affected.incl(pos)
    of pkRetractRod:
      affected = [pos].toHashSet()
    for aff_pos in affected:
      if not self.current.pos_exists(aff_pos): continue
      self.current.cell_mutation_it(aff_pos):
        it.keep = false

func apply_plans(self: var World) =
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
      for old_pos, new_pos in plan.chain.reversed_pairs:
        self.plan_move(old_pos, new_pos)
      let rod = newRod(self.counter.next(), piston.direction, pos)
      self.plan_place(plan.target, rod)
      self.pending.cell_mutation_it(pos):
        it.rod = rod.id
    of pkRetractRod:
      self.pending.cell_mutation_it(plan.pistonPosition):
        it.rod = NoneCellID

  swap(self.current, self.pending)

func update*(self: var World) =
  ## Performs one tick of the world

  self.collect_plans
  self.resolve_conflicts
  self.apply_plans