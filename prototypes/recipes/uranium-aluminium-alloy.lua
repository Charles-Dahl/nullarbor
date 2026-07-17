local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "recipe",
    name = "nullarbor-uranium-aluminium-alloy",
    icon = "__base__/graphics/icons/uranium-238.png",
    icon_size = 64,
    category = "nullarbor-crafting",
    energy_required = 10,
    ingredients = {
      { type = "item", name = "uranium-238", amount = 2 },
      { type = "item", name = "nullarbor-aluminium", amount = 4 },
    },
    results = {
      { type = "item", name = "nullarbor-uranium-aluminium-alloy", amount = 1 },
    },
    enabled = false,
    allow_productivity = true,
  },
  {
    type = "recipe",
    name = "nullarbor-uranium-aluminium-alloy-casting",
    -- Alternative alloy source for players who bring a Foundry: cast the uranium
    -- suspended in radioactive slurry straight into alloy with aluminium, skipping
    -- the lossy U-238 extraction the Burner Assembling Machine route needs. Amounts
    -- and energy are placeholder -- needs balancing vs. that route (2 U-238 + 4
    -- aluminium -> 1 alloy).
    icons = { { icon = "__space-age__/graphics/icons/fluid/fluorine.png", icon_size = 64, tint = tints.aluminium } },
    subgroup = "nullarbor-materials",
    order = "f[nullarbor]-a[uranium-aluminium-alloy]-b[casting]",
    category = "metallurgy",
    energy_required = 16,
    ingredients = {
      { type = "fluid", name = "nullarbor-radioactive-slurry", amount = 100 },
      { type = "item", name = "nullarbor-aluminium", amount = 4 },
    },
    results = {
      { type = "item", name = "nullarbor-uranium-aluminium-alloy", amount = 1 },
    },
    enabled = false,
    -- True so the recipe gets the Foundry's base +50% productivity (its whole
    -- appeal), plus prod modules/research -- like vanilla casting recipes. Balance
    -- the route via the input amounts above, not by denying productivity.
    allow_productivity = true,
  },
})
