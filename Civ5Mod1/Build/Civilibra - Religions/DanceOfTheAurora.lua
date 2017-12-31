g_ForestPlots = {}
g_NumForestPlots = 0
g_AuroraChosen = false

-- store all forest tiles
function GetForestTiles()
  local mapWidth, mapHeight = Map.GetGridSize()
  for x = 0, mapWidth-1 do
    for y = 0, mapHeight-1 do
      local pPlot = Map.GetPlot(x, y)
	  local iFeature = pPlot:GetFeatureType()

	  if ( iFeature == GameInfo.Features.FEATURE_FOREST.ID ) then
        g_ForestPlots[g_NumForestPlots] = pPlot
		g_NumForestPlots = g_NumForestPlots + 1
      end
    end
  end
end
Events.LoadScreenClose.Add( GetForestTiles )

-- adjust yield of one tile
function AdjustYield(pPlot)
	if( pPlot:CalculateYield( YieldTypes.YIELD_FAITH, true ) >= 100 ) then
		local gridX = pPlot:GetX()
		local gridY = pPlot:GetY()
		-- remove extra yield 100 faith
		Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_FAITH, -100 )
		-- if it's a tundra tile: add 1 faith
		if( pPlot:GetTerrainType() == GameInfo.Terrains.TERRAIN_TUNDRA.ID ) then
			Game.SetPlotExtraYield( gridX, gridY, YieldTypes.YIELD_FAITH, 1 )
		end
	end
end

function LoopForestTiles()
	-- loop all stored forest tiles
	for i = 0, g_NumForestPlots do
		local pPlot = g_ForestPlots[i]
		if( pPlot ~= nil) then
			-- if forest has been removed: remove plot from storage
			if( pPlot:GetFeatureType() ~= GameInfo.Features.FEATURE_FOREST.ID ) then
				g_ForestPlots[i] = g_ForestPlots[ g_NumForestPlots - 1 ]
				g_NumForestPlots = g_NumForestPlots - 1
				i = i - 1
			else
				AdjustYield( pPlot )
			end
		end
	end
end
Events.ActivePlayerTurnStart.Add( LoopForestTiles )
Events.ActivePlayerTurnEnd.Add( LoopForestTiles )

function CheckTile(hexX, hexY, iPlayerID, unknown)
	local gridX, gridY = ToGridFromHex( hexX, hexY )
	local pPlot = Map.GetPlot(gridX, gridY )
	AdjustYield( pPlot )
end
Events.SerialEventHexCultureChanged.Add( CheckTile )