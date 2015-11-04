
------------- Constants

local S_ADDON_NAME	= "Super Ignore"
local S_ADDON_DIR	= "superignore"
local S_TEXT_OPTIONS	= "Ignore Filter"
local S_TEXT_DURATION	= "Default Ignore Time"
local S_BAN_SPECIAL	= "Auto-Block players\nwith special characters\nin their names"
local S_BAN_WHISPER	= "Whispers"
local S_BAN_PARTY	= "Party Chat"
local S_BAN_GUILD	= "Guild Chat"
local S_BAN_SAY		= "Say"
local S_BAN_YELL	= "Yell"
local S_BAN_PUBLIC	= "Public Channels"
local S_BAN_EMOTE	= "Emotes"
local S_BAN_TRADE	= "Trade Requests"
local S_BAN_INVITE	= "Invitations"

local T_FOREVER		= 1
local T_MONTH		= 2
local T_WEEK		= 3
local T_DAY			= 4
local T_HOUR		= 5
local T_RELOG		= 6

local TS_FOREVER	= -1
local TS_RELOG		= -2

local T_Duration = {
	"Forever",
	"Month",
	"Week",
	"Day",
	"Hour",
	"Until Relog",
}
local T_Time = {
	TS_FOREVER,
	60 * 60 * 24 * 30,
	60 * 60 * 24 * 7,
	60 * 60 * 24,
	60 * 60,
	TS_RELOG
}

------------- Helper

--[[
p = function(msg)
	DEFAULT_CHAT_FRAME:AddMessage("SI "..msg)
end
]]
local GetMessageInfo = function(msg)

	local found, chan, name, name2

	-- Channel
	found, _, chan, name = string.find(msg, "^%[([^%]]+)%].*|Hplayer:([^|]+)|h")
	if found and chan and name then
		return name, chan
	end

	-- Say, Yell, Whisper
	found, _, name, name2, chan = string.find(msg, "^|Hplayer:([^|]+)|h%[([^%]]+)%]|h ([^:]+):")
	if found and name and name2 and chan then
		return name, chan
	end

	-- Emote
	found, _, name = string.find(msg, "^([^ ]+) ")
	if found and name then
		return name, "emote"
	end

	return nil
end

local IsChannelBanned = function(chan)
	local g = SI_Global
	--p("CHANNEL "..chan)
	if chan == "whispers"	then return g.BanOptWhisper end
	if chan == "Party"		then return g.BanOptParty end
	if chan == "Guild"		then return g.BanOptGuild end
	if chan == "says"		then return g.BanOptSay end
	if chan == "yells"		then return g.BanOptYell end
	if chan == "emote"		then return g.BanOptEmote end
	return g.BanOptPublic
end

local IsMessageIgnored = function(msg)
	local name, chan = GetMessageInfo(msg)
	if name and SI_IsPlayerIgnored(name) and IsChannelBanned(chan) then
		return true
	else
		return false
	end
end

local CalcBanTime = function()
	local t = T_Time[SI_Global.BanDuration]
	if t < 0 then
		return t
	else
		return time() + t
	end
end
local IsBanTimeOver = function(t)
	if t < 0 then
		return false
	else
		return time() > t
	end
end
local UnbanRelog = function()
	local unbanNames = {}
	for _, banned in SI_Global.BannedPlayers do
		if banned[2] == TS_RELOG then
			table.insert(unbanNames, banned[1])
		end
	end

	for _, name in unbanNames do
		DelIgnore(name)
	end
end
local CheckBanTimes = function()
	local unbanNames = {}
	for _, banned in SI_Global.BannedPlayers do
		if IsBanTimeOver(banned[2]) then
			table.insert(unbanNames, banned[1])
		end
	end

	for _, name in unbanNames do
		DelIgnore(name)
	end
end
local FormatTimeNoStyle = function(t)

	local _s = function(n)
		if n == 1 then return "" else return "s" end
	end

	if t == TS_FOREVER then
		return T_Duration[T_FOREVER], "ff00ff"
	elseif t == TS_RELOG then
		return T_Duration[T_RELOG], "00ff00"
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
local FormatTime = function(t)
	local str, color = FormatTimeNoStyle(t)
	return "|cff" .. color .. "[" .. str .. "]|r "
end

local FixPlayerName = function(name)
	return string.gsub(name, "^%l", string.upper)
end

local FixBannedSelected = function()
	 local selected = SI_Global.BannedSelected
	 if selected > 1 and selected > GetNumIgnores() then
		SI_Global.BannedSelected = selected - 1
	 end
end

local FindBannedPlayer = function(name)
	for index, banned in SI_Global.BannedPlayers do
		if banned[1] == name then
			return index
		end
	end

	return nil
end

------------- Global

SI_IsPlayerIgnored = function(name)

	if FindBannedPlayer(name) then
		return true
	end

	name = string.lower(name)

	for _, test in SI_Global.BannedParts do
		if string.find(name, test) then
			return true
		end
	end

	if SI_Global.BanSpecial then
		if string.find(name, "[^a-z]") then
			return true
		end
	end

	return false
end

------------- Overrides

local AddIgnore_Old				= nil
local AddIgnore_New				= nil
local AddOrDelIgnore_Old		= nil
local AddOrDelIgnore_New		= nil
local DelIgnore_Old				= nil
local DelIgnore_New				= nil
local GetIgnoreName_Old			= nil
local GetIgnoreName_New			= nil
local GetNumIgnores_Old			= nil
local GetNumIgnores_New			= nil
local GetSelectedIgnore_Old		= nil
local GetSelectedIgnore_New		= nil
local SetSelectedIgnore_Old		= nil
local SetSelectedIgnore_New		= nil
local TradeFrame_OnEvent_Old	= nil
local TradeFrame_OnEvent_New	= nil
local StaticPopup_Show_Old		= nil
local StaticPopup_Show_New		= nil

AddIgnore_New = function(name)

	name = FixPlayerName(name)

	if not FindBannedPlayer(name) then
		table.insert(SI_Global.BannedPlayers, {name, CalcBanTime()})
		IgnoreList_Update()
	end
end

AddOrDelIgnore_New = function(name)
	local oldLen = GetNumIgnores()
	DelIgnore(name)
	if oldLen == GetNumIgnores() then
		AddIgnore(name)
	end
end

DelIgnore_New = function(name)

	name = string.gsub(name, "^|cff([^|]+)|r ", "")
	name = FixPlayerName(name)

	local index = FindBannedPlayer(name)
	if index then
		 table.remove(SI_Global.BannedPlayers, index)
		 FixBannedSelected()
		 IgnoreList_Update()
	end
end

GetIgnoreName_New = function(index)
	local banned = SI_Global.BannedPlayers[index]
	if banned then
		return FormatTime(banned[2]) .. banned[1]
	else
		return UNKNOWN
	end
end

GetNumIgnores_New = function()
	return table.getn(SI_Global.BannedPlayers)
end

GetSelectedIgnore_New = function()
	return SI_Global.BannedSelected
end

SetSelectedIgnore_New = function(index)
	SI_Global.BannedSelected = index
end

local StaticPopup_Show_New = function(type, a1, a2, a3)
	if SI_Global.BanOptInvite then
		if type == "PARTY_INVITE" then
			if SI_IsPlayerIgnored(a1) then
				DeclineGroup()
				return
			end
		elseif type == "GUILD_INVITE" then
			if SI_IsPlayerIgnored(a1) then
				DeclineGuild()
				return
			end
		end
	end

	StaticPopup_Show_Old(type, a1, a2, a3)
end

TradeFrame_OnEvent_New = function()
	if SI_Global.BanOptTrade then
		if event == "TRADE_SHOW" or event == "TRADE_UPDATE" then
			if SI_IsPlayerIgnored(UnitName("NPC")) then
				CloseTrade()
				return
			end
		end
	end

	TradeFrame_OnEvent_Old()
end

------------- Main Code

local HookChatFrame = function(frameName)

	local frame = getglobal(frameName)
	if not frame then return end

	local originalAddMessage = frame.AddMessage
	if not originalAddMessage then return end

	frame.AddMessage = function(self, msg, ...)
		--originalAddMessage(self, string.gsub(msg, "|", "||"))
		if not IsMessageIgnored(msg) then
			originalAddMessage(self, msg, unpack(arg))
		end
	end
end

local HookFunctions = function()

	StaticPopup_Show_Old	= StaticPopup_Show
	StaticPopup_Show		= StaticPopup_Show_New

	TradeFrame_OnEvent_Old	= TradeFrame_OnEvent
	TradeFrame_OnEvent		= TradeFrame_OnEvent_New

	AddIgnore_Old			= AddIgnore
	AddIgnore				= AddIgnore_New

	AddOrDelIgnore_Old		= AddOrDelIgnore
	AddOrDelIgnore			= AddOrDelIgnore_New

	DelIgnore_Old			= DelIgnore
	DelIgnore				= DelIgnore_New

	GetIgnoreName_Old		= GetIgnoreName
	GetIgnoreName			= GetIgnoreName_New

	GetNumIgnores_Old		= GetNumIgnores
	GetNumIgnores			= GetNumIgnores_New

	GetSelectedIgnore_Old	= GetSelectedIgnore
	GetSelectedIgnore		= GetSelectedIgnore_New

	SetSelectedIgnore_Old	= SetSelectedIgnore
	SetSelectedIgnore		= SetSelectedIgnore_New

	for i = 1, 7 do
		HookChatFrame("ChatFrame" .. i)
	end
end

local ReplaceOldIgnores = function()

	local oldNames = {}
	for i = 1, GetNumIgnores_Old() do
		table.insert(oldNames, GetIgnoreName_Old(i))
	end

	for _, name in oldNames do
		DelIgnore_Old(name)
		AddIgnore_New(name)
	end
end

------------- Initialization

local CreateFrames = function()

	local f = CreateFrame("Frame", "SI_OptionsFrame", IgnoreListFrame)
	f:SetHeight(300)
	f:SetWidth(185)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	f:SetPoint("TOPLEFT", IgnoreListFrame, "TOPRIGHT", -34, -35)
	f:Hide()

	local pad = -15

	local t = f:CreateFontString(nil, "OVERLAY", f)
	t:SetPoint("TOP", f, "TOP", 0, pad)
	t:SetFont("Fonts\\FRIZQT__.TTF", 12)
	t:SetTextColor(1,0.82,0)
	t:SetText(S_ADDON_NAME)

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
	end

	pad = pad - 25
	createOpt(0, "BanSpecial", S_BAN_SPECIAL, pad)

	pad = pad - 35
	local ti = f:CreateFontString(nil, "OVERLAY", f)
	ti:SetPoint("TOP", f, "TOP", 0, pad)
	ti:SetFont("Fonts\\FRIZQT__.TTF", 11)
	ti:SetTextColor(1,0.82,0)
	ti:SetText(S_TEXT_OPTIONS)

	local options = {
		{"BanOptWhisper",	S_BAN_WHISPER,	15},
		{"BanOptParty",		S_BAN_PARTY,	15},
		{"BanOptGuild",		S_BAN_GUILD,	15},
		{"BanOptSay",		S_BAN_SAY,		15},
		{"BanOptYell",		S_BAN_YELL,		15},
		{"BanOptPublic",	S_BAN_PUBLIC,	15},
		{"BanOptEmote",		S_BAN_EMOTE,	15},
		{"BanOptTrade",		S_BAN_TRADE,	15},
		{"BanOptInvite",	S_BAN_INVITE,	15}
	}

	for i = 1, table.getn(options) do
		local optVar		= options[i][1]
		local optDesc		= options[i][2]
		local optPadding	= options[i][3]
		pad = pad - optPadding
		createOpt(i, optVar, optDesc, pad)
	end

	pad = pad - 30
	local dt = f:CreateFontString(nil, "OVERLAY", f)
	dt:SetPoint("TOP", f, "TOP", 0, pad)
	dt:SetFont("Fonts\\FRIZQT__.TTF", 11)
	dt:SetTextColor(1,0.82,0)
	dt:SetText(S_TEXT_DURATION)

	pad = pad - 15
	local dd = CreateFrame("Button", "SI_BanDuration", f, "UIDropDownMenuTemplate")
	dd:SetPoint("TOP", f, "TOP", 0, pad)
	UIDropDownMenu_SetWidth(100, dd)
	UIDropDownMenu_JustifyText("LEFT", dd)
	UIDropDownMenu_Initialize(dd, function()
		local info = {}
		for i = 1, table.getn(T_Time) do
			info.text = T_Duration[i]
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
end

local MainFrame = CreateFrame("frame")
MainFrame:RegisterEvent("ADDON_LOADED")
MainFrame:RegisterEvent("IGNORELIST_UPDATE")
MainFrame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if string.lower(arg1) == S_ADDON_DIR then

			if not SI_Global then
				SI_Global = {
					BannedPlayers	= {},
					BannedSelected	= 1,
					BannedParts		= {},

					BanSpecial		= false,
					BanDuration		= T_FOREVER,

					BanOptWhisper	= true,
					BanOptParty		= false,
					BanOptGuild		= false,
					BanOptSay		= true,
					BanOptYell		= true,
					BanOptPublic	= true,
					BanOptEmote		= true,
					BanOptTrade		= true,
					BanOptInvite	= true
				}
			end

			HookFunctions()
			CreateFrames()

			UnbanRelog()
			CheckBanTimes()

			DEFAULT_CHAT_FRAME:AddMessage(S_ADDON_NAME .. " loaded.")
		end
	elseif event == "IGNORELIST_UPDATE" then
		ReplaceOldIgnores()
		MainFrame:UnregisterEvent("IGNORELIST_UPDATE")
	end
end)