

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

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("picoGuild", {icon = "Interface\\Addons\\picoGuild\\icon", text = L["No Guild"]})
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

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj.OnLeave() GameTooltip:Hide() end
function dataobj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	if IsInGuild() then
		GameTooltip:AddDoubleLine("picoGuild", GetGuildInfo("player"))
		GameTooltip:AddLine(GetGuildRosterMOTD(), 0, 1, 0, true)
		GameTooltip:AddLine(" ")

		local mylevel = UnitLevel("player")
		for i=1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, area, note, officernote, connected, status, engclass = GetGuildRosterInfo(i)
			if connected then
				local levelcolor = (level >= (mylevel - 5) and level <= (mylevel + 5)) and "|cff00ff00" or ""
				GameTooltip:AddDoubleLine(string.format("%s%02d:|cff%s%s|r", levelcolor, level, colors[engclass] or "000000", name), "|cffffff00"..note.. " "..officernote.." |cff00ff00("..rank..")")
			end
		end
	else
		GameTooltip:AddLine("picoGuild")
		GameTooltip:AddLine(L["Not in a guild"])
	end

	GameTooltip:Show()
end


-----------------------------------------
--      Click to open guild panel      --
-----------------------------------------

function dataobj.OnClick()
	if FriendsFrame:IsVisible() then HideUIPanel(FriendsFrame)
	else
		ToggleFriendsFrame(3)
		FriendsFrame_Update()
		GameTooltip:Hide()
	end
end


-----------------------------------
--      Make rocket go now!      --
-----------------------------------

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
