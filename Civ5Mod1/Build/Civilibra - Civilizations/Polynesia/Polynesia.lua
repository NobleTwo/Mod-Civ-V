include("PlotIterators")

-- reveals terrain in 5 tiles range when embarked
function sightPolynesianScout(iPlayerID, iUnitID, x, y)
	local pPlayer = Players[iPlayerID]
	local pUnit = pPlayer:GetUnitByID(iUnitID)

	if( not pUnit:IsEmbarked() ) then
		return
	end

	if( not pUnit:IsHasPromotion(GameInfo.UnitPromotions.PROMOTION_CLIMB_MAST.ID) ) then
		return
	end
	
	local iTeam = pPlayer:GetTeam()
	local pPlot = Map.GetPlot(x, y)
	for pAreaPlot in PlotAreaSweepIterator(pPlot, 5) do
		pAreaPlot:SetRevealed(iTeam, true)
	end
	Map.UpdateDeferredFog()
end
GameEvents.UnitSetXY.Add(sightPolynesianScout)

