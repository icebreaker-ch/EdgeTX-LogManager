local Selector = {}
Selector.__index = Selector

Selector.STATE_IDLE = 0
Selector.STATE_SELECTED = 1
Selector.STATE_EDITING = 2

function Selector.new(values, index)
    local self = setmetatable({}, Selector)
    self.index = index
    self.values = values
    self.state = self.STATE_IDLE
    return self
end

function Selector:setValues(values)
    self.values = values
end

function Selector:setIndex(index)
    self.index = index
end

function Selector:setState(newState)
    self.state = newState
end

function Selector:getState()
    return self.state
end

function Selector:getIndex()
    return self.index
end

function Selector:getValue()
    return self.values[self.index]
end

function Selector:getFlags()
    if self.state == self.STATE_IDLE then
        return 0
    elseif self.state == self.STATE_SELECTED then
        return INVERS
    elseif self.state == self.STATE_EDITING then
        return BLINK
    end
end

function Selector:incValue()
    if self.index < #self.values then
        self.index = self.index + 1
    end
end

function Selector:decValue()
    if self.index > 1 then
        self.index = self.index - 1
    end
end

return Selector