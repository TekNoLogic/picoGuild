
local lib, oldminor = LibStub:NewLibrary("tektip-1.0", 3)
if not lib then return end
oldminor = oldminor or 0


local PADDING, VGAP, HGAP = 5, 2, 5
local TOOLTIP_PADDING = PADDING + HGAP

local bgFrame = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", insets = {left = PADDING, right = PADDING, top = PADDING, bottom = PADDING},
	tile = true, tileSize = 16, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16}

if oldminor < 1 then
	local linemeta = {__index = function(t,i)
		if i == "header" then
			local h = CreateFrame("Frame", nil, t.frame)
			h:SetHeight(1)
			if t.colnum == 1 then
				h:SetPoint("TOPLEFT", t.frame, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING)
			else
				h:SetPoint("LEFT", t.frame.cols[t.colnum-1].header, "RIGHT", HGAP, 0)
			end
			t[i] = h
			return h
		end

		local fs = t.frame:CreateFontString(nil, nil, i == 1 and "GameTooltipHeaderText" or "GameTooltipText")
		if t.colnum == 1 then
			if i == 1 then
				fs:SetPoint("TOPLEFT", t.frame, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING)
			else
				fs:SetPoint("TOPLEFT", t[i-1], "BOTTOMLEFT", 0, -VGAP)
			end
		else
			fs:SetPoint("TOP", t.frame.cols[t.colnum-1][i], "TOP")
			fs:SetPoint("LEFT", t.header, "LEFT")
			fs:SetPoint("RIGHT", t.header, "RIGHT")
		end
		fs:SetJustifyH(t.justify)
		t[i] = fs
		return fs
	end}

	function lib.new(cols, ...)
		assert(type(cols) == "number" and cols >= 2, "Must have at least two columns.")

		local f = CreateFrame("Frame", nil, UIParent)
		f:SetBackdrop(bgFrame)
		f:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
		f:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
		f:SetFrameStrata("TOOLTIP")
		f:SetClampedToScreen(true)

		f.cols = {}
		for i=1,cols do
			local justify = select(i, ...) or i == 1 and "LEFT" or i == cols and "RIGHT" or "CENTER"
			f.cols[i] = setmetatable({frame = f, colnum = i, justify = justify}, linemeta)
		end

		f.AddLine = lib.AddLine
		f.AddMultiLine = lib.AddMultiLine
		f.Clear = lib.Clear
		f.AnchorTo = lib.AnchorTo

		f:SetScript("OnHide", lib.Clear)
		f:SetScript("OnShow", lib.OnShow)

		f:Hide()
		return f
	end


	local function GetTipAnchor(frame)
		local x,y = frame:GetCenter()
		if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	end

	function lib:AnchorTo(frame)
		self:Clear()
		self:ClearAllPoints()
		self:SetPoint(GetTipAnchor(frame))
	end


	function lib:Clear()
		self.numlines = 0
		for i,col in pairs(self.cols) do
			for j,fs in ipairs(col) do
				fs:Hide()
			end
		end
	end
end


if oldminor < 3 then
	function lib:AddLine(text, r, g, b, wrap)
		self.numlines = self.numlines + 1
		local fs = self.cols[1][self.numlines]
		fs:SetTextColor(r or NORMAL_FONT_COLOR.r, g or NORMAL_FONT_COLOR.g, b or NORMAL_FONT_COLOR.b)
		fs:SetText(text)
		fs:SetPoint("RIGHT", self.cols[#self.cols].header, "RIGHT")
		fs.wrapped = wrap
		for i=2,#self.cols do self.cols[i][self.numlines]:SetText(nil) end
		fs:Show()
	end
end


if oldminor < 1 then
	function lib:AddMultiLine(...)
		self.numlines = self.numlines + 1
		local numdots = select("#", ...)
		for i=1,#self.cols do
			local fs = self.cols[i][self.numlines]
			local text = select(i, ...)
			local r, g, b
			if numdots >= (#self.cols + i*3) then r, g, b = select(#self.cols + i*3 - 2, ...) end
			fs:SetTextColor(r or NORMAL_FONT_COLOR.r, g or NORMAL_FONT_COLOR.g, b or NORMAL_FONT_COLOR.b)
			fs:SetText(text == "" and " " or text)
			if i == 1 then fs:SetPoint("RIGHT", self.cols[1].header, "RIGHT") end
			fs:Show()
		end
	end
end


if oldminor < 3 then
	function lib:OnShow()
		local w, totalw = 0, 0
		for i=1,#self.cols do
			local colw = 1
			for j=1,self.numlines do
				local fs = self.cols[i][j]
				if i ~= 1 or self.cols[2][j]:GetText() then colw = math.max(colw, fs:GetStringWidth())
				elseif not fs.wrapped then totalw = math.max(totalw, fs:GetStringWidth()) end
			end
			self.cols[i].header:SetWidth(colw)
			w = w + colw
		end

		if w < (totalw - (#self.cols-1)*HGAP) then
			local extra = totalw - w - (#self.cols-1)*HGAP
			for i=1,#self.cols do self.cols[i].header:SetWidth(extra/#self.cols + self.cols[i].header:GetWidth()) end
			w = totalw
		else
			w = w + (#self.cols-1)*HGAP
		end
		self:SetWidth(w + TOOLTIP_PADDING*2)

		local h = 0
		for i=1,self.numlines do
			local fs = self.cols[1][i]
			fs:SetWidth(fs.wrapped and w or 0)
			h = h + fs:GetHeight()
		end

		self:SetHeight(h + TOOLTIP_PADDING*2 + (self.numlines-1)*VGAP)
	end
end
