local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "resource",
    name = "nullarbor-bauxite",
    icon = "__base__/graphics/icons/stone.png",
    icon_size = 64,
    flags = { "placeable-neutral" },
    category = "basic-solid",
    minable = {
      mining_time = 1,
      result = "nullarbor-bauxite",
    },
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    stages = {
      sheet = {
        filename = "__base__/graphics/entity/stone/stone.png",
        priority = "extra-high",
        width = 64,
        height = 64,
        frame_count = 8,
        variation_count = 8,
        tint = tints.grey,
      },
    },
    stage_counts = { 0 },
    map_color = tints.grey_map,
  },
})
