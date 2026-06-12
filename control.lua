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

-- An arm facing the same direction as the primary drops to the left of the
-- belt axis; facing the opposite direction drops to the right.
local function arm_specs(primary)
  local dir = primary.direction
  local front = FRONT[dir]
  local pos = primary.position
  local back_tile = { x = pos.x - front.x * 0.5, y = pos.y - front.y * 0.5 }
  local front_tile = { x = pos.x + front.x * 0.5, y = pos.y + front.y * 0.5 }
  return {
    { position = back_tile, direction = OPPOSITE[dir] },
    { position = front_tile, direction = dir },
    { position = front_tile, direction = OPPOSITE[dir] },
  }
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
local function set_custom_status(entity, invalid)
  pcall(function()
    if invalid then
      entity.custom_status = {
        diode = defines.entity_status_diode.red,
        label = { "nullarbor.distributor-status-no-belt" },
      }
    else
      entity.custom_status = nil
    end
  end)
end

local function apply_validity(entry)
  local primary = entry.primary
  local valid = placement_valid(primary.surface, primary.position, primary.direction)
  primary.active = valid
  for _, arm in ipairs(entry.arms) do
    if arm.valid then
      arm.active = valid
    end
  end
  set_custom_status(primary, not valid)
  return valid
end

-- ========================= hover indication =========================

-- The primary's native arrow is suppressed in the prototype (it points
-- diagonally because the entity center sits on the tile seam), so render
-- perpendicular arrows for all four drops plus pickup markers on the two
-- covered belt tiles while a player has the distributor selected.
local function clear_arrows(player_index)
  storage.selection_arrows = storage.selection_arrows or {}
  local arrows = storage.selection_arrows[player_index]
  if arrows then
    for _, arrow in pairs(arrows) do
      if arrow.valid then
        arrow.destroy()
      end
    end
    storage.selection_arrows[player_index] = nil
  end
end

local function draw_arrows(player_index, entry)
  local arrows = {}
  local inserters = { entry.primary }
  for _, arm in ipairs(entry.arms) do
    inserters[#inserters + 1] = arm
  end
  for _, inserter in ipairs(inserters) do
    if inserter.valid then
      arrows[#arrows + 1] = rendering.draw_sprite({
        sprite = "utility/indication_arrow",
        -- Every arm drops to the left of its facing.
        orientation = (inserter.orientation - 0.25) % 1,
        target = inserter.drop_position,
        surface = inserter.surface,
        players = { player_index },
        render_layer = "arrow",
      })
    end
  end
  local primary = entry.primary
  if primary.valid then
    local front = FRONT[primary.direction]
    local pos = primary.position
    for _, offset in ipairs({ -0.5, 0.5 }) do
      arrows[#arrows + 1] = rendering.draw_sprite({
        sprite = "utility/indication_line",
        orientation = primary.orientation,
        target = { x = pos.x + front.x * offset, y = pos.y + front.y * offset },
        surface = primary.surface,
        players = { player_index },
        render_layer = "arrow",
      })
    end
  end
  storage.selection_arrows[player_index] = arrows
end

script.on_event(defines.events.on_selected_entity_changed, function(event)
  clear_arrows(event.player_index)
  local player = game.get_player(event.player_index)
  local selected = player and player.selected
  if selected and selected.valid and selected.name == DISTRIBUTOR then
    local entry = storage.distributors[selected.unit_number]
    if entry then
      draw_arrows(event.player_index, entry)
    end
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
  if not entry then
    return
  end
  storage.distributors[event.useful_id] = nil
  for _, arm in ipairs(entry.arms) do
    if arm.valid then
      arm.destroy()
    end
  end
end)

-- Rotation reorients the whole cluster: rebuild the arms for the new axis,
-- salvaging their fuel into the primary's buffer.
script.on_event(defines.events.on_player_rotated_entity, function(event)
  local entity = event.entity
  if not (entity.valid and entity.name == DISTRIBUTOR) then
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
  for _, player in pairs(game.connected_players) do
    if player.selected == entity then
      clear_arrows(player.index)
      draw_arrows(player.index, entry)
    end
  end
end)

-- ========================= settings sync =========================

script.on_event(defines.events.on_gui_closed, function(event)
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
    -- Native green corner brackets, same style as electric-coverage
    -- highlights when holding a power pole.
    objects[#objects + 1] = surface.create_entity({
      name = "highlight-box",
      position = { tile.x + 0.5, tile.y + 0.5 },
      bounding_box = { { tile.x, tile.y }, { tile.x + 1, tile.y + 1 } },
      box_type = "electricity",
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
  storage.selection_arrows = {}
  storage.pending_builds = {}
  storage.highlight_players = {}
  storage.highlight_objects = {}
end)

script.on_configuration_changed(function()
  storage.distributors = storage.distributors or {}
  storage.selection_arrows = storage.selection_arrows or {}
  storage.pending_builds = storage.pending_builds or {}
  storage.highlight_players = storage.highlight_players or {}
  storage.highlight_objects = storage.highlight_objects or {}
end)
