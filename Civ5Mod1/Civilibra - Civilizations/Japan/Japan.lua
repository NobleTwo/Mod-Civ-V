local g_ChangedPlotsIndices = {}

-- adds +1 production from each sea resource for Japan
function addProductionToJapaneseSeaResources( hexX, hexY, iPlayerID, unknown)	
	local gridX, gridY = ToGridFromHex( hexX, hexY )
	local pPlot = Map.GetPlot( gridX, gridY )
	local iResourceID = pPlot:GetResourceType()
	
	-- if sea resource
	if( iResourceID ~= GameInfo.Resources.RESOURCE_FISH.ID and iResourceID ~= GameInfo.Resources.RESOURCE_WHALE.ID and iResourceID ~= GameInfo.Resources.RESOURCE_PEARLS.ID and iResourceID ~= GameInfo.Resources.RESOURCE_CRAB.ID ) then
		return
	end
	
	local pPlayer = Players[iPlayerID]
	if( pPlayer == nil ) then
		return
	end

	local w = Map.GetGridSize()
	local index = gridX + gridY * w
	if( pPlayer:GetCivilizationType() == GameInfo.Civilizations.CIVILIZATION_JAPAN.ID ) then
		-- adds yield for Japan
		Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_PRODUCTION, 1 )
		Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_CULTURE, 1 )
		
		-- tracks changes
		g_ChangedPlotsIndices[index] = true
	elseif ( g_ChangedPlotsIndices[index] == true ) then
		-- removes yield if not Japan
		Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_PRODUCTION, -1 )
		Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_CULTURE, -1 )

		-- tracks changes
		g_ChangedPlotsIndices[index] = false
	end
end
Events.SerialEventHexCultureChanged.Add( addProductionToJapaneseSeaResources )