--[[
	RollTracker Lite v0.2 - by Jerry Chong. <zanglang@gmail.com>
	Originally written by Coth of Gilneas and Morodan of Khadgar.
	
	0.3 - Testing localization, save anchors and size
	0.2 - New project name. Auto clear when closed
	0.1 - Initial test release. The code is very loosely based on the old addon, most of the less-used features have been removed. <10kb when all rolls emptied :)
]]--

local rollArray
local rollNames

-- hard-coded configs
local ClearWhenClosed = true

-- Basic localizations
local locales = {
	deDE = {
		["All rolls have been cleared."] = "Alle gewürfelten Zahlen gelöscht.",
		["%d Roll(s)"] = "%d Zahlen gewürfelt",
	},
	esES = {
		["All rolls have been cleared."] = "Todas las tiradas han sido borradas.",
		["%d Roll(s)"] = "%d Tiradas",
	},
	ruRU = {
		["All rolls have been cleared."] = "Все броски костей очищены.",
		["%d Roll(s)"] = "%d броска(ов)",
	},
	zhCN = {
		["All rolls have been cleared."] = "所有投掷已被清除。",
		["%d Roll(s)"] = "%d个投掷",
	},
	zhTW = {
		["All rolls have been cleared."] = "所有投擲已被清除。",
		["%d Roll(s)"] = "%d個投擲",
	},
}
local L = locales[GetLocale()] or {}
setmetatable(L, {
	-- looks a little messy, may be worth migrating to AceLocale when this list gets bigger
	__index = {
		["%d Roll(s)"] = "%d Roll(s)",
		["All rolls have been cleared."] = "All rolls have been cleared.",
	},
})

-- Init
function RollTracker_OnLoad()
	rollArray = {}
	rollNames = {}
	
	-- GUI
	if not RollTrackerDB then RollTrackerDB = {} end -- fresh DB
	local x, y, w, h = RollTrackerDB.X, RollTrackerDB.Y, RollTrackerDB.Width, RollTrackerDB.Height
	if not x or not y or not w or not h then
		RollTracker_SaveAnchors()
	else
		this:ClearAllPoints()
		this:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		this:SetWidth(w)
		this:SetHeight(h)
	end
		
	-- slash command
	SLASH_ROLLTRACKER1 = "/rolltracker";
	SLASH_ROLLTRACKER2 = "/rt";
	SlashCmdList["ROLLTRACKER"] = function (msg)
		if msg == "clear" then
			RollTracker_ClearRolls()
		else
			RollTracker_ShowWindow()
		end
	end
end

-- Event handler
function RollTracker_CHAT_MSG_SYSTEM(msg)
	-- using RANDOM_ROLL_RESULT from GlobalStrings.lua
	-- %s rolls %d (%d-%d) to (.+) rolls (%d+) %((%d+)-(%d+)%)
	local pattern = string.gsub(RANDOM_ROLL_RESULT, "[%(%)-]", "%%%1")
	pattern = string.gsub(pattern, "%%s", "(.+)")
	pattern = string.gsub(pattern, "%%d", "%(%%d+%)")
	
	for name, roll, low, high in string.gmatch(arg1, pattern) do
		-- check for rerolls. >1 if rolled before
		rollNames[name] = rollNames[name] and rollNames[name] + 1 or 1
		table.insert(rollArray, {
			Name = name,
			Roll = tonumber(roll),
			Low = tonumber(low),
			High = tonumber(high),
			Count = rollNames[name]
		})
		-- popup window
		RollTracker_ShowWindow()
	end
end

-- Sort and format the list
local function RollTracker_Sort(a, b)
	return a.Roll < b.Roll
end

function RollTracker_UpdateList()
	local rollText = ""
	
	table.sort(rollArray, RollTracker_Sort)
	
	-- format and print rolls, check for ties
	for i, roll in pairs(rollArray) do
		local tied = (rollArray[i + 1] and roll.Roll == rollArray[i + 1].Roll) or (rollArray[i - 1] and roll.Roll == rollArray[i - 1].Roll)
		rollText = string.format("|c%s%d|r: |c%s%s%s%s|r\n",
				tied and "ffffff00" or "ffffffff",
				roll.Roll,
				((roll.Low ~= 1 or roll.High ~= 100) or (roll.Count > 1)) and  "ffffcccc" or "ffffffff",
				roll.Name,
				(roll.Low ~= 1 or roll.High ~= 100) and format(" (%d-%d)", roll.Low, roll.High) or "",
				roll.Count > 1 and format(" [%d]", roll.Count) or "") .. rollText
	end
	RollTrackerRollText:SetText(rollText)
	RollTrackerFrameStatusText:SetText(string.format(L["%d Roll(s)"], table.getn(rollArray)))
end

function RollTracker_ClearRolls()
	rollArray = {}
	rollNames = {}
	DEFAULT_CHAT_FRAME:AddMessage(L["All rolls have been cleared."])
	RollTracker_UpdateList()
end

-- GUI
function RollTracker_SaveAnchors()
	RollTrackerDB.X = RollTrackerFrame:GetLeft()
	RollTrackerDB.Y = RollTrackerFrame:GetTop()
	RollTrackerDB.Width = RollTrackerFrame:GetWidth()
	RollTrackerDB.Height = RollTrackerFrame:GetHeight()
end

function RollTracker_ShowWindow()
	RollTrackerFrame:Show()
	RollTracker_UpdateList()
end

function RollTracker_HideWindow()
	if ClearWhenClosed then
		RollTracker_ClearRolls()
	end
end