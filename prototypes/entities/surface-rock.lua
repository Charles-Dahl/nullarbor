local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")
local decorative_trigger_effects = require("__base__/prototypes/decorative/decorative-trigger-effects")

data:extend({
  {
    name = "nullarbor-surface-rock",
    type = "simple-entity",
    flags = { "placeable-neutral", "placeable-off-grid" },
    icon = "__base__/graphics/icons/huge-rock.png",
    subgroup = "grass",
    order = "a[decorative]-l[rock]-a[nauvis]-c[huge-rock]",
    collision_box = { { -1.5, -1.1 }, { 1.5, 1.1 } },
    selection_box = { { -1.7, -1.3 }, { 1.7, 1.3 } },
    damaged_trigger_effect = hit_effects.rock(),
    dying_trigger_effect = decorative_trigger_effects.huge_rock(),
    minable = {
      mining_particle = "stone-particle",
      mining_time = 3,
      results = {
        { type = "item", name = "stone", amount_min = 24, amount_max = 50 },
        { type = "item", name = "iron-ore", amount_min = 24, amount_max = 50 },
        { type = "item", name = "solid-fuel", amount_min = 24, amount_max = 50 },
      },
    },

    map_color = { 129, 105, 78 },
    count_as_rock_for_filtered_deconstruction = true,
    mined_sound = sounds.deconstruct_bricks(1.0),
    impact_category = "stone",
    render_layer = "object",
    max_health = 2000,
    resistances = {
      {
        type = "fire",
        percent = 100,
      },
    },
    autoplace = {
      control = "rocks",
      order = "a[doodad]-a[rock]-a[huge]",
      -- Denser than the original Nauvis-style placement and concentrated
      -- around the cliffs: cliff_band peaks in the coastline elevation band
      -- (cliffs form near elevation 80, again at 120), and scatter keeps a
      -- sparser presence elsewhere. Tunable: multiplier (overall density),
      -- the elevation band, and the scatter penalty.
      probability_expression = "multiplier * control * (cliff_band + scatter)",
      local_expressions = {
        multiplier = 0.01,
        control = "control:rocks:size",
        cliff_band = "range_select_base(elevation, 75, 150, 1, 0, 1)",
        scatter = "max(0, rock_density - 1.4)",
      },
    },
    pictures = {
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-05.png",
        width = 201,
        height = 179,
        scale = 0.5,
        shift = { 0.25, 0.0625 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-06.png",
        width = 233,
        height = 171,
        scale = 0.5,
        shift = { 0.429688, 0.046875 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-07.png",
        width = 240,
        height = 192,
        scale = 0.5,
        shift = { 0.398438, 0.03125 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-08.png",
        width = 219,
        height = 175,
        scale = 0.5,
        shift = { 0.148438, 0.132812 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-09.png",
        width = 240,
        height = 208,
        scale = 0.5,
        shift = { 0.3125, 0.0625 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-10.png",
        width = 243,
        height = 190,
        scale = 0.5,
        shift = { 0.1875, 0.046875 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-11.png",
        width = 249,
        height = 185,
        scale = 0.5,
        shift = { 0.398438, 0.0546875 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-12.png",
        width = 273,
        height = 163,
        scale = 0.5,
        shift = { 0.34375, 0.0390625 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-13.png",
        width = 275,
        height = 175,
        scale = 0.5,
        shift = { 0.273438, 0.0234375 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-14.png",
        width = 241,
        height = 215,
        scale = 0.5,
        shift = { 0.195312, 0.0390625 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-15.png",
        width = 318,
        height = 181,
        scale = 0.5,
        shift = { 0.523438, 0.03125 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-16.png",
        width = 217,
        height = 224,
        scale = 0.5,
        shift = { 0.0546875, 0.0234375 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-17.png",
        width = 332,
        height = 228,
        scale = 0.5,
        shift = { 0.226562, 0.046875 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-18.png",
        width = 290,
        height = 243,
        scale = 0.5,
        shift = { 0.195312, 0.0390625 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-19.png",
        width = 349,
        height = 225,
        scale = 0.5,
        shift = { 0.609375, 0.0234375 },
      },
      {
        filename = "__base__/graphics/decorative/huge-rock/huge-rock-20.png",
        width = 287,
        height = 250,
        scale = 0.5,
        shift = { 0.132812, 0.03125 },
      },
    },
  },
})
