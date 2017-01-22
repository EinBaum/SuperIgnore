
local chatfilter = function(message, name, type)
	return false
end

local mod = {
	["Name"] = "Custom Message Blocker",
	["Description"] = "Blocks all messages containing a phrase.",
	["OnEnable"] = nil,
	["OnDisable"] = nil,
	["CreateUI"] = function(frame, pad)
		return pad
	end,
	["NameFilter"] = nil,
	["ChatFilter"] = chatfilter,
}

local f = CreateFrame("frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SI_ModInstall(mod)
end)
