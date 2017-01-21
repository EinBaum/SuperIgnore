
local mod = {
	["Name"] = "Special Snowflake Blocker",
	["Description"] = "Blocks messages sent by players who have special characters in their names.",
	["OnEnable"] = function() 
	end,
	["OnDisable"] = function()
	end,
	["CreateUI"] = function(frame, pad)
		return pad
	end,
	["NameFilter"] = function(name)
		if string.find(name, "[^a-zA-Z]") then
			return true
		end
		return false
	end,
	["ChatFilter"] = nil,
}


local f = CreateFrame("frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SI_ModInstall(mod)
end)
