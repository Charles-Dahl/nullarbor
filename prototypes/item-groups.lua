-- A dedicated crafting-menu tab for everything Nullarbor adds, so the mod's
-- recipes and items browse together instead of scattering across vanilla
-- subgroups -- and so multi-output fluid recipes (which infer no main product)
-- stop falling into the "unsorted"/other subgroup. Purely GUI organization; no
-- gameplay effect (recipe categories, ingredients, and tech are untouched).
data:extend({
  {
    type = "item-group",
    name = "nullarbor",
    order = "z[nullarbor]", -- after the vanilla groups
    -- Placeholder: reuse the planet's (also placeholder) Fulgora art until custom
    -- Nullarbor icons exist. Keep in sync with prototypes/planet/nullarbor.lua.
    icon = "__space-age__/graphics/icons/fulgora.png",
    icon_size = 64,
  },
  { type = "item-subgroup", name = "nullarbor-machines", group = "nullarbor", order = "a" },
  { type = "item-subgroup", name = "nullarbor-processing", group = "nullarbor", order = "b" },
  { type = "item-subgroup", name = "nullarbor-materials", group = "nullarbor", order = "c" },
  { type = "item-subgroup", name = "nullarbor-resources", group = "nullarbor", order = "d" },
  { type = "item-subgroup", name = "nullarbor-fluids", group = "nullarbor", order = "e" },
})
