
if not ChatSanitizer then ChatSanitizer = {} end
local chatfilter = function(message, name)
	ChatSanitizer:Filter(message)
end

local mod = {
	["Name"] = "Spam Blocker",
	["Description"] = "Blocks spam messages in chat.",
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
