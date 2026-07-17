require("circuit-connector-sprites")
local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")

data:extend({
  {
    type = "inserter",
    name = "nullarbor-burner-inserter-mk2",
    icon = "__base__/graphics/icons/burner-inserter.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.1, result = "nullarbor-burner-inserter-mk2" },
    max_health = 150,
    corpse = "burner-inserter-remnants",
    dying_explosion = "burner-inserter-explosion",
    resistances = {
      {
        type = "fire",
        percent = 90,
      },
    },
    collision_box = { { -0.15, -0.15 }, { 0.15, 0.15 } },
    selection_box = { { -0.4, -0.35 }, { 0.4, 0.45 } },
    -- Shares the vanilla inserter group so the burner inserter (and other vanilla
    -- inserters) fast-replace into the mk2 as an upgrade.
    fast_replaceable_group = "inserter",
    damaged_trigger_effect = hit_effects.entity(),
    pickup_position = { 0, -1 },
    insert_position = { 0, 1.2 },
    energy_per_movement = "7kJ",
    energy_per_rotation = "7kJ",
    energy_source = {
      type = "burner",
      fuel_categories = { "chemical" },
      initial_fuel = "wood",
      initial_fuel_percent = 0.25,
      effectivity = 1,

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
    extension_speed = 0.1,
    rotation_speed = 0.04,
    allow_burner_leech = true,
    filter_count = 5,
    icon_draw_specification = { scale = 0.5 },
    impact_category = "metal",
    open_sound = sounds.inserter_open,
    close_sound = sounds.inserter_close,
    working_sound = sounds.inserter_fast,
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
    platform_picture = {
      sheet = {
        filename = "__base__/graphics/entity/burner-inserter/burner-inserter-platform.png",
        priority = "extra-high",
        width = 105,
        height = 79,
        shift = util.by_pixel(1.5, 7.5 - 1),
        scale = 0.5,
      },
    },
    circuit_connector = circuit_connector_definitions["inserter"],
    circuit_wire_max_distance = inserter_circuit_wire_max_distance,
    default_stack_control_input_signal = inserter_default_stack_control_input_signal,
  },
})
