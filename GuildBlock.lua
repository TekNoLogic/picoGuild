

----------------------------
--      Localization      --
----------------------------

local L = {
	offline = "(.+) has gone offline.";
	online = "|Hplayer:%s|h[%s]|h has come online.";	["has come online"] = "has come online",
	["has gone offline"] = "has gone offline",

	["Guildless"] = "Guildless",
	["Not in a guild"] = "Not in a guild",
}


------------------------------
--      Are you local?      --
------------------------------

local friends, colors = {}, {}
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

GuildBlock = DongleStub("Dongle-1.0"):New("GuildBlock")
local lego = DongleStub("LegoBlock-Beta0"):New("GuildBlock", "50/50", "Interface\\Addons\\GuildBlock\\icon")
--~ if tekDebug then GuildBlock:EnableDebug(1, tekDebug:GetFrame("GuildBlock")) end


----------------------------------
--      Server query timer      --
----------------------------------

local MINDELAY, DELAY = 15, 300
local elapsed, dirty = 0, false
local function OnUpdate(self, el)
	elapsed = elapsed + el
	if (dirty and elapsed >= MINDELAY) or elapsed >= DELAY then
		if IsInGuild() then GuildRoster()
		else elapsed, dirty = 0, false end
	end
end


local orig = GuildRoster
GuildRoster = function(...)
	elapsed, dirty = 0, false
	return orig(...)
end


---------------------------
--      Init/Enable      --
---------------------------

function GuildBlock:Initialize()
	local blockdefaults = {
		locked = false,
		showIcon = true,
		showText = true,
		shown = true,
	}

	self.db = self:InitializeDB("GuildBlockDB", {profile = {block = blockdefaults}}, "global")
end


function GuildBlock:Enable()
	lego:SetDB(self.db.profile.block)

	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	lego:SetScript("OnUpdate", OnUpdate)
	SortGuildRoster("class")
	GuildRoster()
end


------------------------------
--      Event Handlers      --
------------------------------

function GuildBlock:CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L["has come online"]) or string.find(msg, L["has gone offline"]) then dirty = true end
end


function GuildBlock:GUILD_ROSTER_UPDATE()
	local online = 0

	if IsInGuild() then
		for i = 1,GetNumGuildMembers(true) do if select(9, GetGuildRosterInfo(i)) then online = online + 1 end end
		lego:SetText(string.format("%d/%d", online, GetNumGuildMembers(true)))
	else lego:SetText(L["No Guild"]) end
end


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


lego:SetScript("OnLeave", function() GameTooltip:Hide() end)
lego:SetScript("OnEnter", function(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	if IsInGuild() then
		GameTooltip:AddDoubleLine("GuildBlock", GetGuildInfo("player"))
		GameTooltip:AddLine(GetGuildRosterMOTD(), 0, 1, 0, true)
		GameTooltip:AddLine(" ")

		local mylevel = UnitLevel("player")
		for i=1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, area, note, officernote, connected, status = GetGuildRosterInfo(i)
			if connected then
				local levelcolor = (level >= (mylevel - 5) and level <= (mylevel + 5)) and "|cff00ff00" or ""
				GameTooltip:AddDoubleLine(string.format("%s%02d:|cff%s%s|r", levelcolor, level, colors[class:upper()] or "000000", name), "|cffffff00"..note.. " "..officernote.." |cff00ff00("..rank..")")
			end
		end
	else
		GameTooltip:AddLine("GuildBlock")
		GameTooltip:AddLine(L["Not in a guild"])
	end

	GameTooltip:Show()
end)


------------------------------------------
--      Click to open friend panel      --
------------------------------------------

lego:EnableMouse(true)
lego:RegisterForClicks("anyUp")
lego:SetScript("OnClick", function()
	if FriendsFrame:IsVisible() then HideUIPanel(FriendsFrame)
	else
		ToggleFriendsFrame(3)
		FriendsFrame_Update()
		GameTooltip:Hide()
	end
end)

