require("__base__/prototypes/entity/pipecovers")
require("circuit-connector-sprites")
require("__base__/prototypes/entity/assemblerpipes")
local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")

data:extend({
  {
    type = "assembling-machine",
    name = "nullarbor-burner-assembling-machine",
    icon = "__base__/graphics/icons/steel-furnace.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.2, result = "nullarbor-burner-assembling-machine" },
    fast_replaceable_group = "furnace",
    circuit_wire_max_distance = furnace_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions["steel-furnace"],
    max_health = 300,
    corpse = "steel-furnace-remnants",
    dying_explosion = "steel-furnace-explosion",
    impact_category = "metal",
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    allowed_effects = { "speed", "consumption", "pollution" },
    effect_receiver = { uses_module_effects = false, uses_beacon_effects = false, uses_surface_effects = true },
    icon_draw_specification = { scale = 0.66, shift = { 0, -0.1 } },
    working_sound = {
      sound = {
        filename = "__base__/sound/steel-furnace.ogg",
        volume = 0.32,
        advanced_volume_control = { attenuation = "exponential" },
        audible_distance_modifier = 0.5,
      },
      max_sounds_per_prototype = 4,
      fade_in_ticks = 4,
      fade_out_ticks = 20,
    },
    resistances = {
      {
        type = "fire",
        percent = 100,
      },
    },
    collision_box = { { -0.7, -0.7 }, { 0.7, 0.7 } },
    selection_box = { { -0.8, -1 }, { 0.8, 1 } },
    damaged_trigger_effect = hit_effects.entity(),
    crafting_categories = { "nullarbor-crafting", "crafting" },
    result_inventory_size = 1,
    energy_usage = "90kW",
    crafting_speed = 2,
    source_inventory_size = 1,
    energy_source = {
      type = "burner",
      fuel_categories = { "chemical" },
      effectivity = 1,
      emissions_per_minute = { pollution = 4 },
      fuel_inventory_size = 1,
      light_flicker = {
        color = { 0, 0, 0 },
        minimum_intensity = 0.6,
        maximum_intensity = 0.95,
      },
      smoke = {
        {
          name = "smoke",
          frequency = 10,
          position = { 0.7, -1.2 },
          starting_vertical_speed = 0.08,
          starting_frame_deviation = 60,
        },
      },
    },
    graphics_set = {
      animation = {
        layers = {
          {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace.png",
            priority = "high",
            width = 171,
            height = 174,
            shift = util.by_pixel(-1.25, 2),
            scale = 0.5,
          },
          {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace-shadow.png",
            priority = "high",
            width = 277,
            height = 85,
            draw_as_shadow = true,
            shift = util.by_pixel(39.25, 11.25),
            scale = 0.5,
          },
        },
      },
      working_visualisations = {
        {
          fadeout = true,
          effect = "flicker",
          animation = {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace-fire.png",
            priority = "high",
            line_length = 8,
            width = 57,
            height = 81,
            frame_count = 48,
            draw_as_glow = true,
            shift = util.by_pixel(-0.75, 5.75),
            scale = 0.5,
          },
        },
        {
          fadeout = true,
          effect = "flicker",
          animation = {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace-glow.png",
            priority = "high",
            width = 60,
            height = 43,
            draw_as_glow = true,
            shift = { 0.03125, 0.640625 },
            blend_mode = "additive",
          },
        },
        {
          fadeout = true,
          effect = "flicker",
          animation = {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace-working.png",
            priority = "high",
            line_length = 1,
            width = 128,
            height = 150,
            draw_as_glow = true,
            shift = util.by_pixel(0, -5),
            blend_mode = "additive",
            scale = 0.5,
          },
        },
        {
          fadeout = true,
          effect = "flicker",
          animation = {
            filename = "__base__/graphics/entity/steel-furnace/steel-furnace-ground-light.png",
            priority = "high",
            line_length = 1,
            width = 152,
            height = 126,
            draw_as_light = true,
            shift = util.by_pixel(1, 48),
            blend_mode = "additive",
            scale = 0.5,
          },
        },
      },
      water_reflection = {
        pictures = {
          filename = "__base__/graphics/entity/steel-furnace/steel-furnace-reflection.png",
          priority = "extra-high",
          width = 20,
          height = 24,
          shift = util.by_pixel(0, 45),
          variation_count = 1,
          scale = 5,
        },
        rotate = false,
        orientation_to_variation = false,
      },
    },
  },
})
