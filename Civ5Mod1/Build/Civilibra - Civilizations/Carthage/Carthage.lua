function GrantGreatGeneral(team, tech, change)
	if(tech == GameInfo.Technologies["TECH_HORSEBACK_RIDING"].ID) then	
		for player = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
			if (Players[player] ~= nil) then
				if (Players[player]:GetTeam() == team and PreGame.GetCivilization(player) == GameInfo.Civilizations.CIVILIZATION_CARTHAGE.ID) then	
					local capital = Players[player]:GetCapitalCity();
					capital:CreateGreatGeneral(GameInfo.Units.UNIT_GREAT_GENERAL.ID);
				end
			end
		end
	end
end
GameEvents.TeamTechResearched.Add(GrantGreatGeneral);