-- Pollution-throttled solar panel variants (Phase 2 of Nullarbor pollution).
-- Nullarbor is permanent-day, so solar is a headline power source -- but local
-- pollution ("smog") throttles it. control.lua watches every solar panel on the
-- Nullarbor surface and fast-replaces it between the vanilla panel and these
-- reduced-production clones according to the pollution over its chunk.
--
-- These are never crafted or placed by the player. They share the vanilla
-- panel's fast_replaceable_group, mine back to a vanilla solar panel
-- (inherited minable.result), resolve to the vanilla item for blueprints and
-- pipette (placeable_by), and fold into the vanilla panel's Factoriopedia
-- entry (factoriopedia_alternative) -- so no new item or recipe is needed.
--
-- Each tier is tinted a progressively darker grey so a smog-throttled field
-- reads at a glance, ashier the heavier the pollution.
local BASE = data.raw["solar-panel"]["solar-panel"]

-- Multiply every non-shadow image layer by the tint; recurses into .layers.
-- Shadow layers are left alone so shadows stay black.
local function apply_tint(graphic, tint)
  if type(graphic) ~= "table" then
    return
  end
  if graphic.layers then
    for _, layer in pairs(graphic.layers) do
      apply_tint(layer, tint)
    end
  elseif graphic.filename and not graphic.draw_as_shadow then
    graphic.tint = tint
  end
end

-- The vanilla panel produces 60kW; the variants keep that scaling relationship
-- so quality still multiplies them proportionally. Values are placeholders.
local function make_variant(name, production, tint)
  local variant = util.table.deepcopy(BASE)
  variant.name = name
  variant.production = production
  variant.placeable_by = { item = "solar-panel", count = 1 }
  variant.factoriopedia_alternative = "solar-panel"
  variant.localised_name = { "entity-name." .. name }
  apply_tint(variant.picture, tint)
  apply_tint(variant.overlay, tint)
  return variant
end

data:extend({
  -- ~60% of base, lightly greyed.
  make_variant("nullarbor-solar-panel-mild-smog", "36kW", { 0.72, 0.72, 0.72, 1 }),
  -- ~25% of base, heavily greyed.
  make_variant("nullarbor-solar-panel-heavy-smog", "15kW", { 0.42, 0.42, 0.42, 1 }),
})
