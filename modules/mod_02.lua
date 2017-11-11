
local getlines = function(text)
	text = text .. "\n"
	local lines = {}
	local index = 1
	local pos = 0
	while true do
		local newpos = strfind(text, "\n", pos, true)
		if not newpos then
			break
		end
		local line = strsub(text, pos, newpos - 1)
		if line ~= "" then
			lines[index] = line
			index = index + 1
		end
		pos = newpos + 1
	end
	return lines
end

local gui = nil
local box = nil
local phrases = {}

local m = {}

m.chatfilter = function(message, name, type)
	if name and FriendLib:IsFriend(name) then
		return false
	end

	message = strupper(message)
	for _, p in phrases do
		if strfind(message, p) then
			return true
		end
	end
	return false
end
m.updatePhrases = function()
	local text = box:GetText()
	SI_ModSetVar(m.mod, "Text", text)
	phrases = {}
	for _, p in getlines(text) do
		if p ~= "" then
			table.insert(phrases, strupper(p))
		end
	end
end

m.createFrame = function(frame)
	gui = SI_FrameCreateFrame("SI_CMB", 500, frame, -10, 0)
	gui:SetHeight(400)

	box = CreateFrame("EditBox", "SI_CMB_Box", gui)
	box:SetMultiLine(true)
	box:SetAutoFocus(true)
	box:EnableMouse(true)
	box:SetMaxLetters(99999)
	box:SetFont("Fonts\\ARIALN.ttf", 13, "THINOUTLINE")
	box:SetWidth(400)
	box:SetHeight(3000)
	box:SetScript("OnEscapePressed", function() gui:Hide() end)
	box:SetScript("OnTextChanged", function() m.updatePhrases() end)

	local scroll = CreateFrame("scrollFrame", "SI_CMB_Scroll", gui, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", gui, "TOPLEFT", 15, -15)
	scroll:SetPoint("BOTTOMRIGHT", gui, "BOTTOMRIGHT", -37, 15)
	scroll:SetScrollChild(box)

	box:SetText(SI_ModGetVar(m.mod, "Text") or "")
end

m.createUI = function(frame, pad)
	m.createFrame(frame)
	SI_FrameCreateButton(frame, "Phrases", pad, function()
		if gui:IsShown() then
			gui:Hide()
		else
			gui:Show()
		end
	end)
	return pad - 15
end

m.mod = {
	["Name"] = "Custom Filter",
	["Description"] = "Blocks all messages containing a phrase.",
	["Help"] = "Enter one phrase per line in the 'Phrases' window. Players that write messages containing one of these phrases will be temporarily ignored. Friends, party and guild members are never ignored.",
	["OnEnable"] = m.updatePhrases,
	["OnDisable"] = nil,
	["CreateUI"] = m.createUI,
	["NameFilter"] = nil,
	["ChatFilter"] = m.chatfilter,
}

local f = CreateFrame("frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SI_ModInstall(m.mod)
end)
