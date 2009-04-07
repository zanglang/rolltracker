--[[
	RollTracker Lite v0.2 - by Jerry Chong. <zanglang@gmail.com>
	Originally written by Coth of Gilneas and Morodan of Khadgar.
	
	0.2 - New project name
	0.1 - Initial test release. The code is very loosely based on the old addon, most of the less-used features have been removed. <10kb when all rolls emptied :)
]]--

local rollArray
local rollNames

function RollTracker_OnLoad()
	rollArray = {}
	rollNames = {}
	this:RegisterEvent("CHAT_MSG_SYSTEM")
	
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
	for name, roll, low, high in string.gmatch(arg1, "([^%s]+) rolls (%d+) %((%d+)%-(%d+)%)$") do
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
function RollTracker_UpdateList()
	local rollText = ""
	
	table.sort(rollArray, function (a, b)
		return a.Roll < b.Roll
	end)
	
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
	RollTrackerFrameStatusText:SetText(string.format("%d Roll(s)", table.getn(rollArray)))
end

function RollTracker_ClearRolls()
	rollArray = {}
	rollNames = {}
	DEFAULT_CHAT_FRAME:AddMessage("All rolls have been cleared.")
	RollTracker_UpdateList()
end

function RollTracker_ShowWindow()
	RollTrackerFrame:Show()
	RollTracker_UpdateList()
end
