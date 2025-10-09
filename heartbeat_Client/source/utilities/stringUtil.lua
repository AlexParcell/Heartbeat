return function()
	local stringUtil = {}

    function stringUtil:BreakStringIntoWrappedLines(str, maxWidth, font)
        local wrappedLines = {}
        local spaceWidth = font:getWidth(" ")

        -- Normalize line endings
        str = str:gsub("\r\n", "\n"):gsub("\r", "\n")

        -- Split the text by newlines (each treated as a separate paragraph)
        for paragraph in (str .. "\n"):gmatch("(.-)\n") do
            local currentLine = ""
            local currentWidth = 0

            for word in paragraph:gmatch("%S+") do
                local wordWidth = font:getWidth(word)

                if currentLine == "" then
                    currentLine = word
                    currentWidth = wordWidth
                else
                    local newWidth = currentWidth + spaceWidth + wordWidth
                    if newWidth <= maxWidth then
                        currentLine = currentLine .. " " .. word
                        currentWidth = font:getWidth(currentLine)
                    else
                        table.insert(wrappedLines, currentLine)
                        currentLine = word
                        currentWidth = wordWidth
                    end
                end
            end

            if currentLine ~= "" then
                table.insert(wrappedLines, currentLine)
            end
        end

        return wrappedLines
    end
    
	return stringUtil
end