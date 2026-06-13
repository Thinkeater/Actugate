import ../data/[cells, spatial, plans]
import std/[tables, options, sets]
import ./utils

type 
  World* = object
    current*: ref Table[Position, Cell] = new(ref Table[Position, Cell])
    pending*: ref Table[Position, Cell] = new(ref Table[Position, Cell])
    plans*: Table[Position, Plan] = initTable[Position, Plan]()

func newWorld*(): World =
  World()

func try_get*(self: World, p: Position): Option[Cell] =
  ## Returns the Option of getting a cell by position, 
  ## if there are no cells in the position, returns none
  
  if p in self.current: some(self.current[p])
  else: none(Cell)

func place*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the current world
  
  self.current[p] = cell

func plan_place*(self: var World, p: Position, cell: Cell) =
  ## Places the cell by position in the pending world
  
  self.pending[p] = cell

func try_activate_piston(self: var World, p: Position, cell: var Cell): bool =
  ## Checking the conditions for piston activation
  
  for d in Direction:
    if cell.direction == d: continue
    let opt = self.try_get(d.apply p)
    if opt.is_some and opt.get().kind == ckActivator:
      return true
  false

func plan(self: var World, p: Position, plan: Plan) =
  self.plans[p] = plan

func try_extend_rod(self: var World, p: Position, piston: Cell) =
  ## He tries to create a plan for extending the rod from the piston, 
  ## observing the conditions of the chaining
  ## Important: Does not check whether the piston is activated
  
  let target_pos = piston.direction.apply p
  var chain = initTable[Position, Position]()
  var current_pos = target_pos

  block collecting_chain:
    while (let opt = self.try_get(current_pos); opt.is_some):
      let current_cell = opt.get()
      if current_cell.is_immovable(): break collecting_chain
      let next_pos = piston.direction.apply current_pos
      chain[current_pos] = next_pos
      current_pos = next_pos
    self.plan(p, newExtendRodPlan(piston.priority, target_pos, chain))

func collect_plans(self: var World) =
  ## Collects plans based on the current 
  ## state of the world, without changing it

  self.plans.clear

  for pos, cell in self.current.mpairs:
    if cell.kind == ckPiston:
      cell.activated = self.try_activate_piston(pos, cell)

      if cell.activated:
        self.try_extend_rod(pos, cell)

func best_plan(entry: tuple[pos: Position, plan: Plan]): (int, int, int) =
  (-entry.plan.priority, entry.pos.y, entry.pos.x)

func resolve_conflicts(self: var World) =
  var index = initTable[Position, seq[tuple[pos: Position, plan: Plan]]]()
  for pos, plan in self.plans.mpairs:
    var affected = initHashSet[Position]()
    case plan.kind:
    of pkExtendRod:
      affected = [plan.target].toHashSet()
      for pos in plan.chain.values:
        affected.incl(pos)
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
    for aff_pos in affected:
      if (var opt = self.try_get(aff_pos); opt.is_some):
        opt.get().keep = false

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
      let piston = self.try_get(pos).get()
      self.plan_place(plan.target, newRod(piston.direction, pos))
      # TODO: chain

  swap(self.current, self.pending)

func update*(self: var World) =
  ## Performs one tick of the world

  self.collect_plans
  self.resolve_conflicts
  self.apply_plans