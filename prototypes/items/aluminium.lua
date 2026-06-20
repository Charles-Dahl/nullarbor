local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-aluminium",
    icons = { { icon = "__base__/graphics/icons/steel-plate.png", icon_size = 64, tint = tints.white } },
    subgroup = "raw-resource",
    order = "a[nullarbor]-b[aluminium]",
    stack_size = 50,
  },
})
