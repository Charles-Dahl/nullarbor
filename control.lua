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

local GANTRY = "nullarbor-gantry"
local GANTRY_LOADER = "nullarbor-gantry-loader"
local GANTRY_BIN_NS = "nullarbor-gantry-bin-ns"
local GANTRY_BIN_EW = "nullarbor-gantry-bin-ew"

local CRANE = "nullarbor-distributor-crane"
local CRANE_LOADER = "nullarbor-crane-loader"
local CRANE_IN_BIN = "nullarbor-crane-input-bin"
local CRANE_OUT_BIN = "nullarbor-crane-output-bin"
local CRANE_RADIUS = 4
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

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == CRANE_GUI then
    event.element.destroy()
    storage.crane_guis[event.player_index] = nil
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
  elseif entity.type == "solar-panel" and entity.surface.name == "nullarbor" then
    register_solar_panel(entity)
  end
end

local build_filter = {
  { filter = "name", name = GANTRY },
  { filter = "name", name = CRANE },
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
local EMERGENCE_SAND = "nullarbor-sand"
local EMERGENCE_CHECK_PERIOD = 90 -- director cadence (ticks)
local EMERGENCE_GRACE = 8 * 60 * 60 -- calm window after arrival (placeholder)
local EMERGENCE_RAMP = 45 * 60 * 60 -- time from grace-end to full intensity
local EMERGENCE_INTERVAL_MAX = 5 * 60 * 60 -- gap between emergences at e=0
local EMERGENCE_INTERVAL_MIN = 40 * 60 -- gap at e=1
local EMERGENCE_MAX_ACTIVE = 3 -- concurrent telegraphed sites (per-region caps TBD)
local PRECURSOR_TICKS = 8 * 60 -- telegraph warning window
local EMERGENCE_MIN_DIST = 32 -- ring around the player to site within
local EMERGENCE_MAX_DIST = 80
local EMERGENCE_SITE_ATTEMPTS = 12 -- random probes before giving up this cycle
local EMERGENCE_POLLUTION_MAX = 5 -- site chunk must be under this pollution
local BAND_MIN = 4 -- swarmers per band at e=0 (morphing escalates them)
local BAND_MAX = 12 -- at e=1
local EMERGENCE_SPREAD = 3 -- band scatter radius
local BOUNDARY_THRESHOLD = 20 -- chunk pollution counted as "the cloud"
local BOUNDARY_SEARCH_CHUNKS = 5 -- how far out to look for the boundary
local ALERT_ICON = { type = "virtual", name = "signal-red" }

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

-- Probe random points in a ring around the origin for a valid, near-pristine
-- sand tile. Tiles are sampled at their centre (+0.5).
local function find_emergence_site(surface, origin)
  for _ = 1, EMERGENCE_SITE_ATTEMPTS do
    local angle = math.random() * 2 * math.pi
    local dist = EMERGENCE_MIN_DIST + math.random() * (EMERGENCE_MAX_DIST - EMERGENCE_MIN_DIST)
    local pos = {
      x = math.floor(origin.x + math.cos(angle) * dist) + 0.5,
      y = math.floor(origin.y + math.sin(angle) * dist) + 0.5,
    }
    if surface.get_tile(pos.x, pos.y).name == EMERGENCE_SAND and surface.get_pollution(pos) < EMERGENCE_POLLUTION_MAX then
      return pos
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
  end
  storage.emergences[#storage.emergences + 1] = {
    marker = marker,
    position = pos,
    fire_tick = game.tick + PRECURSOR_TICKS,
    band_size = band_size,
  }
end

-- (Re)assert the custom alert on each player; custom alerts fade if not
-- refreshed, so the director re-adds them each cycle. Cleared when the marker is
-- destroyed at fire.
local function refresh_alert(entry, players)
  if not (entry.marker and entry.marker.valid) then
    return
  end
  for _, player in pairs(players) do
    player.add_custom_alert(entry.marker, ALERT_ICON, { "nullarbor.emergence-warning" }, true)
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
    local site = find_emergence_site(surface, players[math.random(#players)].position)
    if site then
      start_emergence(surface, site, math.floor(lerp(BAND_MIN, BAND_MAX, e) + 0.5))
      storage.next_emergence_tick = now + lerp(EMERGENCE_INTERVAL_MAX, EMERGENCE_INTERVAL_MIN, e)
      for _, player in pairs(players) do
        player.play_sound({ path = "utility/new_objective" })
      end
    end
  end
end)

-- ========================= init =========================

script.on_init(function()
  storage.gantries = {}
  storage.cranes = {}
  storage.crane_guis = {}
  storage.morphs = {}
  storage.morphing = {}
  storage.solar_panels = {}
  storage.emergences = {}
  storage.next_emergence_tick = 0
  storage.hunters = {}
end)

script.on_configuration_changed(function()
  storage.gantries = storage.gantries or {}
  storage.cranes = storage.cranes or {}
  storage.crane_guis = storage.crane_guis or {}
  storage.morphs = storage.morphs or {}
  storage.morphing = storage.morphing or {}
  storage.emergences = storage.emergences or {}
  storage.next_emergence_tick = storage.next_emergence_tick or 0
  storage.hunters = storage.hunters or {}
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
