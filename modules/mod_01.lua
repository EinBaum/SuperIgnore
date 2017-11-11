
local chatfilter = function(message, name, type)
	return name
		and (not FriendLib:IsFriend(name))
		and (FilterLib:Filter(message) == "")
end

local mod = {
	["Name"] = "ChatSanitizer",
	["Description"] = "Blocks gold spam and advertisements.",
	["Help"] = "Knows how common spam messages look like, e.g. what words they are made of. Friends, party and guild members are never ignored. More info here:|n|nhttps://github.com/Aviana/ChatSanitizer",
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
