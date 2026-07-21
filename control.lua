-- Composite buildings whose visible shell is a placeholder over hidden,
-- script-managed parts:
--   * Gantry: a simple-entity shell over a central bin and 12 hidden loaders
--     (6 per long side) acting as a belt balancer.
--   * Distributor Crane: a simple-entity shell over two distinct hidden bins
--     (input/output), each served by a hidden loader, that services every
--     crafting machine in a radius -- collecting outputs and distributing
--     ingredients/fuel -- and exposes both bins through a custom GUI.

-- Forward declaration: appends a solar panel to storage.solar_panels for the
-- pollution-tiering pass. Assigned in the pollution-effects section; hoisted
-- here so the shared build dispatcher (below) can reference it as an upvalue.
local register_solar_panel

-- Forward declaration: enrolls a hunter in storage.hunters for surface-life
-- decay. Assigned in the emergence section; hoisted so the morph completion
-- handler (below) can register the bruisers/exploders it creates.
local register_hunter
local register_mining_wagon

local GANTRY = "nullarbor-gantry"
local GANTRY_LOADER = "nullarbor-gantry-loader"
local GANTRY_BIN_NS = "nullarbor-gantry-bin-ns"
local GANTRY_BIN_EW = "nullarbor-gantry-bin-ew"

local CRANE = "nullarbor-distributor-crane"
local CRANE_LOADER = "nullarbor-crane-loader"
local CRANE_BIN = "nullarbor-crane-bin"
-- Bin slot layout: 1 = input left lane, 2 = input right, 3 = output left, 4 = output right.
local CRANE_IN_SLOTS = { 1, 2 }
local CRANE_OUT_SLOTS = { 3, 4 }
local CRANE_AREA_HALF = 4.5 -- 9x9 area: 3x3 footprint + 3 tiles each side (matches the radius=1 preview)

local MINING_WAGON = "nullarbor-mining-wagon"
local MINING_DRILL = "nullarbor-mining-wagon-drill"
local MINING_WAGON_GUI = "nullarbor-mining-wagon-fuel"
local MINING_SERVICE_PERIOD = 31 -- ticks: fuel top-up + fuel-bar refresh cadence (unique; 30 is the crane servicer)
local MINING_FUEL_REF = 4000000 -- J reference (~coal) for the fuel-bar fraction
local MINING_AREA_R = 3 -- half-extent of the hover area highlight (matches the drill's ~6x6)
-- Keep each serviced machine topped up to this many of every item it accepts
-- (ingredients and burner fuel). Placeholder value, needs balancing.
local CRANE_INPUT_TARGET = 10

-- Bestiary morphing. When a swarmer engages (a hostile target comes within
-- MORPH_ENGAGE_RANGE), it rolls once: a chance to morph into a bruiser or
-- exploder, otherwise it stays a swarmer. Only swarmers roll. Placeholder
-- chances, need balancing.
local SWARMER = "nullarbor-swarmer"
local BRUISER = "nullarbor-bruiser"
local EXPLODER = "nullarbor-exploder"
local MORPHING_BRUISER = "nullarbor-morphing-bruiser"
local MORPHING_EXPLODER = "nullarbor-morphing-exploder"
local MORPH_ENGAGE_RANGE = 16 -- a hostile target this close = "engaged"
local MORPH_SCAN_RADIUS = 64 -- only evaluate swarmers near a player (bounds cost)
local MORPH_CHANCE_BRUISER = 0.20
local MORPH_CHANCE_EXPLODER = 0.20
-- Windup the intermediate spends before completing into its final form.
-- Bruiser morph is fast, exploder morph slow (CLAUDE.md). Killing the
-- intermediate before this elapses cancels the morph.
local BRUISER_MORPH_TICKS = 90 -- 1.5s
local EXPLODER_MORPH_TICKS = 300 -- 5s

-- 90° counter-clockwise of each direction: the "left" side of the facing axis.
local LEFT_OF = {
  [defines.direction.north] = defines.direction.west,
  [defines.direction.west] = defines.direction.south,
  [defines.direction.south] = defines.direction.east,
  [defines.direction.east] = defines.direction.north,
}

-- ========================= gantry composite =========================

-- One loader per long-side edge tile, 6 per side, belt end facing outward.
-- The side to the left of the shell's facing is the input side (belt ->
-- buffer), the right side is output (buffer -> belt); rotating the shell
-- cycles which physical sides those are.
local function gantry_loader_specs(shell)
  local pos = shell.position
  local vertical = shell.direction == defines.direction.north or shell.direction == defines.direction.south
  local input_side = LEFT_OF[shell.direction]
  local specs = {}
  if vertical then
    for _, sx in ipairs({ -1.5, 1.5 }) do
      local outward = sx < 0 and defines.direction.west or defines.direction.east
      for gy = -2.5, 2.5 do
        specs[#specs + 1] = {
          position = { x = pos.x + sx, y = pos.y + gy },
          outward = outward,
          is_input = outward == input_side,
        }
      end
    end
  else
    for _, sy in ipairs({ -1.5, 1.5 }) do
      local outward = sy < 0 and defines.direction.north or defines.direction.south
      for gx = -2.5, 2.5 do
        specs[#specs + 1] = {
          position = { x = pos.x + gx, y = pos.y + sy },
          outward = outward,
          is_input = outward == input_side,
        }
      end
    end
  end
  return specs
end

local function create_gantry_parts(shell)
  local vertical = shell.direction == defines.direction.north or shell.direction == defines.direction.south
  local bin = shell.surface.create_entity({
    name = vertical and GANTRY_BIN_NS or GANTRY_BIN_EW,
    position = shell.position,
    force = shell.force,
  })
  bin.destructible = false
  local loaders = {}
  for _, spec in ipairs(gantry_loader_specs(shell)) do
    local loader = shell.surface.create_entity({
      name = GANTRY_LOADER,
      position = spec.position,
      direction = spec.outward,
      force = shell.force,
    })
    loader.destructible = false
    -- Fixed for the building's life: input side loads the buffer, output
    -- side empties it. The two together make a 6-lane belt balancer.
    -- The loader is created facing outward (belt end to the external belt,
    -- container end to the central bin); only loader_type is set after, and
    -- direction is NOT re-set — re-setting it after loader_type flips the
    -- input loaders' belt to the wrong side.
    loader.loader_type = spec.is_input and "input" or "output"
    loaders[#loaders + 1] = { entity = loader, outward = spec.outward, is_input = spec.is_input }
  end
  return bin, loaders
end

local function on_gantry_built(shell)
  local bin, loaders = create_gantry_parts(shell)
  local entry = { shell = shell, bin = bin, loaders = loaders }
  storage.gantries[shell.unit_number] = entry
  script.register_on_object_destroyed(shell)
end

-- Open the bin's inventory when the player opens the shell (the shell
-- itself has no GUI).
script.on_event("nullarbor-gantry-open", function(event)
  local player = game.get_player(event.player_index)
  local selected = player and player.selected
  if selected and selected.valid and selected.name == GANTRY then
    local entry = storage.gantries[selected.unit_number]
    if entry and entry.bin.valid then
      player.opened = entry.bin
    end
  end
end)

-- Move a container's contents into the mining buffer so nothing is lost when
-- the composite building is mined.
local function drain_bin_to_buffer(bin, buffer)
  if not (bin and bin.valid) then
    return
  end
  local inventory = bin.get_inventory(defines.inventory.chest)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read then
      buffer.insert(stack)
    end
  end
  inventory.clear()
end

local composite_mined_filter = {
  { filter = "name", name = GANTRY },
  { filter = "name", name = CRANE },
}
local function on_composite_mined(event)
  local gantry = storage.gantries[event.entity.unit_number]
  if gantry then
    drain_bin_to_buffer(gantry.bin, event.buffer)
    return
  end
  local crane = storage.cranes[event.entity.unit_number]
  if crane then
    drain_bin_to_buffer(crane.parts.bin, event.buffer)
  end
end
script.on_event(defines.events.on_player_mined_entity, on_composite_mined, composite_mined_filter)
script.on_event(defines.events.on_robot_mined_entity, on_composite_mined, composite_mined_filter)

-- ========================= crane composite =========================

-- Two hidden 1x1 bins on the middle row, each with a hidden loader one tile
-- south of it. With the loader facing south, its container side is north (the
-- bin) and its belt side is south (the external belt). Input bin/loader on
-- the west half, output bin/loader on the east half; both belts come from the
-- south face. Loaders are created facing outward and only loader_type is set
-- afterward (re-setting direction after loader_type flips the belt side — the
-- gantry documents the same quirk).
local DIR_VEC = {
  [defines.direction.north] = { x = 0, y = -1 },
  [defines.direction.east] = { x = 1, y = 0 },
  [defines.direction.south] = { x = 0, y = 1 },
  [defines.direction.west] = { x = -1, y = 0 },
}

-- One 4-slot bin at the shell centre + two container-less loaders on the chosen
-- front face. f = front unit vector, p = its perpendicular. The input loader sits
-- at p*-1, output at p*+1; belt side faces outward (f), container side faces the
-- footprint interior (empty -- the ag-tower has no linkable inventory), so the
-- loaders stay container-less and control.lua routes each belt lane to a slot via
-- their transport lines. Rebuilt on rotation -- the ag-tower graphic doesn't turn.
local function create_crane_parts(shell, direction)
  local pos = shell.position
  local f = DIR_VEC[direction] or DIR_VEC[defines.direction.south]
  local p = { x = f.y, y = -f.x } -- perpendicular; input on the left, output on the right
  local bin = shell.surface.create_entity({
    name = CRANE_BIN,
    position = { x = pos.x, y = pos.y },
    force = shell.force,
  })
  bin.destructible = false
  local function make_loader(side, is_input)
    local loader = shell.surface.create_entity({
      name = CRANE_LOADER,
      position = { x = pos.x + f.x + p.x * side, y = pos.y + f.y + p.y * side },
      direction = direction,
      force = shell.force,
    })
    loader.destructible = false
    -- Created facing outward; only loader_type is set after (re-setting direction
    -- after loader_type flips the belt side -- same quirk the gantry documents).
    loader.loader_type = is_input and "input" or "output"
    return loader
  end
  return {
    bin = bin,
    input_loader = make_loader(-1, true),
    output_loader = make_loader(1, false),
  }
end

local function on_crane_built(shell)
  local direction = defines.direction.south
  storage.cranes[shell.unit_number] = {
    shell = shell,
    direction = direction,
    parts = create_crane_parts(shell, direction),
  }
  script.register_on_object_destroyed(shell)
end

local NEXT_DIR = {
  [defines.direction.north] = defines.direction.east,
  [defines.direction.east] = defines.direction.south,
  [defines.direction.south] = defines.direction.west,
  [defines.direction.west] = defines.direction.north,
}

-- Rotating reorients only the hidden loaders/bins (the shell graphic is fixed).
-- Destroy and rebuild the parts on the next face, carrying bin contents and
-- output-slot filters across.
local function rotate_crane(entry)
  local shell = entry.shell
  if not shell.valid then
    return
  end
  local saved
  local old_bin = entry.parts.bin
  if old_bin and old_bin.valid then
    local inv = old_bin.get_inventory(defines.inventory.chest)
    saved = { contents = inv.get_contents(), filters = {} }
    for i = 1, #inv do
      saved.filters[i] = inv.get_filter(i)
    end
  end
  for _, part in pairs(entry.parts) do
    if part.valid then
      part.destroy()
    end
  end
  entry.direction = NEXT_DIR[entry.direction] or defines.direction.south
  entry.parts = create_crane_parts(shell, entry.direction)
  if saved and entry.parts.bin.valid then
    local inv = entry.parts.bin.get_inventory(defines.inventory.chest)
    for i, filt in pairs(saved.filters) do
      pcall(function()
        inv.set_filter(i, filt)
      end)
    end
    for _, stack in pairs(saved.contents) do
      inv.insert(stack)
    end
  end
end

-- One R press can trigger both the linked custom-input and (if the ag-tower
-- honours `rotatable`) on_player_rotated_entity; guard so we rotate only once.
local function try_rotate_crane(entry)
  if entry.last_rotate == game.tick then
    return
  end
  entry.last_rotate = game.tick
  rotate_crane(entry)
end

script.on_event("nullarbor-distributor-rotate", function(event)
  local player = game.get_player(event.player_index)
  local selected = player and player.selected
  if selected and selected.valid and selected.name == CRANE then
    local entry = storage.cranes[selected.unit_number]
    if entry then
      try_rotate_crane(entry)
    end
  end
end)

-- ---- 4-slot bin helpers + strict lane routing --------------------------
local function slot_filter_name(inv, index)
  local f = inv.get_filter(index)
  if not f then
    return nil
  end
  return type(f) == "table" and f.name or f
end

-- Add up to `count` of an item into ONE specific slot, respecting the slot's
-- filter and stack size. Returns the amount added.
local function add_to_slot(inv, index, name, quality, count)
  if count <= 0 then
    return 0
  end
  local filt = slot_filter_name(inv, index)
  if filt and filt ~= name then
    return 0
  end
  local slot = inv[index]
  local stack_size = prototypes.item[name].stack_size
  if slot.valid_for_read then
    if slot.name ~= name then
      return 0
    end
    local add = math.min(stack_size - slot.count, count)
    if add > 0 then
      slot.count = slot.count + add
    end
    return add
  end
  local add = math.min(stack_size, count)
  slot.set_stack({ name = name, count = add, quality = quality })
  return add
end

-- Strict lane -> slot: drain a loader transport line into one slot.
local function pull_lane_to_slot(line, inv, index)
  if not line then
    return
  end
  for _, item in pairs(line.get_contents()) do
    local moved = add_to_slot(inv, index, item.name, item.quality, item.count)
    if moved > 0 then
      line.remove_item({ name = item.name, count = moved, quality = item.quality })
    end
  end
end

-- Strict slot -> lane: feed a slot's item onto one loader transport line. Runs
-- every tick and inserts until the lane is full at the feed point, so throughput
-- self-regulates to belt speed.
local function push_slot_to_lane(inv, index, line)
  if not line then
    return
  end
  local slot = inv[index]
  while slot.valid_for_read and slot.count > 0 do
    if line.can_insert_at(0.25) and line.insert_at(0.25, { name = slot.name, quality = slot.quality }) then
      slot.count = slot.count - 1
    else
      break
    end
  end
end

-- Route an item across the OUTPUT slots (3,4), balancing across any that accept
-- it (unfiltered or filtered to this item) so both lanes fill evenly. Adds to the
-- accepting slot that currently holds the least of it, in small chunks.
local function add_to_output_slots(inv, name, quality, count)
  local stack_size = prototypes.item[name].stack_size
  local moved_total = 0
  while count > 0 do
    local target, target_have
    for _, index in ipairs(CRANE_OUT_SLOTS) do
      local filt = slot_filter_name(inv, index)
      local slot = inv[index]
      local occupied_other = slot.valid_for_read and slot.name ~= name
      if (not filt or filt == name) and not occupied_other then
        local have = slot.valid_for_read and slot.count or 0
        if have < stack_size and (not target_have or have < target_have) then
          target, target_have = index, have
        end
      end
    end
    if not target then
      break
    end
    local moved = add_to_slot(inv, target, name, quality, math.min(count, 8))
    if moved <= 0 then
      break
    end
    moved_total = moved_total + moved
    count = count - moved
  end
  return moved_total
end

-- Pull machine outputs into the OUTPUT slots (3,4), honouring their filters.
local function collect_outputs(machines, inv)
  for _, machine in pairs(machines) do
    local src = machine.get_output_inventory()
    if src then
      for _, item in pairs(src.get_contents()) do
        local moved = add_to_output_slots(inv, item.name, item.quality, item.count)
        if moved > 0 then
          src.remove({ name = item.name, count = moved, quality = item.quality })
        end
      end
    end
  end
end

-- Push the INPUT slots (1,2) into machines that can use them, capped to
-- CRANE_INPUT_TARGET. can_insert gates validity (only real recipe
-- ingredients/fuel pass); insert() routes to the right sub-inventory.
local function distribute_inputs(machines, inv)
  for _, machine in pairs(machines) do
    for _, index in ipairs(CRANE_IN_SLOTS) do
      local slot = inv[index]
      if slot.valid_for_read then
        local name, quality = slot.name, slot.quality
        local need = CRANE_INPUT_TARGET - machine.get_item_count(name)
        if need > 0 and machine.can_insert({ name = name, count = 1, quality = quality }) then
          local inserted = machine.insert({ name = name, count = math.min(need, slot.count), quality = quality })
          if inserted > 0 then
            slot.count = slot.count - inserted
          end
        end
      end
    end
  end
end

-- Belt <-> slot lane transfer. Runs EVERY tick so items flow at belt speed.
local function service_crane_lanes(entry)
  local bin = entry.parts.bin
  if not (bin and bin.valid) then
    return
  end
  local inv = bin.get_inventory(defines.inventory.chest)
  local in_loader = entry.parts.input_loader
  if in_loader and in_loader.valid then
    pull_lane_to_slot(in_loader.get_transport_line(1), inv, CRANE_IN_SLOTS[1])
    pull_lane_to_slot(in_loader.get_transport_line(2), inv, CRANE_IN_SLOTS[2])
  end
  local out_loader = entry.parts.output_loader
  if out_loader and out_loader.valid then
    push_slot_to_lane(inv, CRANE_OUT_SLOTS[1], out_loader.get_transport_line(1))
    push_slot_to_lane(inv, CRANE_OUT_SLOTS[2], out_loader.get_transport_line(2))
  end
end

-- Machine exchange (distribute inputs, collect outputs). Periodic is fine.
local function service_crane_machines(entry)
  local shell = entry.shell
  local bin = entry.parts.bin
  if not (shell.valid and bin and bin.valid) then
    return
  end
  local inv = bin.get_inventory(defines.inventory.chest)
  local pos = shell.position
  local machines = shell.surface.find_entities_filtered({
    area = {
      { pos.x - CRANE_AREA_HALF, pos.y - CRANE_AREA_HALF },
      { pos.x + CRANE_AREA_HALF, pos.y + CRANE_AREA_HALF },
    },
    type = { "assembling-machine", "furnace" },
  })
  distribute_inputs(machines, inv)
  collect_outputs(machines, inv)
end

-- Lane transfer at belt speed.
script.on_nth_tick(1, function()
  for _, entry in pairs(storage.cranes) do
    if entry.shell.valid then
      service_crane_lanes(entry)
    end
  end
end)

-- Machine exchange + prune dead cranes.
script.on_nth_tick(30, function()
  for unit_number, entry in pairs(storage.cranes) do
    if entry.shell.valid then
      service_crane_machines(entry)
    else
      storage.cranes[unit_number] = nil
    end
  end
end)

-- ========================= crane GUI =========================

local function open_crane_gui(player, entry)
  -- Open the REAL 4-slot container so the player gets native filtered slots
  -- (count, faint filter-icon background, middle-click to set a filter). Slots
  -- 1/2 = input lanes, 3/4 = output lanes; filter 3/4 to pick each output lane's
  -- item. collect_outputs honours those filters.
  local bin = entry.parts.bin
  if bin and bin.valid then
    player.opened = bin
  end
end

script.on_event("nullarbor-crane-open", function(event)
  local player = game.get_player(event.player_index)
  local selected = player and player.selected
  if selected and selected.valid and selected.name == CRANE then
    local entry = storage.cranes[selected.unit_number]
    if entry then
      open_crane_gui(player, entry)
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  -- Mining wagon closed: tear down its relative fuel bar.
  if storage.mining_wagon_guis and storage.mining_wagon_guis[event.player_index] then
    storage.mining_wagon_guis[event.player_index] = nil
    local player = game.get_player(event.player_index)
    local frame = player and player.gui.relative[MINING_WAGON_GUI]
    if frame and frame.valid then
      frame.destroy()
    end
  end
end)

-- ========================= build / removal =========================

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end
  if entity.name == GANTRY then
    on_gantry_built(entity)
  elseif entity.name == CRANE then
    on_crane_built(entity)
  elseif entity.name == MINING_WAGON then
    register_mining_wagon(entity)
  elseif entity.type == "solar-panel" and entity.surface.name == "nullarbor" then
    register_solar_panel(entity)
  end
end

local build_filter = {
  { filter = "name", name = GANTRY },
  { filter = "name", name = CRANE },
  { filter = "name", name = MINING_WAGON },
  { filter = "type", type = "solar-panel" },
}
script.on_event(defines.events.on_built_entity, on_built, build_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, build_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, build_filter)
script.on_event(defines.events.script_raised_built, on_built, build_filter)
script.on_event(defines.events.script_raised_revive, on_built, build_filter)

-- Covers every removal path: mined by hand or robot, killed, script-destroyed.
script.on_event(defines.events.on_object_destroyed, function(event)
  local gantry = storage.gantries[event.useful_id]
  if gantry then
    storage.gantries[event.useful_id] = nil
    if gantry.bin.valid then
      gantry.bin.destroy()
    end
    for _, rec in ipairs(gantry.loaders) do
      if rec.entity.valid then
        rec.entity.destroy()
      end
    end
    return
  end
  local crane = storage.cranes[event.useful_id]
  if crane then
    storage.cranes[event.useful_id] = nil
    for _, part in pairs(crane.parts) do
      if part.valid then
        part.destroy()
      end
    end
    return
  end
  -- A mining wagon was removed: destroy its persistent hidden drill.
  local mining = storage.mining_wagons[event.useful_id]
  if mining then
    storage.mining_wagons[event.useful_id] = nil
    if mining.drill and mining.drill.valid then
      mining.drill.destroy()
    end
    return
  end
  -- A resolved swarmer died or morphed: drop its tracking entry.
  if storage.morphs[event.useful_id] then
    storage.morphs[event.useful_id] = nil
  end
  -- An intermediate died (killed mid-windup, or completed by us): cancel any
  -- pending completion so it isn't finalised after death.
  if storage.morphing[event.useful_id] then
    storage.morphing[event.useful_id] = nil
  end
end)

-- Rotation reorients the gantry: rebuild its loaders for the new axis,
-- carrying the bin contents over.
script.on_event(defines.events.on_player_rotated_entity, function(event)
  local entity = event.entity
  if entity.valid and entity.name == CRANE then
    local entry = storage.cranes[entity.unit_number]
    if entry then
      try_rotate_crane(entry)
    end
    return
  end
  if not (entity.valid and entity.name == GANTRY) then
    return
  end
  local entry = storage.gantries[entity.unit_number]
  if not entry then
    return
  end
  for _, rec in ipairs(entry.loaders) do
    if rec.entity.valid then
      rec.entity.destroy()
    end
  end
  local old_bin = entry.bin
  entry.bin, entry.loaders = create_gantry_parts(entity)
  if old_bin.valid then
    local old_inventory = old_bin.get_inventory(defines.inventory.chest)
    local new_inventory = entry.bin.get_inventory(defines.inventory.chest)
    for i = 1, #old_inventory do
      local stack = old_inventory[i]
      if stack.valid_for_read then
        local inserted = new_inventory.insert(stack)
        if inserted < stack.count then
          entity.surface.spill_item_stack({
            position = entity.position,
            stack = { name = stack.name, count = stack.count - inserted, quality = stack.quality },
          })
        end
      end
    end
    old_bin.destroy()
  end
end)

-- ========================= bestiary morphing =========================

-- Each morph outcome: the intermediate the swarmer becomes immediately, the
-- final form it completes into, and the windup between them.
local MORPH_TARGETS = {
  bruiser = { intermediate = MORPHING_BRUISER, final = BRUISER, ticks = BRUISER_MORPH_TICKS },
  exploder = { intermediate = MORPHING_EXPLODER, final = EXPLODER, ticks = EXPLODER_MORPH_TICKS },
}

-- Begin a morph: the swarmer becomes its intermediate form now; control
-- completes it to the final form after the windup. The intermediate is a
-- normal killable unit -- destroying it before completion cancels the morph,
-- which is the player's reaction-window reward. Tracked by the intermediate's
-- unit_number in storage.morphing.
local function begin_morph(swarmer, spec)
  local intermediate = swarmer.surface.create_entity({
    name = spec.intermediate,
    position = swarmer.position,
    force = swarmer.force,
  })
  swarmer.destroy()
  if intermediate then
    storage.morphing[intermediate.unit_number] = {
      entity = intermediate,
      final = spec.final,
      complete_tick = game.tick + spec.ticks,
    }
    script.register_on_object_destroyed(intermediate)
  end
end

-- Complete due morphs: replace each finished intermediate with its final form.
-- Clearing the storage entry before destroying the intermediate keeps the
-- on_object_destroyed cleanup a no-op for our own removal. A distinct period
-- from the other timers so none overwrites another.
script.on_nth_tick(10, function()
  local now = game.tick
  for id, m in pairs(storage.morphing) do
    if now >= m.complete_tick then
      storage.morphing[id] = nil
      if m.entity.valid then
        local final = m.entity.surface.create_entity({
          name = m.final,
          position = m.entity.position,
          force = m.entity.force,
        })
        if final then
          register_hunter(final)
        end
        m.entity.destroy()
      end
    end
  end
end)

-- Engagement poll. Bounded to swarmers near connected players (the only
-- targets that exist pre-emergence); each swarmer is evaluated at most once,
-- tracked by unit_number in storage.morphs. A distinct period from the crane
-- GUI's on_nth_tick(15) so neither overwrites the other.
script.on_nth_tick(20, function()
  local resolved = storage.morphs
  for _, player in pairs(game.connected_players) do
    local surface = player.surface
    local swarmers = surface.find_entities_filtered({
      name = SWARMER,
      position = player.position,
      radius = MORPH_SCAN_RADIUS,
    })
    for _, swarmer in pairs(swarmers) do
      local id = swarmer.unit_number
      if not resolved[id] then
        -- "Engaged" = a hostile (player-force) target is within range.
        local target = surface.find_nearest_enemy({
          position = swarmer.position,
          max_distance = MORPH_ENGAGE_RANGE,
          force = swarmer.force,
        })
        if target then
          resolved[id] = true
          -- Registered so the resolved entry is cleaned up on death/morph.
          script.register_on_object_destroyed(swarmer)
          local roll = math.random()
          if roll < MORPH_CHANCE_BRUISER then
            begin_morph(swarmer, MORPH_TARGETS.bruiser)
          elseif roll < MORPH_CHANCE_BRUISER + MORPH_CHANCE_EXPLODER then
            begin_morph(swarmer, MORPH_TARGETS.exploder)
          end
          -- else: stays a swarmer; resolved so it never re-rolls.
        end
      end
    end
  end
end)

-- ========================= pollution effects =========================

-- Nullarbor's pollution ("smog") is a defensive substance the player cultivates,
-- but it has industrial costs, applied per-surface here so Nauvis is untouched.
-- Pollution is stored per 32x32 chunk, so get_pollution(position) is a
-- chunk-granular sample -- fine, that's the resolution the design calls for.
local NULLARBOR = "nullarbor"
local CONDENSER = "nullarbor-condenser"
-- Per-chunk pollution at or above which a condenser stalls completely (design:
-- "pollution disables condensers", forcing water infrastructure into pristine
-- terrain). Placeholder, needs balancing.
local CONDENSER_POLLUTION_CUTOFF = 15

-- Shown in the condenser's GUI (red diode + reason) while pollution has stalled
-- it, instead of the bare engine "Disabled" that active=false gives on its own.
local CONDENSER_SMOG_STATUS = {
  diode = defines.entity_status_diode.red,
  label = { "nullarbor.condenser-smog-disabled" },
}

-- Toggle every Nullarbor condenser on/off by the pollution over its chunk.
-- A disabled condenser stops crafting (and, consuming no power, stops emitting),
-- re-enabling automatically once its chunk clears. Scans by name once a second;
-- condensers are few and pollution drifts slowly, so a periodic scan is cheap
-- enough without a registry. Only writes on a state change so the custom status
-- (and its GUI) don't churn every cycle.
script.on_nth_tick(60, function()
  local surface = game.surfaces[NULLARBOR]
  if not surface then
    return
  end
  for _, condenser in pairs(surface.find_entities_filtered({ name = CONDENSER })) do
    local should_run = surface.get_pollution(condenser.position) < CONDENSER_POLLUTION_CUTOFF
    if should_run ~= condenser.active then
      condenser.active = should_run
      condenser.custom_status = should_run and nil or CONDENSER_SMOG_STATUS
    end
  end
end)

-- ---- solar tiering ----
-- Nullarbor is permanent-day, so solar carries the base load -- but local
-- pollution throttles it. Each panel is fast-replaced between the vanilla panel
-- and two reduced-production clones by the pollution over its chunk. Panels are
-- tracked in storage.solar_panels (an array of entity refs) populated on build
-- and seeded once on config change; the periodic pass compacts out invalids.
local SOLAR_MILD = "nullarbor-solar-panel-mild-smog"
local SOLAR_HEAVY = "nullarbor-solar-panel-heavy-smog"
local SOLAR_BASE = "solar-panel"
-- Per-chunk pollution boundaries between tiers, with hysteresis: a panel rises
-- a tier at the UP threshold but only falls back once pollution drops under the
-- lower DOWN threshold, so a chunk hovering on a boundary doesn't flip every
-- pass. DOWN < UP for each pair. Placeholders, need balancing.
local SOLAR_MILD_UP = 15
local SOLAR_MILD_DOWN = 10
local SOLAR_HEAVY_UP = 40
local SOLAR_HEAVY_DOWN = 33

-- Resolve the tier a panel should be at, given its current tier (its name) and
-- the pollution over its chunk. Clear up/down cases fire first; in the gaps the
-- panel holds its current tier (that hold IS the hysteresis). Big jumps across
-- two tiers are allowed (e.g. a pollution spike takes base straight to heavy).
local function resolve_solar_name(current, pollution)
  if pollution >= SOLAR_HEAVY_UP then
    return SOLAR_HEAVY
  elseif pollution < SOLAR_MILD_DOWN then
    return SOLAR_BASE
  elseif current == SOLAR_HEAVY then
    return pollution < SOLAR_HEAVY_DOWN and SOLAR_MILD or SOLAR_HEAVY
  elseif current == SOLAR_BASE then
    return pollution >= SOLAR_MILD_UP and SOLAR_MILD or SOLAR_BASE
  end
  -- current == SOLAR_MILD, pollution in [MILD_DOWN, HEAVY_UP): hold at mild.
  return SOLAR_MILD
end

-- Fast-replace a panel with its tier variant, carrying position/quality/health
-- over. fast_replace swaps atomically (no power gap) and avoids self-collision;
-- panels aren't circuit-connected, so nothing else needs preserving. Returns
-- the surviving entity (the new one, or the original if creation failed).
local function swap_solar(panel, desired_name)
  local health = panel.health
  local created = panel.surface.create_entity({
    name = desired_name,
    position = panel.position,
    direction = panel.direction,
    force = panel.force,
    quality = panel.quality,
    fast_replace = true,
    spill = false,
    create_build_effect_smoke = false,
  })
  if not created then
    return panel
  end
  created.health = health
  return created
end

-- Assigned to the forward-declared upvalue so the shared build dispatcher can
-- register panels into our array.
register_solar_panel = function(entity)
  storage.solar_panels[#storage.solar_panels + 1] = entity
end

-- Rebuild the registry from a fresh surface scan (existing saves, or a panel
-- placed before this feature existed). Idempotent.
local function seed_solar_registry()
  storage.solar_panels = {}
  local surface = game.surfaces[NULLARBOR]
  if not surface then
    return
  end
  for _, panel in pairs(surface.find_entities_filtered({ type = "solar-panel" })) do
    storage.solar_panels[#storage.solar_panels + 1] = panel
  end
end

-- Re-tier every tracked panel. Pollution drifts slowly, so a 2s cadence is
-- ample; pollution is sampled once per chunk and cached across the pass.
script.on_nth_tick(120, function()
  local surface = game.surfaces[NULLARBOR]
  if not surface then
    return
  end
  local panels = storage.solar_panels
  local kept = {}
  local pollution_by_chunk = {}
  for i = 1, #panels do
    local panel = panels[i]
    if panel.valid then
      local pos = panel.position
      local key = math.floor(pos.x / 32) .. ":" .. math.floor(pos.y / 32)
      local pollution = pollution_by_chunk[key]
      if not pollution then
        pollution = surface.get_pollution(pos)
        pollution_by_chunk[key] = pollution
      end
      local desired = resolve_solar_name(panel.name, pollution)
      if panel.name ~= desired then
        panel = swap_solar(panel, desired)
      end
      kept[#kept + 1] = panel
    end
  end
  storage.solar_panels = kept
end)

-- ========================= emergence =========================

-- Hunter bands emerge from telegraphed sites in pristine loose sand. A site must
-- be a "nullarbor-sand" tile -- which rejects rock AND paving in one test, since
-- both report a different tile name -- and its chunk must be near-pristine. A
-- tremor marker (which also anchors a native custom alert) warns the player for
-- PRECURSOR_TICKS, then the band spawns and marches to the nearest pollution
-- boundary; the engine handles group cohesion/pathing natively.
--
-- Cadence escalates with time since the player first arrived: a grace window of
-- calm, then emergences ramp from rare/small to frequent/large over the ramp
-- period. Pollution-gated site selection means this pressures expansion into
-- pristine sand while a smoggy base stays self-protecting. (Uranium extracted is
-- the intended second escalation input; time-only for now.)
local TREMOR = "nullarbor-emergence-tremor"
-- Number of crack decal variations on the tremor marker; keep in sync with
-- CRACK_VARIATION_COUNT in prototypes/entities/emergence-marker.lua.
local TREMOR_VARIATIONS = 20
local EMERGENCE_SAND = "nullarbor-sand"
local EMERGENCE_CHECK_PERIOD = 90 -- director cadence (ticks)
local EMERGENCE_GRACE = 8 * 60 * 60 -- calm window after arrival (placeholder)
local EMERGENCE_RAMP = 45 * 60 * 60 -- time from grace-end to full intensity
local EMERGENCE_INTERVAL_MAX = 10 * 60 * 60 -- gap between emergences at e=0 (10 min)
local EMERGENCE_INTERVAL_MIN = 5 * 60 * 60 -- gap at e=1 (5 min)
local EMERGENCE_MAX_ACTIVE = 3 -- concurrent telegraphed sites (per-region caps TBD)
-- Telegraph warning window: how long a site stays visible before the band fires.
-- Independent of the emergence interval (which is scheduled from each site's start
-- tick), so lengthening this raises the fraction of time a site is on-screen and
-- shortens the gap after one fires -- without changing how often emergences occur.
local PRECURSOR_TICKS = 2 * 60 * 60
local EMERGENCE_MIN_DIST = 32 -- inner buffer: never site a band closer than this to the player
local EMERGENCE_SEARCH_CHUNKS = 16 -- outward chunk-ring search cap (~512 tiles) -- safety bound, not a design distance
local EMERGENCE_POLLUTION_MAX = 1 -- site chunk must be essentially pristine (outside the cloud, not its fringe)
local BAND_MIN = 4 -- swarmers per band at e=0 (morphing escalates them)
local BAND_MAX = 12 -- at e=1
local EMERGENCE_SPREAD = 3 -- band scatter radius
local EMERGENCE_DUST = "nullarbor-emergence-dust" -- custom large tan dust cloud
local EMERGENCE_DUST_PERIOD = 18 -- ticks between dust puffs per site (unique period; 20 is the morph loop)
local EMERGENCE_DUST_JITTER = 2.5 -- puff offset from the marker centre
local BOUNDARY_THRESHOLD = 20 -- chunk pollution counted as "the cloud"
local BOUNDARY_SEARCH_CHUNKS = 5 -- how far out to look for the boundary
local ALERT_ICON = { type = "virtual", name = "nullarbor-emergence-alert" }

-- Surface-life decay: emerged hunters lose a fraction of their max health each
-- period and are removed at the floor -- the population governor (steady-state
-- count ~ band_size * lifespan / interval). Percentage-of-max gives every unit
-- type a similar lifespan despite very different HP pools. Removal is a quiet
-- destroy(), not damage()/die(), so a decaying exploder never triggers its AOE.
local DECAY_PERIOD = 45 -- ticks (unique among the on_nth_tick periods)
local DECAY_FRACTION = 0.01 -- of max health per period (~1.3%/s -> ~75s lifespan)

-- Escalation in [0,1], or -1 while still in the post-arrival grace window.
local function emergence_escalation()
  local start = storage.nullarbor_start_tick
  if not start then
    return -1
  end
  local past = game.tick - start - EMERGENCE_GRACE
  if past <= 0 then
    return -1
  end
  return math.min(1, past / EMERGENCE_RAMP)
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

-- Every connected player standing on the surface (the alert/site audience).
local function players_on(surface)
  local list = {}
  for _, player in pairs(game.connected_players) do
    if player.surface == surface and player.character then
      list[#list + 1] = player
    end
  end
  return list
end

-- Origin for a new emergence: a random player-force structure (military target --
-- assemblers, furnaces, turrets, etc.; excludes belts/inserters/wires), so bands
-- anchor to the base and can threaten outposts the player isn't standing at. The
-- scan runs only when a new emergence is due (every few minutes), so its cost is
-- amortised. Falls back to a present player before any base structure exists.
local function emergence_origin(surface, players)
  local anchors = surface.find_entities_filtered({ force = "player", is_military_target = true })
  if #anchors > 0 then
    return anchors[math.random(#anchors)].position
  end
  return players[math.random(#players)].position
end

-- Find the *nearest pristine sand* to the player and site the band there, so it
-- emerges just outside the pollution cloud (whatever the cloud's size) and then
-- paths inward to its edge. Expands chunk-ring by chunk-ring from the player's
-- chunk; at the first ring holding any pristine (sub-threshold pollution) sand
-- chunk, picks one at random for directional variety. Only generated chunks are
-- considered, which also caps the work to explored terrain. Returns a tile centre
-- (+0.5), or nil if nothing qualifies within the safety radius (band then wanders).
local EMERGENCE_MIN_DIST_SQ = EMERGENCE_MIN_DIST * EMERGENCE_MIN_DIST
local function pristine_sand_in_chunk(surface, cx, cy, origin)
  local area = { { cx * 32, cy * 32 }, { cx * 32 + 32, cy * 32 + 32 } }
  local sand = surface.find_tiles_filtered({ area = area, name = EMERGENCE_SAND })
  -- Shuffle-free random pick that still respects the inner buffer: scan tiles in
  -- random order, return the first far enough from the player.
  while #sand > 0 do
    local k = math.random(#sand)
    local t = sand[k].position
    local dx, dy = t.x + 0.5 - origin.x, t.y + 0.5 - origin.y
    if dx * dx + dy * dy >= EMERGENCE_MIN_DIST_SQ then
      return { x = t.x + 0.5, y = t.y + 0.5 }
    end
    sand[k] = sand[#sand]
    sand[#sand] = nil
  end
  return nil
end

local function find_emergence_site(surface, origin)
  local ocx, ocy = math.floor(origin.x / 32), math.floor(origin.y / 32)
  for ring = 0, EMERGENCE_SEARCH_CHUNKS do
    -- Collect this ring's pristine sand-bearing chunks (perimeter of the ring box).
    local candidates = {}
    for dcx = -ring, ring do
      for dcy = -ring, ring do
        if math.max(math.abs(dcx), math.abs(dcy)) == ring then
          local cx, cy = ocx + dcx, ocy + dcy
          if
            surface.is_chunk_generated({ cx, cy })
            and surface.get_pollution({ cx * 32 + 16, cy * 32 + 16 }) < EMERGENCE_POLLUTION_MAX
          then
            candidates[#candidates + 1] = { cx = cx, cy = cy }
          end
        end
      end
    end
    -- Try candidates in random order until one yields a valid sand tile.
    while #candidates > 0 do
      local k = math.random(#candidates)
      local c = candidates[k]
      local pos = pristine_sand_in_chunk(surface, c.cx, c.cy, origin)
      if pos then
        return pos
      end
      candidates[k] = candidates[#candidates]
      candidates[#candidates] = nil
    end
  end
  return nil
end

-- Attack-pattern B target: the nearest point on the pollution boundary. Scans
-- chunk centres outward for the closest polluted chunk, then pulls the target
-- back toward the site by half a chunk so the band halts at the cloud's edge
-- (loitering at the frontier) rather than marching into it. nil if no pollution
-- is within range -- the band then just wanders until it decays or finds prey.
local function nearest_boundary_point(surface, site)
  local scx, scy = math.floor(site.x / 32), math.floor(site.y / 32)
  local best, best_d2
  for dcx = -BOUNDARY_SEARCH_CHUNKS, BOUNDARY_SEARCH_CHUNKS do
    for dcy = -BOUNDARY_SEARCH_CHUNKS, BOUNDARY_SEARCH_CHUNKS do
      local center = { x = (scx + dcx) * 32 + 16, y = (scy + dcy) * 32 + 16 }
      if surface.get_pollution(center) >= BOUNDARY_THRESHOLD then
        local dx, dy = center.x - site.x, center.y - site.y
        local d2 = dx * dx + dy * dy
        if not best_d2 or d2 < best_d2 then
          best, best_d2 = center, d2
        end
      end
    end
  end
  if not best then
    return nil
  end
  local dx, dy = site.x - best.x, site.y - best.y
  local len = math.sqrt(dx * dx + dy * dy)
  if len < 1 then
    return best
  end
  return { x = best.x + dx / len * 16, y = best.y + dy / len * 16 }
end

-- Spawn the tremor marker and register the pending emergence. The marker anchors
-- the native alert and is the world telegraph; it is destroyed on fire.
local function start_emergence(surface, pos, band_size)
  local marker = surface.create_entity({ name = TREMOR, position = pos, force = "neutral" })
  if marker then
    marker.destructible = false
    -- Pick a random crack decal (matches CRACK_VARIATION_COUNT in emergence-marker.lua)
    -- so neighbouring emergence sites don't all show the same fracture.
    marker.graphics_variation = math.random(TREMOR_VARIATIONS)
  end
  local fire_tick = game.tick + PRECURSOR_TICKS
  -- Floating countdown over the site; updated on the fast dust cadence and
  -- destroyed at fire. Stored on the entry so it survives save/load.
  local timer = rendering.draw_text({
    text = { "nullarbor.emergence-countdown", math.ceil(PRECURSOR_TICKS / 60) },
    surface = surface,
    target = { x = pos.x, y = pos.y - 1.5 },
    color = { r = 1, g = 0.82, b = 0.35 },
    scale = 2.2,
    alignment = "center",
    vertical_alignment = "middle",
    scale_with_zoom = true,
  })
  storage.emergences[#storage.emergences + 1] = {
    marker = marker,
    position = pos,
    fire_tick = fire_tick,
    band_size = band_size,
    timer = timer,
  }
end

-- Whole seconds until this site fires (never negative).
local function emergence_seconds_left(entry)
  return math.max(0, math.ceil((entry.fire_tick - game.tick) / 60))
end

-- (Re)assert the custom alert on each player; custom alerts fade if not
-- refreshed, so the director re-adds them each cycle. The message carries a live
-- countdown (updated at the 90-tick director cadence). Cleared when the marker is
-- destroyed at fire.
local function refresh_alert(entry, players)
  if not (entry.marker and entry.marker.valid) then
    return
  end
  local secs = emergence_seconds_left(entry)
  for _, player in pairs(players) do
    player.add_custom_alert(entry.marker, ALERT_ICON, { "nullarbor.emergence-warning", secs }, true)
  end
end

-- Spawn the band, enrol each unit in the decay registry, and send the group to
-- the nearest pollution boundary. The marker is destroyed here (clearing the
-- alert).
local function fire_emergence(surface, entry)
  local units = {}
  for _ = 1, entry.band_size do
    local p = surface.find_non_colliding_position(SWARMER, entry.position, EMERGENCE_SPREAD + 2, 0.5)
    if p then
      local unit = surface.create_entity({ name = SWARMER, position = p, force = "enemy" })
      if unit then
        units[#units + 1] = unit
        register_hunter(unit)
      end
    end
  end
  if #units > 0 then
    local group = surface.create_unit_group({ position = entry.position, force = "enemy" })
    for _, unit in pairs(units) do
      group.add_member(unit)
    end
    local target = nearest_boundary_point(surface, entry.position)
    if target then
      group.set_command({
        type = defines.command.attack_area,
        destination = target,
        radius = 16,
        distraction = defines.distraction.by_enemy,
      })
    else
      group.set_command({ type = defines.command.wander, radius = 12, ticks_to_wait = 300 })
    end
  end
  if entry.marker and entry.marker.valid then
    entry.marker.destroy()
  end
  if entry.timer and entry.timer.valid then
    entry.timer.destroy()
  end
end

-- Decay pass: trim each live hunter's health, quietly remove the spent ones, and
-- compact the registry (which also prunes any that died elsewhere).
register_hunter = function(entity)
  storage.hunters[#storage.hunters + 1] = entity
end

script.on_nth_tick(DECAY_PERIOD, function()
  local hunters = storage.hunters
  local kept = {}
  for i = 1, #hunters do
    local hunter = hunters[i]
    if hunter.valid then
      local loss = hunter.max_health * DECAY_FRACTION
      if hunter.health <= loss then
        hunter.destroy()
      else
        hunter.health = hunter.health - loss
        kept[#kept + 1] = hunter
      end
    end
  end
  storage.hunters = kept
end)

script.on_nth_tick(EMERGENCE_CHECK_PERIOD, function()
  local surface = game.surfaces[NULLARBOR]
  if not surface then
    return
  end
  local players = players_on(surface)
  if #players == 0 then
    return
  end
  local now = game.tick
  -- Start the arrival clock the first time a player is present on Nullarbor.
  if not storage.nullarbor_start_tick then
    storage.nullarbor_start_tick = now
  end
  -- Fire due precursors; refresh the alert on the rest.
  local pending = {}
  for _, entry in pairs(storage.emergences) do
    if now >= entry.fire_tick then
      fire_emergence(surface, entry)
    else
      refresh_alert(entry, players)
      pending[#pending + 1] = entry
    end
  end
  storage.emergences = pending
  -- Start a new emergence if past the grace window, cadence, and cap.
  local e = emergence_escalation()
  if e >= 0 and now >= storage.next_emergence_tick and #storage.emergences < EMERGENCE_MAX_ACTIVE then
    local site = find_emergence_site(surface, emergence_origin(surface, players))
    if site then
      start_emergence(surface, site, math.floor(lerp(BAND_MIN, BAND_MAX, e) + 0.5))
      storage.next_emergence_tick = now + lerp(EMERGENCE_INTERVAL_MAX, EMERGENCE_INTERVAL_MIN, e)
      -- Warning klaxon on telegraph (alert_destroyed is the alarm-toned utility
      -- sound; the punchy silo/speaker klaxons aren't reachable via play_sound).
      for _, player in pairs(players) do
        player.play_sound({ path = "utility/alert_destroyed" })
      end
    end
  end
end)

-- Continuous dust over each telegraphed site: a jittered tan puff per site every
-- EMERGENCE_DUST_PERIOD ticks, so the churning ground reads as active while the
-- band brews. Puffs are purely cosmetic (create_trivial_smoke); nothing tracks
-- them. Runs on its own fast cadence, decoupled from the 90-tick director.
script.on_nth_tick(EMERGENCE_DUST_PERIOD, function()
  local emergences = storage.emergences
  if not emergences or #emergences == 0 then
    return
  end
  local surface = game.surfaces[NULLARBOR]
  if not surface then
    return
  end
  local j = EMERGENCE_DUST_JITTER
  for _, entry in pairs(emergences) do
    local pos = entry.position
    surface.create_trivial_smoke({
      name = EMERGENCE_DUST,
      position = { pos.x + (math.random() * 2 - 1) * j, pos.y + (math.random() * 2 - 1) * j },
    })
    -- Tick the floating countdown down on this faster cadence so the seconds
    -- decrement smoothly (the alert message steps on the slower director cadence).
    if entry.timer and entry.timer.valid then
      entry.timer.text = { "nullarbor.emergence-countdown", emergence_seconds_left(entry) }
    end
  end
end)

-- ========================= init =========================

script.on_init(function()
  storage.gantries = {}
  storage.cranes = {}
  storage.crane_hover = {}
  storage.morphs = {}
  storage.morphing = {}
  storage.solar_panels = {}
  storage.emergences = {}
  storage.next_emergence_tick = 0
  storage.hunters = {}
  storage.mining_wagons = {}
  storage.mining_wagon_guis = {}
  storage.mining_wagon_hover = {}
end)

script.on_configuration_changed(function()
  storage.gantries = storage.gantries or {}
  storage.cranes = storage.cranes or {}
  storage.crane_hover = storage.crane_hover or {}
  storage.morphs = storage.morphs or {}
  storage.morphing = storage.morphing or {}
  storage.emergences = storage.emergences or {}
  storage.next_emergence_tick = storage.next_emergence_tick or 0
  storage.hunters = storage.hunters or {}
  storage.mining_wagons = storage.mining_wagons or {}
  storage.mining_wagon_guis = storage.mining_wagon_guis or {}
  storage.mining_wagon_hover = storage.mining_wagon_hover or {}
  -- Rebuild the solar registry from a surface scan so panels placed before this
  -- feature (or in an existing save) are picked up.
  seed_solar_registry()
  -- Drop retired storage from the removed belt-straddling distributor.
  storage.distributors = nil
  storage.pending_builds = nil
  storage.highlight_players = nil
  storage.highlight_objects = nil
  storage.selection_arrows = nil
end)

-- ========================= mining wagon =========================
-- A Mining Wagon (cargo wagon) owns a persistent, hidden, collisionless mining
-- drill created on build. The drill is paused while the train moves and teleported
-- onto the resource + reactivated when the train stops at a station on straight
-- rail; it loads the wagon via drop_target and honours mining productivity/quality
-- natively. Its small burner buffer is topped from the train's locomotive, and a
-- read-only fuel bar on the wagon shows that buffer.

local function is_axis_aligned(orientation)
  for _, a in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
    if math.abs(orientation - a) < 0.02 then
      return true
    end
  end
  return false
end

local function train_locomotives(train)
  local list = {}
  if not train then
    return list
  end
  local movers = train.locomotives
  for _, loco in ipairs(movers.front_movers) do
    list[#list + 1] = loco
  end
  for _, loco in ipairs(movers.back_movers) do
    list[#list + 1] = loco
  end
  return list
end

-- Total fuel energy (J) currently in a locomotive's fuel inventory -- i.e. what
-- the drill can actually pull. Excludes remaining_burning_fuel (already committed
-- to movement). Used to always draw from the fullest loco so all locos drain evenly.
local function loco_fuel_energy(loco)
  local lb = loco.burner
  local linv = lb and lb.inventory
  if not linv then
    return 0
  end
  local energy = 0
  for i = 1, #linv do
    local stack = linv[i]
    if stack.valid_for_read then
      energy = energy + stack.count * prototypes.item[stack.name].fuel_value
    end
  end
  return energy
end

-- Fraction (0..1) of the drill's fuel buffer, for the wagon fuel bar.
local function drill_fuel_fraction(drill)
  local burner = drill.burner
  if not burner then
    return 0
  end
  local energy = burner.remaining_burning_fuel or 0
  local inv = burner.inventory
  if inv and not inv.is_empty() then
    energy = energy + MINING_FUEL_REF
  end
  return math.min(1, energy / MINING_FUEL_REF)
end

-- Top up the drill's single-slot buffer with one fuel item pulled from a train
-- locomotive -- the wagons-per-loco balance lever. Draws from whichever loco
-- currently holds the most fuel, so every loco drains evenly regardless of how
-- the consist interleaves wagons and locomotives (stateless, self-correcting).
local function feed_drill(drill, train)
  local burner = drill.burner
  local inv = burner and burner.inventory
  if not inv or not inv.is_empty() then
    return
  end
  local best_loco, best_energy
  for _, loco in ipairs(train_locomotives(train)) do
    local energy = loco_fuel_energy(loco)
    if energy > 0 and (not best_energy or energy > best_energy) then
      best_loco, best_energy = loco, energy
    end
  end
  if not best_loco then
    return
  end
  local linv = best_loco.burner.inventory
  for i = 1, #linv do
    local stack = linv[i]
    if stack.valid_for_read then
      local moved = inv.insert({ name = stack.name, count = 1, quality = stack.quality })
      if moved > 0 then
        stack.count = stack.count - moved
        return
      end
    end
  end
end

local function refresh_mining_wagon_gui(player_index)
  local rec = storage.mining_wagon_guis[player_index]
  if not rec then
    return
  end
  local entry = storage.mining_wagons[rec.unit_number]
  if entry and entry.drill and entry.drill.valid and rec.bar and rec.bar.valid then
    rec.bar.value = drill_fuel_fraction(entry.drill)
  end
end

local function make_wagon_drill(wagon)
  local drill = wagon.surface.create_entity({
    name = MINING_DRILL,
    position = wagon.position,
    force = wagon.force,
  })
  if drill then
    drill.active = false
    drill.drop_target = wagon
  end
  return drill
end

register_mining_wagon = function(wagon)
  storage.mining_wagons[wagon.unit_number] = { wagon = wagon, drill = make_wagon_drill(wagon) }
  script.register_on_object_destroyed(wagon)
end

-- Deploy on stop at a station (straight rail); pause otherwise.
script.on_event(defines.events.on_train_changed_state, function(event)
  local train = event.train
  local stopped = train.state == defines.train_state.wait_station
  for _, carriage in pairs(train.carriages) do
    if carriage.valid and carriage.name == MINING_WAGON then
      local entry = storage.mining_wagons[carriage.unit_number]
      if entry and entry.drill and entry.drill.valid then
        if stopped and is_axis_aligned(carriage.orientation) then
          entry.drill.teleport(carriage.position)
          entry.drill.drop_target = carriage
          entry.drill.active = true
        else
          entry.drill.active = false
        end
      end
    end
  end
end)

-- Read-only fuel bar, attached under the wagon's inventory window.
script.on_event(defines.events.on_gui_opened, function(event)
  if event.gui_type ~= defines.gui_type.entity then
    return
  end
  -- Distributor: replace the native ag-tower GUI with the bin's native container GUI.
  local opened = event.entity
  if opened and opened.valid and opened.name == CRANE then
    local player = game.get_player(event.player_index)
    local entry = storage.cranes[opened.unit_number]
    if player and entry then
      open_crane_gui(player, entry)
    end
    return
  end
  local wagon = event.entity
  if not (wagon and wagon.valid and wagon.name == MINING_WAGON) then
    return
  end
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  -- Anchor the bar under the wagon's inventory window. Guarded so a missing anchor
  -- type just skips the bar rather than crashing.
  local anchor_gui = defines.relative_gui_type.cargo_wagon_gui
  if not anchor_gui then
    return
  end
  local rel = player.gui.relative
  if rel[MINING_WAGON_GUI] then
    rel[MINING_WAGON_GUI].destroy()
  end
  local frame = rel.add({
    type = "frame",
    name = MINING_WAGON_GUI,
    direction = "vertical",
    caption = { "nullarbor.mining-wagon-fuel" },
    anchor = {
      gui = anchor_gui,
      position = defines.relative_gui_position.bottom,
    },
  })
  local bar = frame.add({ type = "progressbar", name = "bar", value = 0 })
  bar.style.horizontally_stretchable = true
  bar.style.width = 220
  storage.mining_wagon_guis[event.player_index] = { unit_number = wagon.unit_number, bar = bar }
  refresh_mining_wagon_gui(event.player_index)
end)

-- Fuel top-up for active drills + fuel-bar refresh.
script.on_nth_tick(MINING_SERVICE_PERIOD, function()
  for unit_number, entry in pairs(storage.mining_wagons) do
    if entry.wagon and entry.wagon.valid then
      if not (entry.drill and entry.drill.valid) then
        entry.drill = make_wagon_drill(entry.wagon) -- self-heal
      end
      if entry.drill and entry.drill.valid and entry.drill.active then
        feed_drill(entry.drill, entry.wagon.train)
      end
    else
      if entry.drill and entry.drill.valid then
        entry.drill.destroy()
      end
      storage.mining_wagons[unit_number] = nil
    end
  end
  for player_index in pairs(storage.mining_wagon_guis) do
    refresh_mining_wagon_gui(player_index)
  end
end)

-- Show the mining area while a mining wagon is hovered, using the vanilla drill's
-- per-tile radius marker so it matches a real mining drill's display.
local function clear_mining_hover(player_index)
  local objs = storage.mining_wagon_hover[player_index]
  if objs then
    for _, obj in pairs(objs) do
      if obj.valid then
        obj.destroy()
      end
    end
  end
  storage.mining_wagon_hover[player_index] = nil
end

local function clear_crane_hover(player_index)
  local objs = storage.crane_hover[player_index]
  if objs then
    for _, obj in pairs(objs) do
      if obj.valid then
        obj.destroy()
      end
    end
  end
  storage.crane_hover[player_index] = nil
end

-- Outline each building the distributor services (in its 9x9) while hovered.
local function draw_crane_hover(player, crane)
  local pos = crane.position
  local machines = crane.surface.find_entities_filtered({
    area = {
      { pos.x - CRANE_AREA_HALF, pos.y - CRANE_AREA_HALF },
      { pos.x + CRANE_AREA_HALF, pos.y + CRANE_AREA_HALF },
    },
    type = { "assembling-machine", "furnace" },
  })
  local objs = {}
  for _, machine in pairs(machines) do
    -- Native highlight-box: the standard yellow corner-bracket highlight, shown
    -- only to this player. Destroyed on hover change by clear_crane_hover.
    objs[#objs + 1] = crane.surface.create_entity({
      name = "highlight-box",
      position = machine.position,
      bounding_box = machine.selection_box,
      box_type = "copy",
      render_player_index = player.index,
    })
  end
  return objs
end

script.on_event(defines.events.on_selected_entity_changed, function(event)
  clear_mining_hover(event.player_index)
  clear_crane_hover(event.player_index)
  local player = game.get_player(event.player_index)
  local selected = player and player.selected
  if not (selected and selected.valid) then
    return
  end
  if selected.name == MINING_WAGON then
    local pos = selected.position
    local objs = {}
    for ix = math.floor(pos.x - MINING_AREA_R), math.ceil(pos.x + MINING_AREA_R) do
      for iy = math.floor(pos.y - MINING_AREA_R), math.ceil(pos.y + MINING_AREA_R) do
        local tcx, tcy = ix + 0.5, iy + 0.5
        if math.abs(tcx - pos.x) <= MINING_AREA_R and math.abs(tcy - pos.y) <= MINING_AREA_R then
          objs[#objs + 1] = rendering.draw_sprite({
            sprite = "nullarbor-mining-radius-viz",
            target = { tcx, tcy },
            surface = selected.surface,
            players = { player },
            render_layer = "radius-visualization",
            tint = { r = 1, g = 1, b = 1, a = 0.1 },
          })
        end
      end
    end
    storage.mining_wagon_hover[event.player_index] = objs
  elseif selected.name == CRANE then
    storage.crane_hover[event.player_index] = draw_crane_hover(player, selected)
  end
end)
