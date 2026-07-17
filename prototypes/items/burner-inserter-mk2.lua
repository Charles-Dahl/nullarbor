local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-burner-inserter-mk2",
    icons = { { icon = "__base__/graphics/icons/burner-inserter.png", icon_size = 64, tint = tints.aluminium } },
    subgroup = "nullarbor-machines",
    order = "d[burner-inserter-mk2]",
    place_result = "nullarbor-burner-inserter-mk2",
    stack_size = 50,
  },
})
