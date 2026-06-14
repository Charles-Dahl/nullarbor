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

-- Belt interface: one hidden 1x1 loader per long-side edge tile (6 per
-- side), cloned from the vanilla hidden loader-1x1 so we inherit working
-- structure sprites and belt animations. control.lua flips each one
-- between input/output/dormant based on the belt outside it.
local loader = util.table.deepcopy(data.raw["loader-1x1"]["loader-1x1"])
loader.name = "nullarbor-gantry-loader"
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
-- Keep the inherited mask: the engine requires loaders to collide with
-- transport belts (that's how they connect). Collision is only checked on
-- player/robot placement, not on script create_entity, so these
-- script-spawned loaders still overlap the shell and each other freely.
loader.fast_replaceable_group = nil
loader.next_upgrade = nil
-- Run at the fastest belt tier in the game (turbo in Space Age) so the
-- loaders never bottleneck the I/O. A faster loader is gated by whatever
-- belt feeds it, so slower belts naturally limit themselves.
local max_belt_speed = 0
for _, belt in pairs(data.raw["transport-belt"]) do
  if belt.speed and belt.speed > max_belt_speed then
    max_belt_speed = belt.speed
  end
end
if max_belt_speed > 0 then
  loader.speed = max_belt_speed
end

-- The shared inventory behind the loaders. Containers can't rotate, so one
-- prototype per footprint axis; invisible, the shell draws the building.
local function gantry_bin(name, half_width, half_height)
  return {
    type = "container",
    name = name,
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 64,
    -- Must stay a real, selectable, non-hidden container: loaders refuse to
    -- link to a hidden / not-selectable container, and player.opened needs
    -- it selectable too. It's made invisible only by having no picture; the
    -- shell draws the building and (via higher selection_priority) is the
    -- hover/mine target, so the bin is rarely clicked directly.
    flags = { "placeable-player", "player-creation", "not-blueprintable", "not-deconstructable" },
    max_health = 200,
    inventory_size = 48,
    collision_box = { { -half_width + 0.1, -half_height + 0.1 }, { half_width - 0.1, half_height - 0.1 } },
    selection_box = { { -half_width, -half_height }, { half_width, half_height } },
  }
end

data:extend({
  {
    type = "collision-layer",
    name = "nullarbor-gantry",
  },
  loader,
  -- Central bins occupying only the inner columns/rows, ADJACENT to the
  -- loaders without overlapping them (a loader links to a container in the
  -- neighbouring tile, like a chest or assembler — not one it sits inside).
  -- NS = 2 wide x 6 long, EW = 6 wide x 2 long.
  gantry_bin("nullarbor-gantry-bin-ns", 1, 3),
  gantry_bin("nullarbor-gantry-bin-ew", 3, 1),
  {
    type = "custom-input",
    name = "nullarbor-gantry-open",
    key_sequence = "",
    linked_game_control = "open-gui",
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
    -- Win hover over the invisible bin underneath, so the shell is the
    -- click/mine target and E opens the bin via the custom input.
    selection_priority = 100,
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
