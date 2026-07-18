local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item-with-entity-data",
    name = "nullarbor-mining-wagon",
    icons = { { icon = "__base__/graphics/icons/cargo-wagon.png", icon_size = 64, tint = tints.aluminium } },
    subgroup = "nullarbor-machines",
    order = "g[mining-wagon]",
    place_result = "nullarbor-mining-wagon",
    stack_size = 5,
  },
})
