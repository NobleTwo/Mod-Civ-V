-- Separate Counters
-- Author: Machiavelli
-- DateCreated: 8/22/2014 8:43:59 PM
--------------------------------------------------------------
g_SaveData = Modding.OpenSaveData();
--------------------------------------------------------------
function GetPersistentProperty(name)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	if(g_Properties[name] == nil) then
		g_Properties[name] = g_SaveData.GetValue(name);
	end
	
	return g_Properties[name];
end
--------------------------------------------------------------
function SetPersistentProperty(name, value)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	g_SaveData.SetValue(name, value);
	g_Properties[name] = value;
end
--------------------------------------------------------------
function Set_SGPC_Threshold(playerID, value)
	SetPersistentProperty("SGPC_Threshold_" .. tostring(playerID), value);
end

function Get_SGPC_Threshold(playerID)
	return GetPersistentProperty("SGPC_Threshold_" .. tostring(playerID));
end
--------------------------------------------------------------
function Set_SGPC_MerchantsBorn(playerID, value)	
	SetPersistentProperty("SGPC_MerchantsBorn_" .. tostring(playerID), value);
end

function Get_SGPC_MerchantsBorn(playerID)
	return GetPersistentProperty("SGPC_MerchantsBorn_" .. tostring(playerID));
end
--------------------------------------------------------------
function Set_SGPC_ScientistsBorn(playerID, value)	
	SetPersistentProperty("SGPC_ScientistsBorn_" .. tostring(playerID), value);
end

function Get_SGPC_ScientistsBorn(playerID)
	return GetPersistentProperty("SGPC_ScientistsBorn_" .. tostring(playerID));
end
--------------------------------------------------------------
function Set_SGPC_EngineersBorn(playerID, value)	
	SetPersistentProperty("SGPC_EngineersBorn_" .. tostring(playerID), value);
end

function Get_SGPC_EngineersBorn(playerID)
	return GetPersistentProperty("SGPC_EngineersBorn_" .. tostring(playerID));
end
--------------------------------------------------------------
--------------------------------------------------------------
function Initialize_SGPC_Values(playerID, iX, iY)
	local plot = Map.GetPlot(iX, iY);
	local player = Players[playerID];

	-- If the player just founded their capital city, initialize
	if(not player:IsMinorCiv() and not player:IsBarbarian() and plot:IsCity() and plot:GetPlotCity():GetID() == player:GetCapitalCity():GetID()) then
		Set_SGPC_Threshold(playerID, player:GetCapitalCity():GetSpecialistUpgradeThreshold());
		Set_SGPC_MerchantsBorn(playerID, 0);
		Set_SGPC_ScientistsBorn(playerID, 0);
		Set_SGPC_EngineersBorn(playerID, 0);
	end
end
GameEvents.PlayerCityFounded.Add(Initialize_SGPC_Values);

function CityFounded_AdjustGreatPersonCounters(playerID, iX, iY)
	local plot = Map.GetPlot(iX, iY);
	local player = Players[playerID];
	local city = plot:GetPlotCity();
	local pointsPerGreatPerson = 0;

	-- If the player has not founded their capital, update the starting Great Person progress
	if(not player:IsMinorCiv() and not player:IsBarbarian() and city:GetID() ~= player:GetCapitalCity():GetID()) then
		pointsPerGreatPerson = (100 * GameInfo.GameSpeeds[Game:GetGameSpeedType()].GreatPeoplePercent) / 100;
		
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, 100 * pointsPerGreatPerson * (Get_SGPC_ScientistsBorn(playerID) + Get_SGPC_EngineersBorn(playerID)));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(playerID) + Get_SGPC_EngineersBorn(playerID)));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(playerID) + Get_SGPC_ScientistsBorn(playerID)));
	end
end
GameEvents.PlayerCityFounded.Add(CityFounded_AdjustGreatPersonCounters);

function CityCaptured_AdjustGreatPersonCounters(oldPlayerID, bCapital, iX, iY, newPlayerID, conquest, conquest2)
	local player = Players[newPlayerID];
	local city = Map.GetPlot(iX, iY):GetPlotCity();
	local pointsPerGreatPerson = (100 * GameInfo.GameSpeeds[Game:GetGameSpeedType()].GreatPeoplePercent) / 100;

	if(not player:IsMinorCiv() and not player:IsBarbarian()) then
		-- Set Progress to zero
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, -1 * city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, -1 * city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, -1 * city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER));
	
		-- Founded city progress
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, 100 * pointsPerGreatPerson * (Get_SGPC_ScientistsBorn(newPlayerID) + Get_SGPC_EngineersBorn(newPlayerID)));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(newPlayerID) + Get_SGPC_EngineersBorn(newPlayerID)));
		city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(newPlayerID) + Get_SGPC_ScientistsBorn(newPlayerID)));
	end
end
GameEvents.CityCaptureComplete.Add(CityCaptured_AdjustGreatPersonCounters);

function GreatPersonBorn(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible)
	local player = Players[playerID];
	local unit = player:GetUnitByID(unitID);
	local newThreshold = 0;
	local oldThreshold = 0;
	local pointsPerGreatPerson = 0;
	local minProgress = 0;

	-- Only continue if the unit is a Great Merchant/Scientist/Engineer
	if(not (unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_MERCHANT"] or unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_SCIENTIST"] or unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_ENGINEER"])) then
		return;
	end

	-- Only continue if player is major civ
	if(player:IsMinorCiv() or player:IsBarbarian()) then
		return;
	end
	
	-- Only continue if the threshold for Great People has increased
	newThreshold = player:GetCapitalCity():GetSpecialistUpgradeThreshold();
	oldThreshold = Get_SGPC_Threshold(playerID);

	-- Only continue if the threshold has increased
	if(newThreshold <= oldThreshold) then
		return;
	end
	
	-- This wasn't a free Great Person so update the stored information
	pointsPerGreatPerson = (100 * GameInfo.GameSpeeds[Game:GetGameSpeedType()].GreatPeoplePercent) / 100;
	Set_SGPC_Threshold(playerID, oldThreshold + pointsPerGreatPerson);

	-- In every city advance the counters for the other Great People
	if(unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_MERCHANT"]) then
		Set_SGPC_MerchantsBorn(playerID, Get_SGPC_MerchantsBorn(playerID) + 1);
		minProgress = 100 * pointsPerGreatPerson * (Get_SGPC_ScientistsBorn(playerID) + Get_SGPC_EngineersBorn(playerID));

		for city in player:Cities() do
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, 100 * pointsPerGreatPerson);
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, 100 * pointsPerGreatPerson);

			if(city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT) < minProgress) then
				city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, minProgress);
			end
		end
	elseif(unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_SCIENTIST"]) then
		Set_SGPC_ScientistsBorn(playerID, Get_SGPC_ScientistsBorn(playerID) + 1);
		minProgress = 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(playerID) + Get_SGPC_EngineersBorn(playerID));

		for city in player:Cities() do
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, 100 * pointsPerGreatPerson);
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, 100 * pointsPerGreatPerson);

			if(city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST) < minProgress) then
				city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, minProgress);
			end
		end
	elseif(unit:GetUnitClassType() == GameInfoTypes["UNITCLASS_ENGINEER"]) then
		Set_SGPC_EngineersBorn(playerID, Get_SGPC_EngineersBorn(playerID) + 1);
		minProgress = 100 * pointsPerGreatPerson * (Get_SGPC_MerchantsBorn(playerID) + Get_SGPC_ScientistsBorn(playerID));

		for city in player:Cities() do
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_MERCHANT, 100 * pointsPerGreatPerson);
			city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_SCIENTIST, 100 * pointsPerGreatPerson);

			if(city:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER) < minProgress) then
				city:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes.SPECIALIST_ENGINEER, minProgress);
			end
		end
	end
end
LuaEvents.SerialEventUnitCreatedGood.Add(GreatPersonBorn);