include("PlotIterators")

-- grants 3 sight range to every player at the beginning of the game
function sightStartingPlot(civID)
	local pPlayer
	local pChosenPlayer
	for iPlayerID = 0, GameDefines.MAX_MAJOR_CIVS do
		pPlayer = Players[iPlayerID]
		if( pPlayer ~= nil and pPlayer:GetCivilizationType() == civID ) then
			pChosenPlayer = pPlayer
		end
	end
	
	local iTeam = pChosenPlayer:GetTeam()
	local pPlot = pChosenPlayer:GetStartingPlot()

	for pAreaPlot in PlotAreaSweepIterator(pPlot, 3) do
		pAreaPlot:SetRevealed(iTeam, true)
	end

	Map.UpdateDeferredFog()
end
Events.SerialEventDawnOfManHide.Add(sightStartingPlot)