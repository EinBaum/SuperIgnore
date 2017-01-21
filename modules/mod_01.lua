
local mod = {
	["Name"] = "Spam Blocker",
	["Description"] = "Blocks spam messages in chat",
	["OnEnable"] = function() 
	end,
	["OnDisable"] = function()
	end,
	["CreateUI"] = function(frame, pad)
		return pad
	end,
	["NameFilter"] = nil,
	["ChatFilter"] = nil,
}

local f = CreateFrame("frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SI_ModInstall(mod)
end)
