local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-cupric-shale",
    icons = { { icon = "__base__/graphics/icons/copper-ore.png", icon_size = 64, tint = tints.grey } },
    subgroup = "nullarbor-resources",
    order = "a[nullarbor]-a[cupric-shale]",
    stack_size = 50,
  },
})
