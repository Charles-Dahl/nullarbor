local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-bauxite",
    icons = { { icon = "__base__/graphics/icons/stone.png", icon_size = 64, tint = tints.grey } },
    subgroup = "nullarbor-resources",
    order = "a[nullarbor]-b[bauxite]",
    stack_size = 50,
  },
})
