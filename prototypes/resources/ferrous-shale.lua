data:extend({
  {
    type = "resource",
    name = "nullarbor-ferrous-shale",
    icon = "__base__/graphics/icons/iron-ore.png",
    icon_size = 64,
    flags = { "placeable-neutral" },
    category = "basic-solid",
    minable = {
      mining_time = 1,
      result = "nullarbor-ferrous-shale",
    },
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    stages = {
      sheet = {
        filename = "__base__/graphics/entity/iron-ore/iron-ore.png",
        priority = "extra-high",
        width = 64,
        height = 64,
        frame_count = 8,
        variation_count = 8,
      },
    },
    stage_counts = { 0 },
    map_color = { r = 0.6, g = 0.3, b = 0.2 },
  },
})
