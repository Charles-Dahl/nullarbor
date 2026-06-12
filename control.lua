-- Distributor: composite of one selectable primary inserter (1x2, sits on a
-- belt) plus three hidden arm inserters. The primary picks from the back
-- covered tile and drops left of the belt axis; the arms cover the other
-- three pickup-tile/drop-side combinations. This script manages arm
-- lifecycle, mirrors the primary's filter settings onto the arms, and tops
-- the arms' fuel up from the primary's buffer.

local DISTRIBUTOR = "nullarbor-distributor"
local ARM = "nullarbor-distributor-arm"

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

-- Hover indication: the primary's native arrow is suppressed in the
-- prototype (it points diagonally because the entity center sits on the
-- tile seam), so render perpendicular arrows for all four drops plus
-- pickup markers on the two covered belt tiles while a player has the
-- distributor selected.
local function clear_arrows(player_index)
  -- Lazy init: saves created before this table existed won't necessarily
  -- get on_configuration_changed if the mod version didn't change.
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

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end
  storage.distributors[entity.unit_number] = { primary = entity, arms = create_arms(entity) }
  script.register_on_object_destroyed(entity)
end

local build_filter = { { filter = "name", name = DISTRIBUTOR } }
script.on_event(defines.events.on_built_entity, on_built, build_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, build_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, build_filter)
script.on_event(defines.events.script_raised_built, on_built, build_filter)
script.on_event(defines.events.script_raised_revive, on_built, build_filter)

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
  for _, player in pairs(game.connected_players) do
    if player.selected == entity then
      clear_arrows(player.index)
      draw_arrows(player.index, entry)
    end
  end
end)

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

-- Fuel priority self > targets: arms only get topped up from the primary's
-- buffer when it has more than one item to spare. Arms also refuel
-- themselves natively from any fuel they pick off the belt.
script.on_nth_tick(60, function()
  for unit_number, entry in pairs(storage.distributors) do
    local primary = entry.primary
    if primary.valid then
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
    else
      storage.distributors[unit_number] = nil
    end
  end
end)

script.on_init(function()
  storage.distributors = {}
  storage.selection_arrows = {}
end)

script.on_configuration_changed(function()
  storage.distributors = storage.distributors or {}
  storage.selection_arrows = storage.selection_arrows or {}
end)
