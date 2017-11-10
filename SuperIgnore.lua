
local name = "SuperIgnore"
local version = "1.3.4"

local SS = {
	["AddonName"]			= name,
	["AddonDir"]			= strlower(name),
	["AddonVersion"] 		= version,

	["AutoResponse"]		= "I'm ignoring you. (" .. name .. " AddOn)",

	["TextOptions"] 		= "Ignore Filter",
	["TextDuration"]		= "Default Ignore Time",
	["TextWhisperBlock"]	= "Do not let me whisper\nignored players",
	["TextWhisperUnignore"]	= "Unignore players if I\nwhisper them",
	["TextAutoResponse"]	= "Notify ignored players\nwho interact with me\n(only once)",
	["TextDebugLog"]		= "Debug: Log ignored\nactions in chat",

	["TextInformation"]		= "Info",
	["TextEnabled"]			= "Enabled",

	["ChatIgnored"]			= "%s is now being ignored. Duration: %s.",
	["ChatUnignored"]		= "%s is no longer being ignored.",
	["ChatBlocked"]			= "Your message was not sent because are ignoring %s.",
	["ChatSelf"]			= "You can't ignore yourself.",

	["BanWhisper"]			= "Whispers",
	["BanParty"]			= "Party / Raid",
	["BanGuild"]			= "Guild Chat",
	["BanOfficer"]			= "Officer Chat",
	["BanSay"]				= "Say",
	["BanYell"]				= "Yell",
	["BanBG"]				= "Battleground",
	["BanChannel"]			= "Public Channels",
	["BanEmote"]			= "Emotes",
	["BanTrade"]			= "Trade Requests",
	["BanInvite"]			= "Invites",
	["BanDuel"]				= "Duels",

	["LogDuel"]				= "[Duel]",
	["LogTrade"]			= "[Trade]",
	["LogInviteGuild"]		= "[Guild Invite]",
	["LogInviteParty"]		= "[Group Invite]",

	["TimeRelog"]			= "Until Relog",
	["TimeHour"]			= "Hour",
	["TimeDay"]				= "Day",
	["TimeWeek"]			= "Week",
	["TimeMonth"]			= "Month",
	["TimeForever"]			= "Forever",
	["TimeAuto"]			= "Auto-Block"
}

local T_RELOG		= 1
local T_HOUR		= 2
local T_DAY			= 3
local T_WEEK		= 4
local T_MONTH		= 5
local T_FOREVER		= 6
local T_AUTOBLOCK	= 7

local TI_RELOG		= -1
local TI_FOREVER	= 1e30 -- lol
local TI_AUTOBLOCK	= 1e31

local B_NAME		= 1
local B_DURATION	= 2
local B_NOTIFIED	= 3

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
	SS.TimeRelog,
	SS.TimeHour,
	SS.TimeDay,
	SS.TimeWeek,
	SS.TimeMonth,
	SS.TimeForever
}

------------- Global

SI_NameFilter = {}
SI_ChatFilter = {}

SI_MainFrame = nil
SI_OptionsFrame = nil
SI_ModsFrame = nil
SI_TimeCheck_Last = 0

SI_Mods = {}
SI_ModsFramePad = 0

SI_Log = {}

------------- Misc

SI_FrameCreateFrame = function(name, width, parent, x, y)
	local f = CreateFrame("Frame", name, parent)

	f:SetWidth(width)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	f:SetPoint("TOPLEFT", parent, "TOPRIGHT", x, y)
	f:Hide()

	return f
end

SI_FrameCreateHeader = function(frame, text, fontSize, pad)
	local t = frame:CreateFontString(nil, "OVERLAY", frame)
	t:SetPoint("TOP", frame, "TOP", 0, pad)
	t:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	t:SetTextColor(1,0.82,0)
	t:SetText(text)
	return t
end

SI_FrameCreateOption = function(frame, name, desc, pad, onclick)
	local c = CreateFrame("CheckButton", name, frame, "UICheckButtonTemplate")
	c:SetHeight(20)
	c:SetWidth(20)
	c:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, pad)
	c:SetScript("OnClick", function()
		onclick(c:GetChecked())
	end)

	local ct = frame:CreateFontString(nil, "OVERLAY", frame)
	ct:SetPoint("LEFT", c, "RIGHT", 0, 0)
	ct:SetFont("Fonts\\FRIZQT__.TTF", 11)
	ct:SetText(desc)

	return c, ct
end

SI_FrameCreateButton = function(frame, text, pad, onclick)
	local b = CreateFrame("Button", text, frame, "UIPanelButtonTemplate")
	b:SetHeight(20)
	b:SetWidth(85)
	b:SetPoint("TOPLEFT", frame, "TOPLEFT", 100, pad)
	b:SetText(text)
	b:SetScript("OnClick", onclick)

	return b
end

------------- Mods

StaticPopupDialogs["SI_ModInfo"] = {
	text = "",
	button1 = TEXT(ACCEPT),
	timeout = 0,
	hideOnEscape = 1
}

SI_ModsGetNumber = function()
	return table.getn(SI_Mods)
end

SI_ModsGetMod = function(index)
	return SI_Mods[index]
end

local createModUI = function(index, mod)
	local f = SI_ModsFrame

	SI_FrameCreateHeader(f, mod.Name, 12, SI_ModsFramePad)
	SI_ModsFramePad = SI_ModsFramePad - 18

	if mod.Description then
		SI_FrameCreateButton(f, SS.TextInformation, SI_ModsFramePad, function()
			local t = mod.Description
			if mod.Help then
				t = t .. "|n|n" .. mod.Help
			end
			StaticPopupDialogs["SI_ModInfo"].text = t
			StaticPopup_Show("SI_ModInfo")
		end)
	end

	local c = CreateFrame("CheckButton", "SI_ModEnable_"..mod.Name, f, "UICheckButtonTemplate")
	c:SetHeight(20)
	c:SetWidth(20)
	c:SetPoint("TOPLEFT", f, "TOPLEFT", 20, SI_ModsFramePad)
	c:SetScript("OnClick", function()
		local checked = c:GetChecked()
		if checked then SI_ModEnable(index) else SI_ModDisable(index) end
	end)
	c:SetChecked(SI_Global.Mods[mod.Name].Enabled)

	local ct = f:CreateFontString(nil, "OVERLAY", f)
	ct:SetPoint("LEFT", c, "RIGHT", 0, 0)
	ct:SetFont("Fonts\\FRIZQT__.TTF", 11)
	ct:SetText(SS.TextEnabled)
	SI_ModsFramePad = SI_ModsFramePad - 20

	if mod.CreateUI then
		SI_ModsFramePad = mod.CreateUI(f, SI_ModsFramePad)
	end
	SI_ModsFramePad = SI_ModsFramePad - 25

	SI_ModsFrameUpdateHeight()
end

SI_ModInstall = function(mod)
	local index = SI_ModsGetNumber() + 1
	SI_Mods[index] = mod

	if not SI_Global.Mods[mod.Name] then
		SI_Global.Mods[mod.Name] = {
			["Enabled"] = false,
			["Vars"] = {}
		}
	end

	createModUI(index, mod)

	if SI_Global.Mods[mod.Name].Enabled then
		SI_ModEnable(index)
	end

	return index
end

SI_ModEnable = function(index)
	local mod = SI_Mods[index]
	SI_Global.Mods[mod.Name].Enabled = true

	if mod.NameFilter then
		SI_AddNameFilter(mod.NameFilter)
	end
	if mod.ChatFilter then
		SI_AddChatFilter(mod.ChatFilter)
	end
	if mod.OnEnable then
		mod.OnEnable()
	end
end

SI_ModDisable = function(index)
	local mod = SI_Mods[index]
	SI_Global.Mods[mod.Name].Enabled = false

	if mod.NameFilter then
		SI_DelNameFilter(mod.NameFilter)
	end
	if mod.ChatFilter then
		SI_DelChatFilter(mod.ChatFilter)
	end
	if mod.OnDisable then
		mod.OnDisable()
	end
end

SI_ModGetVar = function(mod, name)
	local modinfo = SI_Global.Mods[mod.Name]
	return modinfo.Vars[name]
end

SI_ModSetVar = function(mod, name, value)
	local modinfo = SI_Global.Mods[mod.Name]
	modinfo.Vars[name] = value
end

------------- Filter

SI_AddNameFilter = function(filter)
	table.insert(SI_NameFilter, filter)
end
SI_DelNameFilter = function(filter)
	for k, v in SI_NameFilter do
		if v == filter then
			table.remove(SI_NameFilter, k)
		end
	end
end

SI_AddChatFilter = function(filter)
	table.insert(SI_ChatFilter, filter)
end
SI_DelChatFilter = function(filter)
	for k, v in SI_ChatFilter do
		if v == filter then
			table.remove(SI_ChatFilter, k)
		end
	end
end

SI_FilterIsPlayerIgnored = function(name)
	if name == UnitName("player") then
		return false
	end

	for _, filter in SI_NameFilter do
		if filter(name) then
			SI_CheckAutoBlock(name)
			return true
		end
	end

	return false
end

SI_FilterIsChatIgnored = function(message, name, type)
	if name == UnitName("player") then
		return false
	end

	for _, filter in SI_ChatFilter do
		if filter(message, name, type) then
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
SI_BannedClearRelog = function()
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
SI_BannedCheckTimes = function()
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
SI_BannedCheckTimesPeriodic = function()
	if GetTime() - SI_TimeCheck_Last > 60 then
		SI_TimeCheck_Last = GetTime()
		SI_BannedCheckTimes()
	end
end
SI_FormatTimeNoColor = function(t)

	local _s = function(n)
		if n == 1 then return "" else return "s" end
	end

	if t == TI_FOREVER then
		return SS.TimeForever, "ff00ff"
	elseif t == TI_RELOG then
		return SS.TimeRelog, "00ff00"
	elseif t == TI_AUTOBLOCK then
		return SS.TimeAuto, "ffffff"
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
	local str, color = SI_FormatTimeNoColor(t)
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

SI_BannedGetIndex = function(name)
	for index, banned in SI_Global.BannedPlayers do
		if banned[B_NAME] == name then
			return index
		end
	end

	return nil
end

SI_BannedGetDuration = function(index)
	return SI_Global.BannedPlayers[index][B_DURATION]
end
SI_BannedSetDuration = function(index, duration)
	SI_Global.BannedPlayers[index][B_DURATION] = duration
end
SI_BannedGetName = function(index)
	return SI_Global.BannedPlayers[index][B_NAME]
end
SI_BannedSetName = function(index, name)
	SI_Global.BannedPlayers[index][B_NAME] = name
end
SI_BannedGetNotified = function(index)
	return SI_Global.BannedPlayers[index][B_NOTIFIED]
end
SI_BannedSetNotified = function(index, notified)
	SI_Global.BannedPlayers[index][B_NOTIFIED] = notified
end

SI_BannedSortByTime = function()
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
		SI_Print(string.format(SS.ChatBlocked, name))
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
		local index = SI_BannedGetIndex(name)
		if index then
			if not SI_BannedGetNotified(index) then
				SI_BannedSetNotified(index, true)
				SI_SendChatMessage_Old(SS.AutoResponse, "WHISPER", nil, name)
			end
		end
	end
end

SI_CheckAutoBlock = function(name)
	local index = SI_BannedGetIndex(name)
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
			if found and name and SI_FilterIsPlayerIgnored(name) then
				SI_LogIgnore(SS.LogInviteGuild, name)
				return true
			end

			found, _, name = SI_StringFindPattern(arg1, ERR_INVITED_TO_GROUP_S)
			if found and name and SI_FilterIsPlayerIgnored(name) then
				SI_LogIgnore(SS.LogInviteParty, name)
				return true
			end

			if SI_FilterIsChatIgnored(arg1, nil, type) then
				SI_LogIgnore(arg1, "SYSTEM")
				return true
			end
		end

		if arg1 and arg2 and type == "WHISPER_INFORM" then
			if arg1 == SS.AutoResponse then
				return true
			end
		end

		if arg2 and SI_IsChannelBanned(type) then
			if SI_FilterIsPlayerIgnored(arg2) then
				if type == "WHISPER" then
					SI_CheckAutoResponse(arg2)
				end

				SI_LogIgnore(arg1, arg2)
				return true
			end

			if SI_FilterIsChatIgnored(arg1, arg2, type) then
				SI_LogIgnore(arg1, arg2)
				return true
			end
		end
	end

	return false
end

------------- Overrides


SI_AddIgnore_Old			= nil
SI_AddOrDelIgnore_Old		= nil
SI_DelIgnore_Old			= nil
SI_GetIgnoreName_Old		= nil
SI_GetNumIgnores_Old		= nil
SI_GetSelectedIgnore_Old	= nil
SI_SetSelectedIgnore_Old	= nil
SI_TradeFrame_OnEvent_Old	= nil
SI_StaticPopup_Show_Old		= nil
SI_ChatFrame_OnEvent_Old	= nil
SI_WIM_ChatFrame_OnEvent_Old= nil
SI_SendChatMessage_Old		= nil

SI_AddIgnore_New = function(name, quiet, banTime)

	name = SI_FixPlayerName(name)
	if name == UnitName("player") then
		SI_Print(SS.ChatSelf)
		return
	end

	if not banTime then
		banTime = SI_CalcBanTime()
	end

	local index = SI_BannedGetIndex(name)
	if index then
		SI_BannedSetDuration(index, banTime)
	else
		table.insert(SI_Global.BannedPlayers, {name, banTime, false})
	end

	SI_BannedSortByTime()
	IgnoreList_Update()

	if not quiet then
		SI_Print(string.format(SS.ChatIgnored, name, SI_FormatTimeNoColor(banTime)))
	end
end

SI_AddOrDelIgnore_New = function(name)
	local index = SI_BannedGetIndex(name)
	if index then
		SI_DelIgnore_New(name)
	else
		SI_AddIgnore_New(name)
	end
end

SI_DelIgnore_New = function(name, quiet)

	name = string.gsub(name, "^|cff([^|]+)|r ", "")
	name = SI_FixPlayerName(name)

	local index = SI_BannedGetIndex(name)
	if index then
		 table.remove(SI_Global.BannedPlayers, index)
		 SI_FixBannedSelected()
		 IgnoreList_Update()

		 if not quiet then
			SI_Print(string.format(SS.ChatUnignored, name))
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
			if SI_FilterIsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				DeclineGroup()
				SI_LogIgnore(SS.LogInviteParty, name)
				return
			end
		elseif which == "GUILD_INVITE" then
			if SI_FilterIsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				DeclineGuild()
				SI_LogIgnore(SS.LogInviteGuild, name)
				return
			end
		end
	end
	if SI_Global.BanOptDuel then
		if which == "DUEL_REQUESTED" then
			if SI_FilterIsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				CancelDuel()
				SI_LogIgnore(SS.LogDuel, name)
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
			if SI_FilterIsPlayerIgnored(name) then
				SI_CheckAutoResponse(name)
				CloseTrade()
				SI_LogIgnore(SS.LogTrade, name)
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
	if chatType == "WHISPER" and SI_FilterIsPlayerIgnored(channel) then
		if SI_CheckInteractRules(channel) then
			return
		end
	end
	SI_SendChatMessage_Old(msg, chatType, lang, channel)
end


------------- Main Code

SI_HookFunctions = function()

	SI_AddIgnore_Old			= AddIgnore
	AddIgnore					= SI_AddIgnore_New

	SI_AddOrDelIgnore_Old		= AddOrDelIgnore
	AddOrDelIgnore				= SI_AddOrDelIgnore_New

	SI_DelIgnore_Old			= DelIgnore
	DelIgnore					= SI_DelIgnore_New

	SI_GetIgnoreName_Old		= GetIgnoreName
	GetIgnoreName				= SI_GetIgnoreName_New

	SI_GetNumIgnores_Old		= GetNumIgnores
	GetNumIgnores				= SI_GetNumIgnores_New

	SI_GetSelectedIgnore_Old	= GetSelectedIgnore
	GetSelectedIgnore			= SI_GetSelectedIgnore_New

	SI_SetSelectedIgnore_Old	= SetSelectedIgnore
	SetSelectedIgnore			= SI_SetSelectedIgnore_New

	SI_StaticPopup_Show_Old		= StaticPopup_Show
	StaticPopup_Show			= SI_StaticPopup_Show_New

	SI_TradeFrame_OnEvent_Old	= TradeFrame_OnEvent
	TradeFrame_OnEvent			= SI_TradeFrame_OnEvent_New

	SI_ChatFrame_OnEvent_Old	= ChatFrame_OnEvent
	ChatFrame_OnEvent			= SI_ChatFrame_OnEvent_New

	if WIM_ChatFrame_OnEvent then
		SI_WIM_ChatFrame_OnEvent_Old	= WIM_ChatFrame_OnEvent
		WIM_ChatFrame_OnEvent			= SI_WIM_ChatFrame_OnEvent_New
	end

	if WhisperFu then
		WhisperFu.OnReceiveWhisper_Old	= WhisperFu.OnReceiveWhisper
		WhisperFu.OnReceiveWhisper		= SI_WhisperFu_OnReceiveWhisper_New
	end

	SI_SendChatMessage_Old		= SendChatMessage
	SendChatMessage				= SI_SendChatMessage_New
end

SI_ApplyFilters = function()

	SI_AddNameFilter(function(name)
		SI_BannedCheckTimesPeriodic()
		local index = SI_BannedGetIndex(name)
		if index and SI_BannedGetDuration(index) ~= TI_AUTOBLOCK then
			return true
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


------------- Log


SI_LogIgnore = function(text, name)
	local logSuccess = SI_LogAdd(text, name)

	if logSuccess and SI_Global.DebugLog then
		SI_Print("IGNORED: " .. name .. ": " .. text)
	end
end

SI_LogAdd = function(text, name)
	for _, msg in SI_Log do
		if msg[1] == name and msg[2] == text then
			return false
		end
	end
	table.insert(SI_Log, {[1] = name, [2] = text})
	return true
end

SI_LogGetByName = function(name)
	local log = {}

	for _, msg in SI_Log do
		if msg[1] == name then
			table.insert(log, msg[2])
		end
	end

	return log
end

------------- Frames


SI_CreateOptionsFrame = function()

	-- Height set at function end
	SI_OptionsFrame = SI_FrameCreateFrame("SI_OptionsFrame", 185, IgnoreListFrame, -34, -7)
	local f = SI_OptionsFrame

	local pad = 0

	local createOpt = function(index, var, desc, padding, onclick)
		local c, ct = SI_FrameCreateOption(f, "SI_Box_"..index, desc, padding, function(checked)
			SI_Global[var] = checked
			if onclick then onclick(checked) end
		end)
		c:SetChecked(SI_Global[var])

		return c, ct
	end

	pad = pad - 15
	SI_FrameCreateHeader(f, string.format("%s %s", SS.AddonName, SS.AddonVersion), 12, pad)
	pad = pad - 25

	createOpt(100, "WhisperBlock", SS.TextWhisperBlock, pad, function(checked)
		if checked and SI_Box_101:GetChecked() then SI_Box_101:Click() end
	end)
	pad = pad - 35

	createOpt(101, "WhisperUnignore", SS.TextWhisperUnignore, pad, function(checked)
		if checked and SI_Box_100:GetChecked() then SI_Box_100:Click() end
	end)
	pad = pad - 35

	createOpt(102, "AutoResponse", SS.TextAutoResponse, pad)
	pad = pad - 35

	createOpt(103, "DebugLog", SS.TextDebugLog, pad)
	pad = pad - 35

	SI_FrameCreateHeader(f, SS.TextOptions, 11, pad)
	pad = pad - 15

	local options = {
		{"BanOptWhisper",	SS.BanWhisper,	15},
		{"BanOptParty",		SS.BanParty,	15},
		{"BanOptGuild",		SS.BanGuild,	15},
		{"BanOptOfficer",	SS.BanOfficer,	15},
		{"BanOptSay",		SS.BanSay,		15},
		{"BanOptYell",		SS.BanYell,		15},
		{"BanOptBg",		SS.BanBG,		15},
		{"BanOptPublic",	SS.BanChannel,	15},
		{"BanOptEmote",		SS.BanEmote,	15},
		{"BanOptTrade",		SS.BanTrade,	15},
		{"BanOptInvite",	SS.BanInvite,	15},
		{"BanOptDuel",		SS.BanDuel,		25}
	}

	for i = 1, table.getn(options) do
		local optVar		= options[i][1]
		local optDesc		= options[i][2]
		local optPadding	= options[i][3]
		createOpt(i, optVar, optDesc, pad)
		pad = pad - optPadding
	end

	SI_FrameCreateHeader(f, SS.TextDuration, 11, pad)
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

	f:SetHeight(40 + (- pad))
end

SI_CreateModsFrame = function()
	SI_ModsFrame = SI_FrameCreateFrame("SI_ModsFrame", 210, SI_OptionsFrame, -10, 0)
	SI_ModsFramePad = -15
	SI_ModsFrameUpdateHeight()
end

SI_ModsFrameUpdateHeight = function()
	SI_ModsFrame:SetHeight(20 + (- SI_ModsFramePad))
end

SI_CreateTooltips = function()
	for i = 1, 20 do
		local index = i
		local b = getglobal("FriendsFrameIgnoreButton" .. index)
		b:SetScript("OnEnter", function()
			local fauxIndex = FauxScrollFrame_GetOffset(FriendsFrameIgnoreScrollFrame) + index
			local name = SI_BannedGetName(fauxIndex)
			local log = SI_LogGetByName(name)
			GameTooltip:SetOwner(b, "ANCHOR_CURSOR")
			GameTooltip:SetText(name)
			for _, v in log do
				GameTooltip:AddLine(v, 1, 1, 1)
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

SI_CreateShowButton = function()
	local b = CreateFrame("Button", "SI_OpenButton", IgnoreListFrame, "UIPanelButtonTemplate")
	b:SetHeight(21)
	b:SetWidth(130)
	b:SetText(SS.AddonName)
	b:SetPoint("TOPLEFT", IgnoreListFrame, "TOPLEFT", 210, -50)
	b:SetScript("OnClick", function()
		if SI_OptionsFrame:IsShown() then
			SI_OptionsFrame:Hide()
			SI_ModsFrame:Hide()
		else
			SI_OptionsFrame:Show()
			if SI_ModsGetNumber() > 0 then
				SI_ModsFrame:Show()
			end
		end
	end)
end

SI_CreateFrames = function()
	SI_CreateOptionsFrame()
	SI_CreateModsFrame()
	SI_CreateTooltips()
	SI_CreateShowButton()
end

------------- Initialization

SI_MainFrame = CreateFrame("frame")
SI_MainFrame:RegisterEvent("ADDON_LOADED")
SI_MainFrame:RegisterEvent("IGNORELIST_UPDATE")
SI_MainFrame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if string.lower(arg1) == SS.AddonDir then

			if not SI_Global then
				SI_Global = {
					BannedPlayers	= {},
					BannedSelected	= 1,

					WhisperBlock	= false,
					WhisperUnignore	= true,
					AutoResponse	= false,
					DebugLog		= false,
					BanDuration		= T_FOREVER,

					BanOptWhisper	= true,
					BanOptParty		= false,
					BanOptGuild		= false,
					BanOptOfficer	= false,
					BanOptSay		= true,
					BanOptYell		= true,
					BanOptBg		= true,
					BanOptPublic	= true,
					BanOptEmote		= true,
					BanOptTrade		= true,
					BanOptInvite	= true,
					BanOptDuel		= true,

					Mods			= {},
				}
			end

			SI_HookFunctions()
			SI_CreateFrames()
			SI_ApplyFilters()

			SI_Print(string.format("%s %s loaded.", SS.AddonName, SS.AddonVersion))

			SI_BannedClearRelog()
			SI_BannedCheckTimes()
		end
	elseif event == "IGNORELIST_UPDATE" then
		SI_MainFrame:UnregisterEvent("IGNORELIST_UPDATE")
		SI_ReplaceOldIgnores()
	end
end)