
if not ChatSanitizer then ChatSanitizer = {} end
local chatfilter = function(message, name, type)
	return (ChatSanitizer:Filter(message) == "")
end

local mod = {
	["Name"] = "ChatSanitizer",
	["Description"] = "Blocks spam messages. https://github.com/Aviana/ChatSanitizer",
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
