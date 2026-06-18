-- Placeholder sand tile for Nullarbor's basins. Cloned from Fulgora's sand
-- (reusing its red-desert graphics) but with an autoplace that wins in the
-- former oil-ocean basins: fulgora_oil_mask is 1 in basins, 0 elsewhere, so
-- this scores ~50 in basins (beating fulgoran-rock's ~2.1) and ~1 outside.
-- Without this, omitting the oil tiles would leave basins as walkable rock.
local sand = util.table.deepcopy(data.raw.tile["fulgoran-sand"])
sand.name = "nullarbor-sand"
sand.autoplace = {
  probability_expression = "1 - fulgora_dunes + 50 * fulgora_oil_mask",
}

-- Tile render layers must be unique across all tiles; the deepcopy kept
-- fulgoran-sand's, so give this one a fresh layer above every existing tile.
local max_layer = 0
for _, t in pairs(data.raw.tile) do
  if t.layer and t.layer > max_layer then
    max_layer = t.layer
  end
end
sand.layer = max_layer + 1

data:extend({ sand })
