

----------------------------
--      Localization      --
----------------------------

local L = {
	offline = "(.+) has gone offline.";
	online = "|Hplayer:%s|h[%s]|h has come online.";	["has come online"] = "has come online",
	["has gone offline"] = "has gone offline",

	["No Guild"] = "No Guild",
	["Not in a guild"] = "Not in a guild",
}


------------------------------
--      Are you local?      --
------------------------------

local mejoin = UnitName("player").." has joined the guild."
local friends, colors = {}, {}
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("picoGuild", {type = "data source", icon = "Interface\\Addons\\picoGuild\\icon", text = L["No Guild"]})
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)


----------------------------------
--      Server query timer      --
----------------------------------

local MINDELAY, DELAY = 15, 300
local elapsed, dirty = 0, false
f:Hide()
f:SetScript("OnUpdate", function(self, elap)
	elapsed = elapsed + elap
	if (dirty and elapsed >= MINDELAY) or elapsed >= DELAY then
		if IsInGuild() then GuildRoster() else elapsed, dirty = 0, false end
	end
end)


local orig = GuildRoster
GuildRoster = function(...)
	elapsed, dirty = 0, false
	return orig(...)
end


---------------------------
--      Init/Enable      --
---------------------------

function f:PLAYER_LOGIN()
	LibStub("tekKonfig-AboutPanel").new(nil, "picoGuild")

	self:Show()
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	SortGuildRoster("class")
	if IsInGuild() then GuildRoster() end

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


------------------------------
--      Event Handlers      --
------------------------------

function f:CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L["has come online"]) or string.find(msg, L["has gone offline"]) or msg == mejoin then dirty = true end
end


function f:GUILD_ROSTER_UPDATE()
	local online = 0

	if IsInGuild() then
		for i = 1,GetNumGuildMembers(true) do if select(9, GetGuildRosterInfo(i)) then online = online + 1 end end
		dataobj.text = string.format("%d/%d", online, GetNumGuildMembers(true))
	else dataobj.text = L["No Guild"] end
end


------------------------
--      Tooltip!      --
------------------------

local tip = LibStub("tektip-1.0").new(6, "LEFT", "LEFT", "CENTER", "RIGHT", "RIGHT", "RIGHT")
local lastanchor
function dataobj.OnLeave() tip:Hide() end
function dataobj.OnEnter(self)
	tip:AnchorTo(self)
	lastanchor = self

	tip:AddLine("picoGuild")

	if IsInGuild() then
		tip:AddLine("<"..GetGuildInfo("player")..">", 1, 1, 1)
		tip:AddLine(GetGuildRosterMOTD(), 0, 1, 0, true)
		tip:AddLine(" ")

		local mylevel, myarea = UnitLevel("player"), GetRealZoneText()
		for i=1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, area, note, officernote, connected, status, engclass = GetGuildRosterInfo(i)
			if connected then
				local cc = RAID_CLASS_COLORS[engclass]
				local lr, lg, lb, ar, ag, ab = 0, 1, 0, 1, 1, 1
				if level < (mylevel - 5) then lr, lg, lb = .6, .6, .6
				elseif level > (mylevel + 5) then lr, lg, lb = 1, 0, 0 end
				if area == myarea then ar, ag, ab = 0, 1, 0 end
				local levelcolor = (level >= (mylevel - 5) and level <= (mylevel + 5)) and "|cff00ff00" or ""
				tip:AddMultiLine((level < 10 and "0" or "")..level, name, area or "???", note, officernote, rank,
					lr,lg,lb, cc.r,cc.g,cc.b, ar,ag,ab, nil,nil,nil, 1,1,0, .7,.7,1)
			end
		end
	else
		tip:AddLine(L["Not in a guild"])
	end

	tip:Show()
end


-----------------------------------------
--      Click to open guild panel      --
-----------------------------------------

function dataobj.OnClick()
	ToggleGuildFrame()
	if GuildFrame:IsShown() then tip:Hide() else dataobj.OnEnter(lastanchor) end
end


-----------------------------------
--      Make rocket go now!      --
-----------------------------------

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
