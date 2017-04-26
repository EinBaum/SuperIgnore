
local chatfilter = function(message, name, type)
	return name
		and (not FriendLib:IsFriend(name))
		and (FilterLib:Filter(message) == "")
end

local mod = {
	["Name"] = "ChatSanitizer",
	["Description"] = "Blocks gold spam messages.",
	["Help"] = "Knows how common spam messages look like, e.g. what words they are made of. Friends and guild members are excluded from being ignored. More info here: https://github.com/Aviana/ChatSanitizer",
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
