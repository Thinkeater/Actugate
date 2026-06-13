import ../data/[cells, spatial, plans]
import std/tables

type 
  World* = object
    current*: Table[Position, Cell] = initTable[Position, Cell]()

    plans*: Table[Position, Plan] = initTable[Position, Plan]()  # TODO: make private

func newWorld*(): World =
  World()

func try_get*(self: World, p: Position): ptr Cell =
  if p in self.current: addr self.current[p]
  else: nil

func place_cell*(self: var World, p: Position, cell: Cell) =
  self.current[p] = cell

func try_activate_piston(self: var World, p: Position, cell: var Cell): bool =
  for d in Direction:
    if cell.direction == d: continue
    let opt = self.try_get(d.apply p)
    if opt != nil and opt[].kind == ckActivator:
      return true
  false

func plan(self: var World, p: Position, plan: Plan) =
  self.plans[p] = plan

func try_extend_rod(self: var World, p: Position, piston: Cell) =
  let target_pos = piston.direction.apply p
  var chain = initTable[Position, Position]()
  var current_pos = target_pos

  block collecting_chain:
    while (let current_cell_ptr = self.try_get(current_pos); current_cell_ptr != nil):
      let current_cell = current_cell_ptr[]
      if current_cell.is_immovable(): break collecting_chain
      let next_pos = piston.direction.apply current_pos
      chain[current_pos] = next_pos
      current_pos = next_pos
    self.plan(p, newExtendRodPlan(piston.priority, target_pos, chain))

func collect_plans(self: var World) =
  for pos, cell in self.current.mpairs:
    if cell.kind == ckPiston:
      cell.activated = self.try_activate_piston(pos, cell)

      if cell.activated:
        self.try_extend_rod(pos, cell)

func update*(self: var World) =
  self.collect_plans