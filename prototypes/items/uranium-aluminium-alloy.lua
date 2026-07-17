local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-uranium-aluminium-alloy",
    icons = { { icon = "__space-age__/graphics/icons/tungsten-plate.png", icon_size = 64, tint = tints.alloy } },
    subgroup = "nullarbor-materials",
    order = "f[nullarbor]-a[uranium-aluminium-alloy]",
    stack_size = 100,
  },
})
