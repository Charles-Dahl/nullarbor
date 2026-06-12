local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")

local icon_tint = { r = 1.0, g = 0.78, b = 0.5, a = 1.0 }

local function hand_sprites()
  return {
    hand_base_picture = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-base.png",
      priority = "extra-high",
      width = 32,
      height = 136,
      scale = 0.25,
    },
    hand_closed_picture = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-closed.png",
      priority = "extra-high",
      width = 72,
      height = 164,
      scale = 0.25,
    },
    hand_open_picture = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-open.png",
      priority = "extra-high",
      width = 72,
      height = 164,
      scale = 0.25,
    },
    hand_base_shadow = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-base-shadow.png",
      priority = "extra-high",
      width = 32,
      height = 132,
      scale = 0.25,
    },
    hand_closed_shadow = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-closed-shadow.png",
      priority = "extra-high",
      width = 72,
      height = 164,
      scale = 0.25,
    },
    hand_open_shadow = {
      filename = "__base__/graphics/entity/burner-inserter/burner-inserter-hand-open-shadow.png",
      priority = "extra-high",
      width = 72,
      height = 164,
      scale = 0.25,
    },
  }
end

-- The primary sits centered on the seam between the two covered belt tiles.
-- Its own arm picks from the back tile and drops to the left of the belt
-- axis; control.lua spawns three hidden arms for the other three
-- pickup-tile/drop-side combinations.
local primary = {
  type = "inserter",
  name = "nullarbor-distributor",
  icons = { { icon = "__base__/graphics/icons/burner-inserter.png", icon_size = 64, tint = icon_tint } },
  flags = { "placeable-neutral", "placeable-player", "player-creation" },
  minable = { mining_time = 0.2, result = "nullarbor-distributor" },
  max_health = 200,
  corpse = "burner-inserter-remnants",
  dying_explosion = "burner-inserter-explosion",
  resistances = {
    {
      type = "fire",
      percent = 90,
    },
  },
  collision_box = { { -0.4, -0.9 }, { 0.4, 0.9 } },
  -- Custom layer: overlaps belts freely, but blocks another distributor.
  collision_mask = { layers = { ["nullarbor-distributor"] = true } },
  selection_box = { { -0.5, -1 }, { 0.5, 1 } },
  -- Wins selection over the belt underneath, so clicking the footprint
  -- always opens the distributor GUI.
  selection_priority = 60,
  damaged_trigger_effect = hit_effects.entity(),
  -- Inert: the primary never operates (control.lua keeps it inactive); it
  -- is the housing, GUI, and fuel buffer. The four hidden arms do all the
  -- work.
  pickup_position = { 0, 0.5 },
  insert_position = { -2.2, 0.5 },
  energy_per_movement = "7kJ",
  energy_per_rotation = "7kJ",
  energy_source = {
    type = "burner",
    fuel_categories = { "chemical" },
    initial_fuel = "wood",
    initial_fuel_percent = 0.25,
    effectivity = 1,
    -- Deep buffer: hand- or inserter-fed fuel lasts a long session on
    -- belts that never carry fuel. The arms sip from this via script.
    fuel_inventory_size = 3,
    light_flicker = {
      color = { 0, 0, 0 },
      minimum_intensity = 0.6,
      maximum_intensity = 0.95,
    },
    smoke = {
      {
        name = "smoke",
        frequency = 10,
        position = { 0.3, -0.3 },
        starting_vertical_speed = 0.08,
        starting_frame_deviation = 60,
      },
    },
  },
  extension_speed = 0.1,
  rotation_speed = 0.04,
  allow_burner_leech = true,
  filter_count = 5,
  -- The native hover arrow points diagonally (entity center sits on the tile
  -- seam, drop is offset half a tile along the axis); control.lua renders
  -- arrows for all four drops instead.
  draw_inserter_arrow = false,
  icon_draw_specification = { scale = 0.5 },
  impact_category = "metal",
  open_sound = sounds.inserter_open,
  close_sound = sounds.inserter_close,
  working_sound = sounds.inserter_fast,
  -- Vanilla 1x2 loader housing; use y = 64 for the direction-out row of the
  -- sheet if the openings read backwards.
  platform_picture = {
    sheet = {
      filename = "__base__/graphics/entity/loader/loader-structure.png",
      priority = "extra-high",
      width = 64,
      height = 64,
    },
  },
}

-- Hidden helper arm: no collision, not selectable, lifecycle and settings
-- managed by control.lua. Picks from the belt tile it stands on and drops
-- to the left of its facing; control.lua rotates instances to cover both
-- sides of both tiles.
local arm = {
  type = "inserter",
  name = "nullarbor-distributor-arm",
  icons = { { icon = "__base__/graphics/icons/burner-inserter.png", icon_size = 64, tint = icon_tint } },
  flags = {
    "placeable-off-grid",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "not-selectable-in-game",
    "hide-alt-info",
    "not-flammable",
    "not-upgradable",
    "not-in-kill-statistics",
  },
  max_health = 50,
  collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
  collision_mask = { layers = {} },
  -- The arm sits on the belt edge facing its drop side: the belt tile is
  -- directly behind it, the drop target 1.7 ahead (the second tile out
  -- from the belt, long-inserter reach).
  pickup_position = { 0, 0.5 },
  insert_position = { 0, -1.7 },
  energy_per_movement = "7kJ",
  energy_per_rotation = "7kJ",
  energy_source = {
    type = "burner",
    fuel_categories = { "chemical" },
    initial_fuel = "wood",
    initial_fuel_percent = 0.25,
    effectivity = 1,
    fuel_inventory_size = 1,
  },
  extension_speed = 0.1,
  rotation_speed = 0.04,
  allow_burner_leech = true,
  filter_count = 5,
  working_sound = sounds.inserter_fast,
}

-- Only the arms render hands; the primary is a static housing.
for k, v in pairs(hand_sprites()) do
  arm[k] = v
end

data:extend({
  {
    type = "collision-layer",
    name = "nullarbor-distributor",
  },
  primary,
  arm,
})
