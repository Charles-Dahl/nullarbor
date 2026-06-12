local hit_effects = require("__base__/prototypes/entity/hit-effects")

local icon_tint = { r = 1.0, g = 0.78, b = 0.5, a = 1.0 }

-- Placeholder art: six steel chests blown up to 2x2 tiles each, tiled
-- 2 across x 3 along the rail axis to outline the 6x4 footprint.
local function add_chest(layers, gx, gy)
  layers[#layers + 1] = {
    filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
    priority = "extra-high",
    width = 64,
    height = 80,
    scale = 1,
    shift = { gx, gy },
  }
  layers[#layers + 1] = {
    filename = "__base__/graphics/entity/steel-chest/steel-chest-shadow.png",
    priority = "extra-high",
    width = 110,
    height = 46,
    scale = 1,
    shift = { gx + 0.77, gy + 0.5 },
    draw_as_shadow = true,
  }
end

local function gantry_picture(along_x)
  local ys = along_x and { -1, 1 } or { -2, 0, 2 }
  local xs = along_x and { -2, 0, 2 } or { -1, 1 }
  local layers = {}
  -- Top rows first so lower chests draw over the ones behind them.
  for _, gy in ipairs(ys) do
    for _, gx in ipairs(xs) do
      add_chest(layers, gx, gy)
    end
  end
  return { layers = layers }
end

data:extend({
  {
    type = "collision-layer",
    name = "nullarbor-gantry",
  },
  {
    type = "simple-entity-with-owner",
    name = "nullarbor-gantry",
    icons = { { icon = "__base__/graphics/icons/train-stop.png", icon_size = 64, tint = icon_tint } },
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = "nullarbor-gantry" },
    max_health = 400,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    resistances = {
      {
        type = "fire",
        percent = 70,
      },
    },
    -- North = rails running north-south: 4 tiles across the track, 6 along
    -- it. Custom layer: overlaps rails and belts, blocks other gantries.
    -- Free single-tile placement: wagons sit on a 7-tile pitch, so
    -- per-wagon gantries can't live on the rail grid; positioning over
    -- rails is a validation concern (and rail-less placement is legal —
    -- the gantry then works as a belt balancer).
    collision_box = { { -1.8, -2.8 }, { 1.8, 2.8 } },
    collision_mask = { layers = { ["nullarbor-gantry"] = true } },
    selection_box = { { -2, -3 }, { 2, 3 } },
    damaged_trigger_effect = hit_effects.entity(),
    impact_category = "metal",
    picture = {
      north = gantry_picture(false),
      east = gantry_picture(true),
      south = gantry_picture(false),
      west = gantry_picture(true),
    },
  },
})
