data:extend({
  {
    type = "recipe",
    name = "nullarbor-distributor-crane",
    category = "crafting",
    energy_required = 10,
    ingredients = {
      { type = "item", name = "nullarbor-burner-inserter-mk2", amount = 8 },
      { type = "item", name = "steel-plate",                   amount = 10 },
      { type = "item", name = "iron-gear-wheel",               amount = 10 },
    },
    results = {
      { type = "item", name = "nullarbor-distributor-crane", amount = 1 },
    },
    -- Enabled for the prototype spike; gate behind tech once validated.
    enabled = true,
  },
})
