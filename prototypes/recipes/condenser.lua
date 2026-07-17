data:extend({
  {
    type = "recipe",
    name = "nullarbor-condenser",
    category = "crafting",
    energy_required = 5,
    ingredients = {
      { type = "item", name = "iron-plate",        amount = 10 },
      { type = "item", name = "steel-plate",       amount = 5  },
      { type = "item", name = "pipe",              amount = 8  },
      { type = "item", name = "electronic-circuit", amount = 5 },
    },
    results = {
      { type = "item", name = "nullarbor-condenser", amount = 1 },
    },
    enabled = false,
  },
  {
    type = "recipe",
    name = "nullarbor-condense-water",
    subgroup = "nullarbor-processing",
    order = "d[condense-water]",
    category = "nullarbor-condensing",
    energy_required = 5,
    ingredients = {},
    results = {
      { type = "fluid", name = "water", amount = 60 },
    },
    enabled = true,
    hide_from_player_crafting = true,
  },
})
