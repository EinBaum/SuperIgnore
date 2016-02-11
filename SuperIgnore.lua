
local S_ADDON_NAME		= "SuperIgnore"
local S_ADDON_DIR		= "superignore"
local S_ADDON_VERSION		= "1.1.6"
local S_AUTO_RESPONSE		= "~Ignored~ (" .. S_ADDON_NAME .. " AddOn)"
local S_TEXT_OPTIONS		= "Ignore Filter"
local S_TEXT_EXTRA		= "Extra Features"
local S_TEXT_DURATION		= "Default Ignore Time"
local S_TEXT_WHISPER_BLOCK	= "Do not let me whisper\nignored players"
local S_TEXT_WHISPER_UNIGNORE	= "Unignore players if I\nwhisper them"
local S_TEXT_AUTO		= "Notify ignored players\nwho interact with me\n(only once)"
local S_TEXT_SPECIAL		= "Auto-Block players\nwith special characters\nin their names"
local S_CHAT_IGNORED		= "%s is now being ignored. Duration: %s."
local S_CHAT_UNIGNORED		= "%s is no longer being ignored."
local S_CHAT_BLOCKED		= "Your message was not sent because are ignoring %s."
local S_CHAT_SELF		= "You can't ignore yourself."
local S_BAN_WHISPER		= "Whispers"
local S_BAN_PARTY		= "Party / Raid"
local S_BAN_GUILD		= "Guild Chat"
local S_BAN_OFFICER		= "Officer Chat"
local S_BAN_SAY			= "Say"
local S_BAN_YELL		= "Yell"
local S_BAN_BG			= "Battleground"
local S_BAN_PUBLIC		= "Public Channels"
local S_BAN_EMOTE		= "Emotes"
local S_BAN_TRADE		= "Trade Requests"
local S_BAN_INVITE		= "Invites"
local S_BAN_DUEL		= "Duels"

local T_RELOG		= 1
local T_HOUR		= 2
local T_DAY		= 3
local T_WEEK		= 4
local T_MONTH		= 5
local T_FOREVER		= 6
local T_AUTOBLOCK	= 7

local TI_FOREVER	= 1e30 -- lol
local TI_RELOG		= -1
local TI_AUTOBLOCK	= 1e31

local B_NAME		= 1
local B_DURATION	= 2
local B_NOTIFIED	= 3

local T_Time_Text = {
	"Until Relog",
	"Hour",
	"Day",
	"Week",
	"Month",
	"Forever",
	"Auto-Block",
}
local T_Time = {
	TI_RELOG,
	60 * 60,
	60 * 60 * 24,
	60 * 60 * 24 * 7,
	60 * 60 * 24 * 30,
	TI_FOREVER,
	TI_AUTOBLOCK,
}

local T_Time_TextOpt = {
	T_Time_Text[1],
	T_Time_Text[2],
	T_Time_Text[3],
	T_Time_Text[4],
	T_Time_Text[5],
	T_Time_Text[6],
}

------------- Global

SI_Filter = {}
SI_MainFrame = nil

------------- Filter

SI_AddFilter = function(filter)
	table.insert(SI_Filter, filter)
end
SI_DelFilter = function(filter)
	table.remove(SI_Filter, filter)
end

SI_IsPlayerIgnored = function(name)

	if name == UnitName("player") then
		return false
	end

	for _, filter in SI_Filter do
		if filter(name) then
			SI_CheckAutoBlock(name)
			return true
		end
	end

	return false
end


------------- Helper

SI_Print = function(msg)
	local info = ChatTypeInfo["SYSTEM"]
	DEFAULT_CHAT_FRAME:AddMessage(msg, info.r, info.g, info.b, info.id);
end

SI_IsTimeSpecial = function(t)
	return t == TI_FOREVER or t == TI_RELOG or t == TI_AUTOBLOCK
end

SI_CalcBanTime = function()
	local t = T_Time[SI_Global.BanDuration]
	if SI_IsTimeSpecial(t) then
		return t
	else
		return time() + t
	end
end
SI_IsBanTimeOver = function(t)
	if SI_IsTimeSpecial(t) then
		return false
	else
		return time() > t
	end
end
SI_CleanUpRelog = function()
	local unbanNames = {}
	for _, banned in SI_Global.BannedPlayers do
		local d = banned[B_DURATION]
		if d == TI_RELOG or d == TI_AUTOBLOCK then
			table.insert(unbanNames, banned[B_NAME])
		end
	end

	for _, name in unbanNames do
		SI_DelIgnore_New(name, true)
	end
end
SI_CheckBanTimes = function()
	local unbanNames = {}
	for _, banned in SI_Global.BannedPlayers do
		if SI_IsBanTimeOver(banned[B_DURATION]) then
			table.insert(unbanNames, banned[B_NAME])
		end
	end

	for _, name in unbanNames do
		SI_DelIgnore_New(name)
	end
end
SI_FormatTimeNoStyle = function(t)

	local _s = function(n)
		if n == 1 then return "" else return "s" end
	end

	if t == TI_FOREVER then
		return T_Time_Text[T_FOREVER], "ff00ff"
	elseif t == TI_RELOG then
		return T_Time_Text[T_RELOG], "00ff00"
	elseif t == TI_AUTOBLOCK then
		return T_Time_Text[T_AUTOBLOCK], "ffffff"
	else
		local tt = t - time()
		if tt < 0 then
			return "0", "00ffff"
		else
			tt = tt / 60
			if tt < 60 then
				tt = math.ceil(tt)
				return tt .. " Min" .. _s(tt), "00ffff"
			end

			tt = tt / 60
			if tt < 24 then
				tt = math.ceil(tt)
				return tt .. " Hour" .. _s(tt), "ffff00"
			end

			tt = tt / 24
			tt = math.ceil(tt)
			return tt .. " Day" .. _s(tt), "ff0000"
		end
	end
end
SI_FormatTime = function(t)
	local str, color = SI_FormatTimeNoStyle(t)
	return "|cff" .. color .. "[" .. str .. "]|r "
end

SI_FixPlayerName = function(name)
	return string.gsub(name, "^%l", string.upper)
end

SI_StringFindPattern = function(s, r)
	-- %s
	-- ([^ ]+)
	-- (.*)
	r = string.gsub(r, "%%s", "%(%[%^ %]%+%)", 1)
	r = string.gsub(r, "%%s", "%(%.%*%)")
	return string.find(s, r)
end

SI_FixBannedSelected = function()
	 local selected = SI_Global.BannedSelected
	 if selected > 1 and selected > GetNumIgnores() then
		SI_Global.BannedSelected = selected - 1
	 end
end

SI_FindBannedPlayer = function(name)
	for index, banned in SI_Global.BannedPlayers do
		if banned[B_NAME] == name then
			return index
		end
	end

	return nil
end

SI_SortBannedPlayersByTime = function()
	table.sort(SI_Global.BannedPlayers, function(a, b)
		local at = a[B_DURATION]
		local bt = b[B_DURATION]
		if at == bt then
			return a[B_NAME] < b[B_NAME]
		else
			return at < bt
		end
	end)
end

SI_IsChannelBanned = function(c)
	local g = SI_Global

	if c == "WHISPER"	then return g.BanOptWhisper end
	if(c == "PARTY" or c == "RAID" or c == "RAID_LEADER" or c == "RAID_WARNING")
				then return g.BanOptParty end
	if c == "GUILD"		then return g.BanOptGuild end
	if c == "OFFICER"	then return g.BanOptOfficer end
	if c == "SAY"		then return g.BanOptSay end
	if c == "YELL"		then return g.BanOptYell end
	if(c == "BATTLEGROUND" or c == "BATTLEGROUND_LEADER")
				then return g.BanOptBg end
	if c == "CHANNEL"	then return g.BanOptPublic end
	if(c == "EMOTE" or c == "TEXT_EMOTE")
				then return g.BanOptEmote end

	return false
end

SI_CheckInteractRules = function(name)
	if SI_Global.WhisperBlock then
		SI_Print(string.format(S_CHAT_BLOCKED, name))
		return true
	elseif SI_Global.WhisperUnignore then
		SI_DelIgnore_New(name)
		return false
	else
		return false
	end
end

SI_CheckAutoResponse = function(name)
	if SI_Global.AutoResponse then
		local index = SI_FindBannedPlayer(name)
		if index then
			if not SI_Global.BannedPlayers[index][B_NOTIFIED] then
				SI_Global.BannedPlayers[index][B_NOTIFIED] = true
				SI_SendChatMessage_Old(S_AUTO_RESPONSE, "WHISPER", nil, name)
			end
		end
	end
end

SI_CheckAutoBlock = function(name)
	local index = SI_FindBannedPlayer(name)
	if not index then
		SI_AddIgnore_New(name, true, TI_AUTOBLOCK)
	end
end

SI_IsChatIgnored = function(event, arg1, arg2)

	if strsub(event, 1, 8) == "CHAT_MSG" then
		local type = strsub(event, 10)
		if type == "IGNORED" then
			return true
		end

		if arg1 and type == "SYSTEM" then
			local found, _, name = SI_StringFindPattern(arg1, ERR_IGNORE_REMOVED_S)
			if found and name then
				return true
			end

			found, _, name = SI_StringFindPattern(arg1, ERR_INVITED_TO_GUILD_SS)
			if found and name and SI_IsPlayerIgnored(name) then
				return true
			end

			found, _, name = SI_StringFindPattern(arg1, ERR_INVITED_TO_GROUP_S)
			if found and name and SI_IsPlayerIgnored(name) then
				return true
			end
		end

		if arg1 and arg2 and type == "WHISPER_INFORM" then
			if arg1 == S_AUTO_RESPONSE then
				return true
			end
		end

		if arg2 and SI_IsChannelBanned(type) and SI_IsPlayerIgnored(arg2) then
			if type == "WHISPER" then
				SI_CheckAutoResponse(arg2)
			end

			return true
		end
	end

	return false
end

------------- Overrides


SI_AddIgnore_Old		= nil
SI_AddOrDelIgnore_Old		= nil
SI_DelIgnore_Old		= nil
SI_GetIgnoreName_Old		= nil
SI_GetNumIgnores_Old		= nil
SI_GetSelectedIgnore_Old	= nil
SI_SetSelectedIgnore_Old	= nil
SI_TradeFrame_OnEvent_Old	= nil
SI_StaticPopup_Show_Old		= nil
SI_ChatFrame_OnEvent_Old	= nil
SI_WIM_ChatFrame_OnEvent_Old	= nil
SI_SendChatMessage_Old		= nil

SI_AddIgnore_New = function(name, quiet, banTime)

	name = SI_FixPlayerName(name)
	if name == UnitName("player") then
		SI_Print(S_CHAT_SELF)
		return
	end

	if not banTime then
		banTime = SI_CalcBanTime()
	end

	local index = SI_FindBannedPlayer(name)
	if index then
		SI_Global.BannedPlayers[index][B_DURATION] = banTime
	else
		table.insert(SI_Global.BannedPlayers, {name, banTime, false})
	end

	SI_SortBannedPlayersByTime()
	IgnoreList_Update()

	if not quiet then
		SI_Print(string.format(S_CHAT_IGNORED, name, SI_FormatTimeNoStyle(banTime)))
	end
end

SI_AddOrDelIgnore_New = function(name)
	local index = SI_FindBannedPlayer(name)
	if index then
		SI_DelIgnore_New(name)
	else
		SI_AddIgnore_New(name)
	end
end

SI_DelIgnore_New = function(name, quiet)

	name = string.gsub(name, "^|cff([^|]+)|r ", "")
	name = SI_FixPlayerName(name)

	local index = SI_FindBannedPlayer(name)
	if index then
		 table.remove(SI_Global.BannedPlayers, index)
		 SI_FixBannedSelected()
		 IgnoreList_Update()

		 if not quiet then
			SI_Print(string.format(S_CHAT_UNIGNORED, name))
		end
	end
end

SI_GetIgnoreName_New = function(index)
	local banned = SI_Global.BannedPlayers[index]
	if banned then
		return SI_FormatTime(banned[B_DURATION]) .. banned[B_NAME]
	else
		return UNKNOWN
	end
end

SI_GetNumIgnores_New = function()
	return table.getn(SI_Global.BannedPlayers)
end

SI_GetSelectedIgnore_New = function()
	return SI_Global.BannedSelected
end

SI_SetSelectedIgnore_New = function(index)
	SI_Global.BannedSelected = index
end

SI_StaticPopup_Show_New = function(which, text_arg1, text_arg2, data)
	local name = text_arg1
	if SI_Global.BanOptInvite then
		if which == "PARTY_INVITE" then
			if SI_IsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				DeclineGroup()
				return
			end
		elseif which == "GUILD_INVITE" then
			if SI_IsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				DeclineGuild()
				return
			end
		end
	end
	if SI_Global.BanOptDuel then
		if which == "DUEL_REQUESTED" then
			if SI_IsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				CancelDuel()
				return
			end
		end
	end

	return SI_StaticPopup_Show_Old(which, text_arg1, text_arg2, data)
end

SI_TradeFrame_OnEvent_New = function()
	if SI_Global.BanOptTrade then
		if event == "TRADE_SHOW" or event == "TRADE_UPDATE" then
			local name = UnitName("NPC")
			if SI_IsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				CloseTrade()
				return
			end
		end
	end

	SI_TradeFrame_OnEvent_Old()
end

SI_ChatFrame_OnEvent_New = function(event)
	if not SI_IsChatIgnored(event, arg1, arg2) then
		SI_ChatFrame_OnEvent_Old(event)
	end
end

SI_WIM_ChatFrame_OnEvent_New = function(event)
	if not SI_IsChatIgnored(event, arg1, arg2) then
		SI_WIM_ChatFrame_OnEvent_Old(event)
	end
end

SI_WhisperFu_OnReceiveWhisper_New = function()
	if not SI_IsChatIgnored("CHAT_MSG_WHISPER", arg1, arg2) then
		WhisperFu:OnReceiveWhisper_Old()
	end
end

SI_SendChatMessage_New = function(msg, chatType, lang, channel)
	local name = channel
	if chatType == "WHISPER" and SI_IsPlayerIgnored(channel) then
		if SI_CheckInteractRules(channel) then
			return
		end
	end
	SI_SendChatMessage_Old(msg, chatType, lang, channel)
end


------------- Main Code

SI_HookFunctions = function()

	SI_AddIgnore_Old		= AddIgnore
	AddIgnore			= SI_AddIgnore_New

	SI_AddOrDelIgnore_Old		= AddOrDelIgnore
	AddOrDelIgnore			= SI_AddOrDelIgnore_New

	SI_DelIgnore_Old		= DelIgnore
	DelIgnore			= SI_DelIgnore_New

	SI_GetIgnoreName_Old		= GetIgnoreName
	GetIgnoreName			= SI_GetIgnoreName_New

	SI_GetNumIgnores_Old		= GetNumIgnores
	GetNumIgnores			= SI_GetNumIgnores_New

	SI_GetSelectedIgnore_Old	= GetSelectedIgnore
	GetSelectedIgnore		= SI_GetSelectedIgnore_New

	SI_SetSelectedIgnore_Old	= SetSelectedIgnore
	SetSelectedIgnore		= SI_SetSelectedIgnore_New

	SI_StaticPopup_Show_Old		= StaticPopup_Show
	StaticPopup_Show		= SI_StaticPopup_Show_New

	SI_TradeFrame_OnEvent_Old	= TradeFrame_OnEvent
	TradeFrame_OnEvent		= SI_TradeFrame_OnEvent_New

	SI_ChatFrame_OnEvent_Old	= ChatFrame_OnEvent
	ChatFrame_OnEvent		= SI_ChatFrame_OnEvent_New

	if WIM_ChatFrame_OnEvent then
		SI_WIM_ChatFrame_OnEvent_Old	= WIM_ChatFrame_OnEvent
		WIM_ChatFrame_OnEvent		= SI_WIM_ChatFrame_OnEvent_New
	end

	if WhisperFu then
		WhisperFu.OnReceiveWhisper_Old	= WhisperFu.OnReceiveWhisper
		WhisperFu.OnReceiveWhisper	= SI_WhisperFu_OnReceiveWhisper_New
	end

	SI_SendChatMessage_Old		= SendChatMessage
	SendChatMessage			= SI_SendChatMessage_New
end

SI_ApplyFilters = function()

	SI_AddFilter(function(name)
		SI_CheckBanTimes()
		if SI_FindBannedPlayer(name) then
			return true
		end
	end)
	SI_AddFilter(function(name)
		for _, test in SI_Global.BannedParts do
			if string.find(string.lower(name), test) then
				return true
			end
		end
	end)
	SI_AddFilter(function(name)
		if SI_Global.BanSpecial then
			if string.find(name, "[^a-zA-Z]") then
				return true
			end
		end
	end)
end

SI_ReplaceOldIgnores = function()

	local oldNames = {}
	for i = 1, SI_GetNumIgnores_Old() do
		table.insert(oldNames, SI_GetIgnoreName_Old(i))
	end

	for _, name in oldNames do
		SI_DelIgnore_Old(name)
		SI_AddIgnore_New(name, true)
	end
end

------------- Initialization

SI_CreateFrames = function()

	local f = CreateFrame("Frame", "SI_OptionsFrame", IgnoreListFrame)
	-- Height set at function end
	f:SetWidth(185)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	f:SetPoint("TOPLEFT", IgnoreListFrame, "TOPRIGHT", -34, -7)
	f:Hide()

	local pad = 0

	local createHeader = function(text, fontSize)
		local t = f:CreateFontString(nil, "OVERLAY", f)
		t:SetPoint("TOP", f, "TOP", 0, pad)
		t:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
		t:SetTextColor(1,0.82,0)
		t:SetText(text)
		return t
	end

	local createOpt = function(index, var, desc, padding)
		local c = CreateFrame("CheckButton", "SI_Box_"..index, f, "UICheckButtonTemplate")
		c:SetHeight(20)
		c:SetWidth(20)
		c:SetPoint("TOPLEFT", f, "TOPLEFT", 15, padding)
		c:SetScript("OnClick", function()
			SI_Global[var] = c:GetChecked()
		end)
		c:SetChecked(SI_Global[var])

		local ct = f:CreateFontString(nil, "OVERLAY", f)
		ct:SetPoint("LEFT", c, "RIGHT", 0, 0)
		ct:SetFont("Fonts\\FRIZQT__.TTF", 11)
		ct:SetText(desc)

		return c, ct
	end

	pad = pad - 15
	createHeader(string.format("%s %s", S_ADDON_NAME, S_ADDON_VERSION), 12)
	pad = pad - 25

	createOpt(0, "WhisperBlock", S_TEXT_WHISPER_BLOCK, pad)
	pad = pad - 35

	createOpt(0, "WhisperUnignore", S_TEXT_WHISPER_UNIGNORE, pad)
	pad = pad - 35

	createOpt(0, "AutoResponse", S_TEXT_AUTO, pad)
	pad = pad - 30

	createHeader(S_TEXT_EXTRA, 11)
	pad = pad - 25

	createOpt(0, "BanSpecial", S_TEXT_SPECIAL, pad)
	pad = pad - 35

	createHeader(S_TEXT_OPTIONS, 11)
	pad = pad - 15

	local options = {
		{"BanOptWhisper",	S_BAN_WHISPER,	15},
		{"BanOptParty",		S_BAN_PARTY,	15},
		{"BanOptGuild",		S_BAN_GUILD,	15},
		{"BanOptOfficer",	S_BAN_OFFICER,	15},
		{"BanOptSay",		S_BAN_SAY,	15},
		{"BanOptYell",		S_BAN_YELL,	15},
		{"BanOptBg",		S_BAN_BG,	15},
		{"BanOptPublic",	S_BAN_PUBLIC,	15},
		{"BanOptEmote",		S_BAN_EMOTE,	15},
		{"BanOptTrade",		S_BAN_TRADE,	15},
		{"BanOptInvite",	S_BAN_INVITE,	15},
		{"BanOptDuel",		S_BAN_DUEL,	25}
	}

	for i = 1, table.getn(options) do
		local optVar		= options[i][1]
		local optDesc		= options[i][2]
		local optPadding	= options[i][3]
		createOpt(i, optVar, optDesc, pad)
		pad = pad - optPadding
	end

	createHeader(S_TEXT_DURATION, 11)
	pad = pad - 15

	local dd = CreateFrame("Button", "SI_BanDuration", f, "UIDropDownMenuTemplate")
	dd:SetPoint("TOP", f, "TOP", 0, pad)
	UIDropDownMenu_SetWidth(100, dd)
	UIDropDownMenu_JustifyText("LEFT", dd)
	UIDropDownMenu_Initialize(dd, function()
		local info = {}
		for i = 1, table.getn(T_Time_TextOpt) do
			info.text = T_Time_TextOpt[i]
			info.value = i
			info.func = function()
				UIDropDownMenu_SetSelectedID(dd, this:GetID())
				SI_Global.BanDuration = this:GetID()
			end
			info.checked = nil
			UIDropDownMenu_AddButton(info, 1)
		end
	end)
	UIDropDownMenu_SetSelectedID(dd, SI_Global.BanDuration)

	local b = CreateFrame("Button", "SI_OpenButton", IgnoreListFrame, "UIPanelButtonTemplate")
	b:SetHeight(21)
	b:SetWidth(130)
	b:SetText(S_ADDON_NAME)
	b:SetPoint("TOPLEFT", IgnoreListFrame, "TOPLEFT", 210, -50)
	b:SetScript("OnClick", function()
		if f:IsShown() then
			f:Hide()
		else
			f:Show()
		end
	end)

	f:SetHeight(40 + (- pad))
end

SI_MainFrame = CreateFrame("frame")
SI_MainFrame:RegisterEvent("ADDON_LOADED")
SI_MainFrame:RegisterEvent("IGNORELIST_UPDATE")
SI_MainFrame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if string.lower(arg1) == S_ADDON_DIR then

			if not SI_Global then
				SI_Global = {
					BannedPlayers	= {},
					BannedSelected	= 1,
					BannedParts	= {},

					WhisperBlock	= false,
					WhisperUnignore	= true,
					AutoResponse	= false,
					BanSpecial	= false,
					BanDuration	= T_FOREVER,

					BanOptWhisper	= true,
					BanOptParty	= false,
					BanOptGuild	= false,
					BanOptOfficer	= false,
					BanOptSay	= true,
					BanOptYell	= true,
					BanOptBg	= true,
					BanOptPublic	= true,
					BanOptEmote	= true,
					BanOptTrade	= true,
					BanOptInvite	= true,
					BanOptDuel	= true
				}
			end

			SI_HookFunctions()
			SI_CreateFrames()
			SI_ApplyFilters()

			SI_Print(string.format("%s %s loaded.", S_ADDON_NAME, S_ADDON_VERSION))

			SI_CleanUpRelog()
			SI_CheckBanTimes()
		end
	elseif event == "IGNORELIST_UPDATE" then
		SI_ReplaceOldIgnores()
		SI_MainFrame:UnregisterEvent("IGNORELIST_UPDATE")
	end
end)