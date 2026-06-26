-- Distributor Crane: a heavy industrial crane that services a cluster of
-- crafting machines within an area radius, handling both input and output
-- from a single structure (see CLAUDE.md "Distributor Crane").
--
-- Implementation: a simple-entity-with-owner shell (the proven gantry
-- pattern) over two hidden 1x1 containers -- a distinct input bin and output
-- bin -- each served by a hidden vanilla loader for direct belt I/O. All
-- building-servicing and the custom two-pane inventory GUI live in
-- control.lua. Nothing is inherited from the agricultural-tower: its native
-- crane AI only harvests plants (it cannot be redirected to buildings, and
-- the arm only animates for harvest ops), its input inventory is seed-
-- filtered, and its status line fought our overrides -- so the shell is fully
-- script-controlled instead.
--
-- Energy: none yet (operates for free). The burner-first fuel layer is a
-- later addition, consistent with the gantry's current state.

local hit_effects = require("__base__/prototypes/entity/hit-effects")

local crane_tint = { r = 0.35, g = 0.36, b = 0.38, a = 1.0 }

local CRANE = "nullarbor-distributor-crane"

-- ----- art: agricultural-tower base sprite, dark-grey tinted ------------
-- Reuse the vanilla ag tower's base animation (the hub/tower body, minus the
-- crane arm, which is a separate engine-driven layer we don't get on a simple
-- entity) and tint it dark grey. The shadow layer is left untinted.
local function crane_animation()
  return {
    layers = {
      util.sprite_load("__space-age__/graphics/entity/agricultural-tower/agricultural-tower-base", {
        priority = "high",
        animation_speed = 0.25,
        frame_count = 64,
        scale = 0.5,
        tint = crane_tint,
      }),
      util.sprite_load("__space-age__/graphics/entity/agricultural-tower/agricultural-tower-base-shadow", {
        priority = "high",
        frame_count = 1,
        repeat_count = 64,
        draw_as_shadow = true,
        scale = 0.5,
      }),
    },
  }
end

-- ----- hidden loader (cloned from vanilla loader-1x1) --------------------
-- Same approach as the gantry: inherit working structure sprites and belt
-- animation, run at the fastest belt tier so it never bottlenecks I/O.
local loader = util.table.deepcopy(data.raw["loader-1x1"]["loader-1x1"])
loader.name = "nullarbor-crane-loader"
loader.hidden = true
loader.flags = {
  "placeable-off-grid",
  "not-on-map",
  "not-blueprintable",
  "not-deconstructable",
  "not-selectable-in-game",
  "hide-alt-info",
  "not-flammable",
  "not-upgradable",
  "not-in-kill-statistics",
}
loader.selectable_in_game = false
loader.minable = nil
loader.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
loader.fast_replaceable_group = nil
loader.next_upgrade = nil
do
  local max_belt_speed = 0
  for _, belt in pairs(data.raw["transport-belt"]) do
    if belt.speed and belt.speed > max_belt_speed then
      max_belt_speed = belt.speed
    end
  end
  if max_belt_speed > 0 then
    loader.speed = max_belt_speed
  end
end

-- ----- hidden 1x1 buffer bins --------------------------------------------
-- Distinct input and output containers so the crane never re-emits its own
-- input (CLAUDE.md: input and output buffers must be separate). Kept real,
-- selectable and non-hidden so loaders will link to them (same constraint
-- the gantry bin documents); made invisible by having no picture. The custom
-- GUI in control.lua surfaces both as labelled panes.
local function crane_bin(name)
  return {
    type = "container",
    name = name,
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 64,
    flags = { "placeable-player", "player-creation", "not-blueprintable", "not-deconstructable" },
    max_health = 200,
    inventory_size = 16,
    collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
  }
end

data:extend({
  loader,
  crane_bin("nullarbor-crane-input-bin"),
  crane_bin("nullarbor-crane-output-bin"),
  {
    type = "custom-input",
    name = "nullarbor-crane-open",
    key_sequence = "",
    linked_game_control = "open-gui",
  },
  {
    type = "simple-entity-with-owner",
    name = CRANE,
    icons = { { icon = "__space-age__/graphics/icons/agricultural-tower.png", icon_size = 64, tint = crane_tint } },
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = CRANE },
    max_health = 400,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    resistances = {
      {
        type = "fire",
        percent = 70,
      },
    },
    -- 3x3 footprint. Blocks overlap with other buildings/water like a normal
    -- structure; the hidden bins/loaders are script-spawned so they bypass
    -- this collision and sit inside the footprint freely.
    collision_box = { { -1.4, -1.4 }, { 1.4, 1.4 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    collision_mask = {
      layers = { item = true, object = true, player = true, water_tile = true, is_object = true, is_lower_object = true },
    },
    -- Win hover over the invisible bins underneath so the shell is the
    -- click/mine target and E opens the custom GUI via the custom input.
    selection_priority = 100,
    damaged_trigger_effect = hit_effects.entity(),
    impact_category = "metal",
    -- The ag tower sprite extends well above its footprint; match vanilla's
    -- extension so the tower isn't clipped.
    drawing_box_vertical_extension = 2.5,
    animations = crane_animation(),
  },
})
