local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-condenser",
    icons = { { icon = "__base__/graphics/icons/assembling-machine-3.png", icon_size = 64, tint = tints.purple } },
    subgroup = "nullarbor-machines",
    order = "c[condenser]",
    place_result = "nullarbor-condenser",
    stack_size = 20,
  },
})
