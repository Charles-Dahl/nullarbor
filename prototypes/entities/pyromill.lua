-- Placeholder graphics: the Space Age crusher (also 2x3), tinted warm so it
-- reads as a fiery furnace and is visually distinct from the real crusher.
-- crusher-pictures defines its builder functions globally; require ensures
-- they exist (space-age already loads it for the crusher itself).
require("__space-age__.prototypes.entity.crusher-pictures")

local pyro_tint = { r = 1.0, g = 0.6, b = 0.42 }
local pyro_body = crusher_animation_vertical_main()
pyro_body.tint = pyro_tint

data:extend({
  {
    type = "furnace",
    name = "nullarbor-pyromill",
    icons = { { icon = "__space-age__/graphics/icons/crusher.png", icon_size = 64, tint = pyro_tint } },
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.2, result = "nullarbor-pyromill" },
    max_health = 350,
    corpse = "crusher-remnants",
    dying_explosion = "electric-furnace-explosion",
    allowed_effects = { "speed", "consumption", "pollution" },
    effect_receiver = { uses_module_effects = false, uses_beacon_effects = false, uses_surface_effects = true },
    impact_category = "stone",
    icon_draw_specification = { scale = 0.66, shift = { 0, -0.1 } },
    resistances = {
      {
        type = "fire",
        percent = 90,
      },
      {
        type = "explosion",
        percent = 30,
      },
      {
        type = "impact",
        percent = 30,
      },
    },
    collision_box = { { -0.7, -1.2 }, { 0.7, 1.2 } },
    selection_box = { { -1, -1.5 }, { 1, 1.5 } },
    crafting_categories = { "nullarbor-pyromilling" },
    result_inventory_size = 2,
    energy_usage = "90kW",
    crafting_speed = 1,
    source_inventory_size = 1,
    energy_source = {
      type = "burner",
      fuel_categories = { "chemical" },
      effectivity = 1,
      fuel_inventory_size = 1,
      emissions_per_minute = { pollution = 2 },
      light_flicker = {
        color = { 0, 0, 0 },
        minimum_intensity = 0.6,
        maximum_intensity = 0.95,
      },
      smoke = {
        {
          name = "smoke",
          deviation = { 0.1, 0.1 },
          frequency = 5,
          position = { 0.0, -0.8 },
          starting_vertical_speed = 0.08,
          starting_frame_deviation = 60,
        },
      },
    },
    graphics_set = {
      animation = {
        layers = {
          pyro_body,
          crusher_animation_vertical_shadow(),
        },
      },
      working_visualisations = {
        {
          fadeout = true,
          animation = crusher_working_visualisations_vertical(),
        },
      },
    },
  },
})
