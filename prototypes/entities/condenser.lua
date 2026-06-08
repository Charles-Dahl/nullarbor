require("__base__/prototypes/entity/pipecovers")
require("circuit-connector-sprites")
require("__base__/prototypes/entity/assemblerpipes")
local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")

data:extend({
  {
    type = "assembling-machine",
    name = "nullarbor-condenser",
    icon = "__base__/graphics/icons/assembling-machine-3.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.2, result = "nullarbor-condenser" },
    max_health = 400,
    corpse = "assembling-machine-3-remnants",
    dying_explosion = "assembling-machine-3-explosion",
    icon_draw_specification = { shift = { 0, -0.3 } },
    circuit_wire_max_distance = assembling_machine_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions["assembling-machine"],
    alert_icon_shift = util.by_pixel(0, -12),
    resistances = {
      {
        type = "fire",
        percent = 70,
      },
    },
    fluid_boxes = {
      {
        production_type = "input",
        pipe_picture = assembler3pipepictures(),
        pipe_covers = pipecoverspictures(),
        volume = 1000,
        pipe_connections = { { flow_direction = "input", direction = defines.direction.north, position = { 0, -1 } } },
        secondary_draw_orders = { north = -1 },
      },
      {
        production_type = "output",
        pipe_picture = assembler3pipepictures(),
        pipe_covers = pipecoverspictures(),
        volume = 1000,
        pipe_connections = { { flow_direction = "output", direction = defines.direction.south, position = { 0, 1 } } },
        secondary_draw_orders = { north = -1 },
      },
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    impact_category = "metal",
    working_sound = {
      sound = {
        filename = "__base__/sound/assembling-machine-t3-1.ogg",
        volume = 0.45,
        audible_distance_modifier = 0.5,
      },
      fade_in_ticks = 4,
      fade_out_ticks = 20,
    },
    collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    damaged_trigger_effect = hit_effects.entity(),
    drawing_box_vertical_extension = 0.2,
    fast_replaceable_group = "assembling-machine",
    graphics_set = {
      animation_progress = 0.5,
      animation = {
        layers = {
          {
            filename = "__base__/graphics/entity/assembling-machine-3/assembling-machine-3.png",
            priority = "high",
            width = 214,
            height = 237,
            frame_count = 32,
            line_length = 8,
            shift = util.by_pixel(0, -0.75),
            scale = 0.5,
          },
          {
            filename = "__base__/graphics/entity/assembling-machine-3/assembling-machine-3-shadow.png",
            priority = "high",
            width = 260,
            height = 162,
            frame_count = 32,
            line_length = 8,
            draw_as_shadow = true,
            shift = util.by_pixel(28, 4),
            scale = 0.5,
          },
        },
      },
    },

    crafting_categories = { "nullarbor-condensing" },
    crafting_speed = 1.25,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 2 },
    },
    energy_usage = "375kW",
    module_slots = 4,
    allowed_effects = { "consumption", "speed", "productivity", "pollution", "quality" },
  },
})
