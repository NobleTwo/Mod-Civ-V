--include("FLuaVector")

local hexGoodyHuts = {}
local numGoodyHuts = 0

function notificationCultureGoody(iHexX, iHexY, iContinent1, iContinent2)
	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY))
	for i = 0, numGoodyHuts do
		if (hexGoodyHuts[i] == pPlot) then
			print("found")
		end
	end
end
Events.SerialEventImprovementDestroyed.Add(notificationCultureGoody)

function storeGoodyHuts(iHexX, iHexY, iContinent1, iContinent2)
	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY))
	if (pPlot:GetImprovementType() == GameInfo.Improvements.IMPROVEMENT_GOODY_HUT.ID) then
		numGoodyHuts = numGoodyHuts + 1
		hexGoodyHuts[numGoodyHuts-1] = pPlot
	end
end
Events.SerialEventImprovementCreated.Add(storeGoodyHuts)