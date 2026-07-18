-- Mining Wagon: a normal cargo wagon (holds the mined ore) that, when the train
-- stops at a station on straight rail, has a hidden mining drill deployed over it
-- by control.lua. The wagon itself is vanilla cargo-wagon behaviour; all mining
-- and fuel logic is scripted. Retinted via the rolling-stock `color` mask.
local tints = require("prototypes.material-tints")

local wagon = table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
wagon.name = "nullarbor-mining-wagon"
wagon.icons = { { icon = "__base__/graphics/icons/cargo-wagon.png", icon_size = 64, tint = tints.aluminium } }
wagon.icon = nil
wagon.icon_size = nil
wagon.minable = { mining_time = 0.5, result = "nullarbor-mining-wagon" }
wagon.inventory_size = 20 -- smaller than a plain wagon: it generates ore (tunable)
wagon.color = { r = 0.5, g = 0.62, b = 0.85, a = 1 } -- aluminium-blue mask, visually distinct

data:extend({ wagon })
