-- Class Set
Set = { keys = {}}
Set.__index = Set

function Set.new()
    local self = setmetatable({}, Set)
    self.keys = {}
    return self
end

function Set:add(item)
    self.keys[item] = true
end

function Set:size()
    local size = 0
    for item in pairs(self.keys) do
        size = size + 1
    end
    return size
end

function Set:values()
    local values = {}
    for item in pairs(self.keys) do
        values[#values + 1] = item
    end
    return values
end

return Set