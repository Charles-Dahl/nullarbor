-- Distributor: composite of one selectable primary inserter (1x2, sits on a
-- belt) plus three hidden arm inserters. The primary picks from the back
-- covered tile and drops left of the belt axis; the arms cover the other
-- three pickup-tile/drop-side combinations. This script manages arm
-- lifecycle, mirrors the primary's filter settings onto the arms, tops the
-- arms' fuel up from the primary's buffer, and enforces the placement rule:
-- the footprint must lie lengthwise along a straight belt run (ghost belts
-- count). Manual placement elsewhere is rejected; a built distributor whose
-- underlay later becomes invalid is disabled with a status instead.

local DISTRIBUTOR = "nullarbor-distributor"
local ARM = "nullarbor-distributor-arm"
local HIGHLIGHT_RADIUS = 32

local GANTRY = "nullarbor-gantry"
local GANTRY_LOADER = "nullarbor-gantry-loader"
local GANTRY_BIN_NS = "nullarbor-gantry-bin-ns"
local GANTRY_BIN_EW = "nullarbor-gantry-bin-ew"

-- Distributor Crane (output-first spike). Agricultural-tower shell + two
-- hidden 1x1 buffer bins, each served by a hidden loader on the south face;
-- belts approach from the south. The crane services every crafting machine
-- within CRANE_RADIUS, pulling their output slots into the output bin, which
-- the output loader empties to the belt. Input servicing is a later layer.
local CRANE = "nullarbor-distributor-crane"
local CRANE_LOADER = "nullarbor-crane-loader"
local CRANE_IN_BIN = "nullarbor-crane-input-bin"
local CRANE_OUT_BIN = "nullarbor-crane-output-bin"
local CRANE_RADIUS = 4
-- Keep each serviced machine topped up to this many of every item it accepts
-- (ingredients and burner fuel). Placeholder value, needs balancing.
local CRANE_INPUT_TARGET = 10

-- Unit vector along each direction, used to find the two covered belt tiles
-- relative to the primary's position (which sits on the seam between them).
local FRONT = {
  [defines.direction.north] = { x = 0, y = -1 },
  [defines.direction.east] = { x = 1, y = 0 },
  [defines.direction.south] = { x = 0, y = 1 },
  [defines.direction.west] = { x = -1, y = 0 },
}

local OPPOSITE = {
  [defines.direction.north] = defines.direction.south,
  [defines.direction.east] = defines.direction.west,
  [defines.direction.south] = defines.direction.north,
  [defines.direction.west] = defines.direction.east,
}

-- 90° counter-clockwise of each direction: the "left" side of the belt axis.
local LEFT_OF = {
  [defines.direction.north] = defines.direction.west,
  [defines.direction.west] = defines.direction.south,
  [defines.direction.south] = defines.direction.east,
  [defines.direction.east] = defines.direction.north,
}

-- ========================= placement validity =========================

-- The engine curves a belt exactly when it has a single input entering from
-- the side; belt_shape isn't needed.
local function is_curved(belt)
  local inputs = belt.belt_neighbours.inputs
  if #inputs ~= 1 then
    return false
  end
  local d = inputs[1].direction
  return d ~= belt.direction and d ~= OPPOSITE[belt.direction]
end

-- A covered belt must run along the distributor's axis (either way), and a
-- real belt must be straight. Ghost belts can't report curvature (it's
-- derived from built neighbours), so they're checked on direction only.
local function belt_ok(belt, is_ghost, axis_dir)
  if belt.direction ~= axis_dir and belt.direction ~= OPPOSITE[axis_dir] then
    return false
  end
  return is_ghost or not is_curved(belt)
end

local function belt_at(surface, position)
  local real = surface.find_entities_filtered({ position = position, type = "transport-belt", limit = 1 })[1]
  if real then
    return real, false
  end
  local ghost = surface.find_entities_filtered({ position = position, ghost_type = "transport-belt", limit = 1 })[1]
  if ghost then
    return ghost, true
  end
  return nil, false
end

local function placement_valid(surface, position, direction)
  local front = FRONT[direction]
  if not front then
    return false
  end
  local belt_a, ghost_a = belt_at(surface, { x = position.x - front.x * 0.5, y = position.y - front.y * 0.5 })
  local belt_b, ghost_b = belt_at(surface, { x = position.x + front.x * 0.5, y = position.y + front.y * 0.5 })
  if not (belt_a and belt_b) then
    return false
  end
  -- One run, one flow: both belts must agree, not just share the axis.
  if belt_a.direction ~= belt_b.direction then
    return false
  end
  return belt_ok(belt_a, ghost_a, direction) and belt_ok(belt_b, ghost_b, direction)
end

-- ========================= composite lifecycle =========================

-- Four arms, one per covered-tile/side combination, each perched on the
-- belt edge facing its drop side, with the belt tile directly behind it.
local function arm_specs(primary)
  local dir = primary.direction
  local front = FRONT[dir]
  local pos = primary.position
  local left_dir = LEFT_OF[dir]
  local right_dir = OPPOSITE[left_dir]
  local left = FRONT[left_dir]
  local specs = {}
  for _, along in ipairs({ -0.5, 0.5 }) do
    local tile = { x = pos.x + front.x * along, y = pos.y + front.y * along }
    specs[#specs + 1] = {
      position = { x = tile.x + left.x * 0.5, y = tile.y + left.y * 0.5 },
      direction = left_dir,
    }
    specs[#specs + 1] = {
      position = { x = tile.x - left.x * 0.5, y = tile.y - left.y * 0.5 },
      direction = right_dir,
    }
  end
  return specs
end

local function create_arms(primary)
  local arms = {}
  for _, spec in ipairs(arm_specs(primary)) do
    local arm = primary.surface.create_entity({
      name = ARM,
      position = spec.position,
      direction = spec.direction,
      force = primary.force,
      quality = primary.quality,
    })
    arm.destructible = false
    arms[#arms + 1] = arm
  end
  return arms
end

local function sync_settings(entry)
  local primary = entry.primary
  for _, arm in ipairs(entry.arms) do
    if arm.valid then
      arm.use_filters = primary.use_filters
      arm.inserter_filter_mode = primary.inserter_filter_mode
      for i = 1, primary.filter_slot_count do
        arm.set_filter(i, primary.get_filter(i))
      end
    end
  end
end

-- ========================= runtime status =========================

-- pcall: custom_status is a recent API; if unavailable, the native
-- "Disabled by script" status from active = false still shows.
local function set_custom_status(entity, valid)
  pcall(function()
    if valid then
      entity.custom_status = {
        diode = defines.entity_status_diode.green,
        label = { "entity-status.working" },
      }
    else
      entity.custom_status = {
        diode = defines.entity_status_diode.red,
        label = { "nullarbor.distributor-status-no-belt" },
      }
    end
  end)
end

local function apply_validity(entry)
  local primary = entry.primary
  local valid = placement_valid(primary.surface, primary.position, primary.direction)
  -- The primary never operates — it's the housing, GUI, and fuel buffer —
  -- so its status line is script-managed to reflect the cluster's state.
  primary.active = false
  for _, arm in ipairs(entry.arms) do
    if arm.valid then
      arm.active = valid
    end
  end
  set_custom_status(primary, valid)
  return valid
end

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
    drain_bin_to_buffer(crane.parts.input_bin, event.buffer)
    drain_bin_to_buffer(crane.parts.output_bin, event.buffer)
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
local function create_crane_parts(shell)
  local pos = shell.position
  local south = defines.direction.south
  local function make_bin(name, dx)
    local bin = shell.surface.create_entity({
      name = name,
      position = { x = pos.x + dx, y = pos.y },
      force = shell.force,
    })
    bin.destructible = false
    return bin
  end
  local function make_loader(dx, is_input)
    local loader = shell.surface.create_entity({
      name = CRANE_LOADER,
      position = { x = pos.x + dx, y = pos.y + 1 },
      direction = south,
      force = shell.force,
    })
    loader.destructible = false
    loader.loader_type = is_input and "input" or "output"
    return loader
  end
  return {
    input_bin = make_bin(CRANE_IN_BIN, -1),
    output_bin = make_bin(CRANE_OUT_BIN, 1),
    input_loader = make_loader(-1, true),
    output_loader = make_loader(1, false),
  }
end

local function on_crane_built(shell)
  storage.cranes[shell.unit_number] = { shell = shell, parts = create_crane_parts(shell) }
  script.register_on_object_destroyed(shell)
end

-- Pull every serviceable machine's output slots into the output bin.
-- get_output_inventory() is type-agnostic (assembling machines and furnaces
-- alike).
local function collect_outputs(machines, out_bin)
  local out_inv = out_bin.get_inventory(defines.inventory.chest)
  if out_inv.is_full() then
    return
  end
  for _, machine in pairs(machines) do
    local src = machine.get_output_inventory()
    if src then
      for _, item in pairs(src.get_contents()) do
        local inserted = out_inv.insert({ name = item.name, count = item.count, quality = item.quality })
        if inserted > 0 then
          src.remove({ name = item.name, count = inserted, quality = item.quality })
        end
      end
    end
  end
end

-- Push ingredients from the input bin into machines that can use them, keeping
-- each machine topped up to CRANE_INPUT_TARGET of every item it accepts.
-- can_insert gates validity (only a machine's actual recipe ingredients / fuel
-- pass) and insert() routes each item to the right inventory, so this works
-- for furnaces (auto-recipe), assemblers (set recipe), and burner fuel slots
-- without parsing recipes. The distinct input/output bins ensure the crane
-- never re-collects what it just inserted.
local function distribute_inputs(machines, in_bin)
  local in_inv = in_bin.get_inventory(defines.inventory.chest)
  if in_inv.is_empty() then
    return
  end
  for _, machine in pairs(machines) do
    for _, item in pairs(in_inv.get_contents()) do
      local need = CRANE_INPUT_TARGET - machine.get_item_count(item.name)
      -- Probe acceptance with a single item (can_insert is all-or-nothing on
      -- the full count); then insert the capped amount and let insert() take
      -- whatever fits.
      if need > 0 and machine.can_insert({ name = item.name, count = 1, quality = item.quality }) then
        local inserted = machine.insert({ name = item.name, count = math.min(need, item.count), quality = item.quality })
        if inserted > 0 then
          in_inv.remove({ name = item.name, count = inserted, quality = item.quality })
        end
      end
    end
  end
end

-- The crane's own hidden bins/loaders are containers/loaders, so the
-- crafting-machine type filter never picks them up.
local function service_crane(entry)
  local shell = entry.shell
  local out_bin = entry.parts.output_bin
  local in_bin = entry.parts.input_bin
  if not (shell.valid and out_bin.valid and in_bin.valid) then
    return
  end
  local machines = shell.surface.find_entities_filtered({
    position = shell.position,
    radius = CRANE_RADIUS,
    type = { "assembling-machine", "furnace" },
  })
  collect_outputs(machines, out_bin)
  distribute_inputs(machines, in_bin)
end

script.on_nth_tick(30, function()
  for unit_number, entry in pairs(storage.cranes) do
    if entry.shell.valid then
      service_crane(entry)
    else
      storage.cranes[unit_number] = nil
    end
  end
end)

-- ========================= crane GUI =========================

-- A custom window with two labelled panes -- Input and Output -- each a grid
-- of slot buttons mirroring the matching hidden container. The buffers are
-- two genuinely distinct inventories; this GUI is just how the player sees
-- and hand-manages them. Interaction: left-click moves the cursor stack into
-- the pane (or picks a slot's stack up into the cursor); shift+left-click
-- quick-transfers a slot to the player inventory.
local CRANE_GUI = "nullarbor-crane-gui"
local CRANE_BIN_SLOTS = 16

local function build_pane(parent, title, pane_id)
  local pane = parent.add({ type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical" })
  pane.add({ type = "label", style = "caption_label", caption = title })
  local tbl = pane.add({ type = "table", name = "slots", column_count = 4 })
  for i = 1, CRANE_BIN_SLOTS do
    local btn = tbl.add({ type = "sprite-button", name = "slot_" .. i, style = "slot_button" })
    btn.tags = { crane_gui = true, pane = pane_id, slot = i }
  end
  return tbl
end

local function refresh_pane(tbl, bin)
  if not (tbl and tbl.valid and bin.valid) then
    return
  end
  local inv = bin.get_inventory(defines.inventory.chest)
  for i = 1, CRANE_BIN_SLOTS do
    local btn = tbl["slot_" .. i]
    local stack = inv[i]
    if stack.valid_for_read then
      btn.sprite = "item/" .. stack.name
      btn.number = stack.count
      btn.elem_tooltip = { type = "item", name = stack.name }
    else
      btn.sprite = nil
      btn.number = nil
      btn.elem_tooltip = nil
    end
  end
end

local function refresh_crane_gui(player_index)
  local rec = storage.crane_guis[player_index]
  if not rec then
    return
  end
  local entry = storage.cranes[rec.unit_number]
  local player = game.get_player(player_index)
  local frame = player and player.gui.screen[CRANE_GUI]
  if not (entry and entry.shell.valid and frame and frame.valid) then
    if frame and frame.valid then
      frame.destroy()
    end
    storage.crane_guis[player_index] = nil
    return
  end
  refresh_pane(rec.input_table, entry.parts.input_bin)
  refresh_pane(rec.output_table, entry.parts.output_bin)
end

local function open_crane_gui(player, entry)
  local screen = player.gui.screen
  if screen[CRANE_GUI] then
    screen[CRANE_GUI].destroy()
  end
  local frame = screen.add({ type = "frame", name = CRANE_GUI, direction = "vertical" })
  frame.add({
    type = "label",
    style = "frame_title",
    caption = { "entity-name.nullarbor-distributor-crane" },
    ignored_by_interaction = true,
  })
  local body = frame.add({ type = "flow", direction = "horizontal" })
  local input_table = build_pane(body, { "nullarbor.crane-input" }, "input")
  local output_table = build_pane(body, { "nullarbor.crane-output" }, "output")
  frame.auto_center = true
  storage.crane_guis[player.index] = {
    unit_number = entry.shell.unit_number,
    input_table = input_table,
    output_table = output_table,
  }
  player.opened = frame
  refresh_crane_gui(player.index)
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

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.crane_gui) then
    return
  end
  local player = game.get_player(event.player_index)
  local rec = storage.crane_guis[event.player_index]
  local entry = rec and storage.cranes[rec.unit_number]
  if not (player and entry and entry.shell.valid) then
    return
  end
  local bin = element.tags.pane == "input" and entry.parts.input_bin or entry.parts.output_bin
  if not bin.valid then
    return
  end
  local inv = bin.get_inventory(defines.inventory.chest)
  local slot = inv[element.tags.slot]
  local cursor = player.cursor_stack
  if cursor and cursor.valid_for_read then
    -- Putting items down: insert the held stack into this bin.
    local inserted = inv.insert(cursor)
    cursor.count = cursor.count - inserted
  elseif slot.valid_for_read then
    if event.shift then
      -- Quick-transfer the slot to the player's inventory.
      local main = player.get_main_inventory()
      local moved = main and main.insert(slot) or 0
      slot.count = slot.count - moved
    else
      -- Pick the slot's stack up into the cursor.
      player.cursor_stack.transfer_stack(slot)
    end
  end
  refresh_crane_gui(event.player_index)
end)

-- Keep open GUIs in sync as the servicing loop and loaders move items.
script.on_nth_tick(15, function()
  for player_index in pairs(storage.crane_guis) do
    refresh_crane_gui(player_index)
  end
end)

-- ========================= build / removal =========================

local function reject_feedback(player_index)
  local player = game.get_player(player_index)
  if player and player.valid then
    player.create_local_flying_text({
      text = { "nullarbor.distributor-needs-belt" },
      create_at_cursor = true,
    })
    player.play_sound({ path = "utility/cannot_build" })
  end
end

-- Blueprint and blueprint-record pastes are validated one tick later (after
-- the whole paste exists, since entity order within a paste is arbitrary);
-- direct placements are validated immediately in the event, which also
-- works while the tick is paused (the map editor pauses it by default, so
-- on_tick may never run there).
local function is_blueprint_paste(player)
  if player.is_cursor_blueprint() then
    return true
  end
  local ok, record = pcall(function()
    return player.cursor_record
  end)
  return ok and record ~= nil
end

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end
  if entity.name == GANTRY then
    on_gantry_built(entity)
    return
  end
  if entity.name == CRANE then
    on_crane_built(entity)
    return
  end
  storage.pending_builds = storage.pending_builds or {}
  local player = event.player_index and game.get_player(event.player_index)
  local deferred = player and is_blueprint_paste(player)

  if entity.type == "entity-ghost" then
    if not player then
      return
    end
    if deferred then
      storage.pending_builds[#storage.pending_builds + 1] = { ghost = entity, player_index = event.player_index }
    elseif not placement_valid(entity.surface, entity.position, entity.direction) then
      entity.destroy()
      reject_feedback(event.player_index)
    end
    return
  end

  if player and not deferred and not placement_valid(entity.surface, entity.position, entity.direction) then
    -- Drop the starter fuel so repeated place-and-reject can't farm it.
    entity.get_fuel_inventory().clear()
    if not player.mine_entity(entity, true) then
      entity.destroy()
    end
    reject_feedback(event.player_index)
    return
  end

  -- Face the belt's flow so the housing sprite reads consistently; a 180
  -- flip keeps the footprint and changes nothing functional.
  local front = FRONT[entity.direction]
  if front then
    local belt = belt_at(entity.surface, { x = entity.position.x - front.x * 0.5, y = entity.position.y - front.y * 0.5 })
    if belt and belt.direction == OPPOSITE[entity.direction] then
      entity.direction = belt.direction
    end
  end

  local entry = { primary = entity, arms = create_arms(entity) }
  storage.distributors[entity.unit_number] = entry
  script.register_on_object_destroyed(entity)
  -- Bot- and script-built distributors are never rejected; an invalid one
  -- (e.g. revived before its belts) just starts out disabled with a status.
  apply_validity(entry)
  if player and deferred then
    storage.pending_builds[#storage.pending_builds + 1] = { unit_number = entity.unit_number, player_index = event.player_index }
  end
end

local build_filter = {
  { filter = "name", name = DISTRIBUTOR },
  { filter = "ghost_name", name = DISTRIBUTOR },
  { filter = "name", name = GANTRY },
  { filter = "name", name = CRANE },
}
script.on_event(defines.events.on_built_entity, on_built, build_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, build_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, build_filter)
script.on_event(defines.events.script_raised_built, on_built, build_filter)
script.on_event(defines.events.script_raised_revive, on_built, build_filter)

-- Deferred rejection of manual builds (real and ghost).
script.on_event(defines.events.on_tick, function()
  local pending = storage.pending_builds
  if not pending or #pending == 0 then
    return
  end
  storage.pending_builds = {}
  for _, check in ipairs(pending) do
    if check.unit_number then
      local entry = storage.distributors[check.unit_number]
      if entry and entry.primary.valid then
        local primary = entry.primary
        if not placement_valid(primary.surface, primary.position, primary.direction) then
          -- Drop the starter fuel so repeated place-and-reject can't farm it.
          primary.get_fuel_inventory().clear()
          local player = game.get_player(check.player_index)
          if not (player and player.valid and player.mine_entity(primary, true)) then
            primary.destroy()
          end
          -- Arms are cleaned up via on_object_destroyed either way.
          reject_feedback(check.player_index)
        end
      end
    else
      local ghost = check.ghost
      if ghost and ghost.valid then
        if not placement_valid(ghost.surface, ghost.position, ghost.direction) then
          ghost.destroy()
          reject_feedback(check.player_index)
        end
      end
    end
  end
end)

-- Covers every removal path: mined by hand or robot, killed, script-destroyed.
script.on_event(defines.events.on_object_destroyed, function(event)
  local entry = storage.distributors[event.useful_id]
  if entry then
    storage.distributors[event.useful_id] = nil
    for _, arm in ipairs(entry.arms) do
      if arm.valid then
        arm.destroy()
      end
    end
    return
  end
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
  end
end)

-- Rotation reorients the whole cluster: rebuild the arms for the new axis,
-- salvaging their fuel into the primary's buffer.
script.on_event(defines.events.on_player_rotated_entity, function(event)
  local entity = event.entity
  if not entity.valid then
    return
  end
  if entity.name == GANTRY then
    local entry = storage.gantries[entity.unit_number]
    if entry then
      -- Rebuild for the new axis, carrying the bin contents over.
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
    end
    return
  end
  if entity.name ~= DISTRIBUTOR then
    return
  end
  local entry = storage.distributors[entity.unit_number]
  if not entry then
    return
  end
  local primary_fuel = entity.get_fuel_inventory()
  for _, arm in ipairs(entry.arms) do
    if arm.valid then
      local fuel = arm.get_fuel_inventory()
      for i = 1, #fuel do
        local stack = fuel[i]
        if stack.valid_for_read then
          local inserted = primary_fuel.insert(stack)
          if inserted < stack.count then
            entity.surface.spill_item_stack({
              position = entity.position,
              stack = { name = stack.name, count = stack.count - inserted, quality = stack.quality },
            })
          end
        end
      end
      arm.destroy()
    end
  end
  entry.arms = create_arms(entity)
  sync_settings(entry)
  -- Rotating off the belt axis isn't rejected, just disabled with a status.
  apply_validity(entry)
end)

-- ========================= settings sync =========================

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == CRANE_GUI then
    event.element.destroy()
    storage.crane_guis[event.player_index] = nil
    return
  end
  local entity = event.entity
  if entity and entity.valid and entity.name == DISTRIBUTOR then
    local entry = storage.distributors[entity.unit_number]
    if entry then
      sync_settings(entry)
    end
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  local entity = event.destination
  if entity.valid and entity.name == DISTRIBUTOR then
    local entry = storage.distributors[entity.unit_number]
    if entry then
      sync_settings(entry)
    end
  end
end)

-- ========================= periodic upkeep =========================

-- Revalidates the underlay (belts removed, rotated, or still ghosts) and
-- tops up arm fuel. Fuel priority self > targets: arms only get fed when
-- the primary has more than one item to spare; arms also refuel themselves
-- natively from any fuel they pick off the belt.
script.on_nth_tick(60, function()
  for unit_number, entry in pairs(storage.distributors) do
    local primary = entry.primary
    if primary.valid then
      if apply_validity(entry) then
        local primary_fuel = primary.get_fuel_inventory()
        for _, arm in ipairs(entry.arms) do
          if arm.valid then
            local arm_fuel = arm.get_fuel_inventory()
            if arm_fuel.is_empty() then
              for i = 1, #primary_fuel do
                local stack = primary_fuel[i]
                if stack.valid_for_read and stack.count >= 2 then
                  arm_fuel.insert({ name = stack.name, count = 1, quality = stack.quality })
                  stack.count = stack.count - 1
                  break
                end
              end
            end
          end
        end
      end
    else
      storage.distributors[unit_number] = nil
    end
  end
end)

-- ========================= placement highlight =========================

local function holding_distributor(player)
  local stack = player.cursor_stack
  if stack and stack.valid_for_read and stack.name == DISTRIBUTOR then
    return true
  end
  local ghost = player.cursor_ghost
  if ghost then
    local name = ghost.name
    if type(name) ~= "string" then
      name = name.name
    end
    return name == DISTRIBUTOR
  end
  return false
end

local function clear_highlights(player_index)
  storage.highlight_objects = storage.highlight_objects or {}
  local objects = storage.highlight_objects[player_index]
  if objects then
    for _, obj in pairs(objects) do
      if obj.valid then
        obj.destroy()
      end
    end
    storage.highlight_objects[player_index] = nil
  end
end

-- Marks every belt tile that is part of at least one valid slot (a straight,
-- same-direction pair, real or ghost) near the player's view.
local function draw_highlights(player)
  clear_highlights(player.index)
  local surface = player.surface
  local pos = player.position
  local area = {
    { pos.x - HIGHLIGHT_RADIUS, pos.y - HIGHLIGHT_RADIUS },
    { pos.x + HIGHLIGHT_RADIUS, pos.y + HIGHLIGHT_RADIUS },
  }
  local belts = {}
  local function add(entity, is_ghost)
    local key = math.floor(entity.position.x) .. ":" .. math.floor(entity.position.y)
    belts[key] = { entity = entity, ghost = is_ghost }
  end
  for _, entity in pairs(surface.find_entities_filtered({ area = area, type = "transport-belt" })) do
    add(entity, false)
  end
  for _, entity in pairs(surface.find_entities_filtered({ area = area, ghost_type = "transport-belt" })) do
    add(entity, true)
  end

  local marked = {}
  for key, info in pairs(belts) do
    local belt = info.entity
    local dir = belt.direction
    if FRONT[dir] and belt_ok(belt, info.ghost, dir) then
      local x = math.floor(belt.position.x)
      local y = math.floor(belt.position.y)
      local front = FRONT[dir]
      local neighbour_key = (x + front.x) .. ":" .. (y + front.y)
      local neighbour = belts[neighbour_key]
      if neighbour and neighbour.entity.direction == dir and belt_ok(neighbour.entity, neighbour.ghost, dir) then
        marked[key] = { x = x, y = y }
        marked[neighbour_key] = { x = x + front.x, y = y + front.y }
      end
    end
  end

  local objects = {}
  for _, tile in pairs(marked) do
    -- Native green corner brackets (the copy-selection style).
    objects[#objects + 1] = surface.create_entity({
      name = "highlight-box",
      position = { tile.x + 0.5, tile.y + 0.5 },
      bounding_box = { { tile.x, tile.y }, { tile.x + 1, tile.y + 1 } },
      box_type = "copy",
      render_player_index = player.index,
    })
  end
  storage.highlight_objects[player.index] = objects
end

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  storage.highlight_players = storage.highlight_players or {}
  local player = game.get_player(event.player_index)
  if player and player.valid and holding_distributor(player) then
    storage.highlight_players[event.player_index] = true
    -- Draw immediately so the highlight appears even while the tick is
    -- paused; the tick loop only refreshes it as the player moves.
    draw_highlights(player)
  else
    storage.highlight_players[event.player_index] = nil
    clear_highlights(event.player_index)
  end
end)

script.on_nth_tick(12, function()
  local highlighters = storage.highlight_players
  if not (highlighters and next(highlighters)) then
    return
  end
  for player_index in pairs(highlighters) do
    local player = game.get_player(player_index)
    if player and player.valid and holding_distributor(player) then
      draw_highlights(player)
    else
      highlighters[player_index] = nil
      clear_highlights(player_index)
    end
  end
end)

-- ========================= init =========================

script.on_init(function()
  storage.distributors = {}
  storage.gantries = {}
  storage.cranes = {}
  storage.crane_guis = {}
  storage.pending_builds = {}
  storage.highlight_players = {}
  storage.highlight_objects = {}
end)

script.on_configuration_changed(function()
  storage.distributors = storage.distributors or {}
  storage.gantries = storage.gantries or {}
  storage.cranes = storage.cranes or {}
  storage.crane_guis = storage.crane_guis or {}
  -- One-time cleanup of the retired hover-arrow renderings.
  if storage.selection_arrows then
    for _, arrows in pairs(storage.selection_arrows) do
      for _, arrow in pairs(arrows) do
        if arrow.valid then
          arrow.destroy()
        end
      end
    end
    storage.selection_arrows = nil
  end
  storage.pending_builds = storage.pending_builds or {}
  storage.highlight_players = storage.highlight_players or {}
  storage.highlight_objects = storage.highlight_objects or {}
  -- Arm geometry can change between mod versions: rebuild every cluster.
  for unit_number, entry in pairs(storage.distributors) do
    if entry.primary.valid then
      for _, arm in ipairs(entry.arms) do
        if arm.valid then
          arm.destroy()
        end
      end
      entry.arms = create_arms(entry.primary)
      sync_settings(entry)
      apply_validity(entry)
    else
      storage.distributors[unit_number] = nil
    end
  end
end)
