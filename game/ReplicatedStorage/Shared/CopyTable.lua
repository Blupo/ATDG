local copy
copy = function(tab)
    local tabCopy = {}

    for k, v in pairs(tab) do
        tabCopy[k] = (type(v) == "table") and copy(v) or v
    end

    return tabCopy
end

return copy