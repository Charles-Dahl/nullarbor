local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-ferrous-shale",
    icons = { { icon = "__base__/graphics/icons/iron-ore.png", icon_size = 64, tint = tints.grey } },
    subgroup = "raw-resource",
    order = "a[nullarbor]-a[ferrous-shale]",
    stack_size = 50,
  },
})
