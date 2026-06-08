-- Add the energetic science pack to vanilla labs so no Nullarbor-specific lab is needed.

for _, lab_name in ipairs({ "lab", "biolab" }) do
  local lab = data.raw["lab"][lab_name]
  if lab then
    table.insert(lab.inputs, "nullarbor-energetic-science-pack")
  end
end
