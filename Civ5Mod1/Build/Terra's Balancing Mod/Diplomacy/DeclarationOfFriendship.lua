--TODO: case: open dll? -> what happens if war declared?,  DoF ausgelaufen, cancel Notifications "Peace made", include into GameOptions to avoid Bot-hate, Textmessage in screen
--  CURRENTLY NOT IN PROPERTIES OF MOD -> DISABLED


local iGameSpeed = PreGame.GetGameSpeed()

-- variables for management of DoFs
local g_MinTurnsDoF = 10
local g_TurnsTruce = 10
if ( iGameSpeed == GameInfo.GameSpeeds.GAMESPEED_EPIC.ID ) then
	g_MinTurnsDoF = 15
	g_TurnsTruce = 15
elseif ( iGameSpeed == GameInfo.GameSpeeds.GAMESPEED_MARATHON.ID ) then
	g_MinTurnsDoF = 30
	g_TurnsTruce = 30
end
local g_CurrentDoF = {}
local g_TurnsTruceLeft = {}

-- variables for management of texts
local g_TextDeclareWar = Locale.ConvertTextKey("TXT_KEY_DIPLO_DECLARE_WAR")
local g_TooltipDeclareWar = Locale.ConvertTextKey("TXT_KEY_DIPLO_DECLARES_WAR_TT")
local g_TooltipCannotDeclareWar = Locale.ConvertTextKey("TXT_KEY_DIPLO_MAY_NOT_ATTACK_MOD")
local g_TextDoesThisMeanWar = Locale.ConvertTextKey("TXT_KEY_POPUP_DOES_THIS_MEAN_WAR")
local g_TextChanged = false

function manageDoFs( )
	for iPlayerID1 = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local pPlayer1 = Players[iPlayerID1]
		if( pPlayer1 ~= nil ) then
			for iPlayerID2 = iPlayerID1 + 1, GameDefines.MAX_PLAYERS-1 do
				local pPlayer2 = Players[iPlayerID2]
				if( pPlayer2 ~= nil ) then
					local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iPlayerID2
					-- count down turns of truce
					if( g_TurnsTruceLeft[posArray] ~= nil and g_TurnsTruceLeft[posArray] > 0 ) then
						g_TurnsTruceLeft[posArray] = g_TurnsTruceLeft[posArray] - 1
						print("turns left:")
						print(g_TurnsTruceLeft[posArray])
					end

					-- keep track of DoFs
					if( pPlayer2:IsDoF(iPlayerID1) and g_CurrentDoF[posArray] == false ) then
						g_CurrentDoF[posArray] = true
						print("dof")
					end
				end
			end
		end
	end
end
Events.ActivePlayerTurnStart.Add( manageDoFs )

GameEvents.CanDeclareWar.Add( function( myTeam, theirTeam )
	for iPlayerID1 = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local pPlayer1 = Players[iPlayerID1]
		if( pPlayer1 ~= nil and pPlayer1:GetTeam() == myTeam and not pPlayer1:IsMinorCiv() ) then
			for iPlayerID2 = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
				local pPlayer2 = Players[iPlayerID2]
				if( pPlayer2 ~= nil and pPlayer2:GetTeam() == theirTeam and not pPlayer2:IsMinorCiv() ) then
					local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iPlayerID2

					-- choose smaller posArray value
					if( iPlayerID2*GameDefines.MAX_MAJOR_CIVS + iPlayerID1 < posArray ) then
						posArray = iPlayerID2*GameDefines.MAX_MAJOR_CIVS + iPlayerID1
					end

					-- war not allowed if Truce
					if( g_TurnsTruceLeft[posArray] ~= nil and g_TurnsTruceLeft[posArray] > 0 ) then
						return false
					end

					-- war not allowed if not enough turns DoF
					local g_DoFCounter = pPlayer1:GetDoFCounter( iAIPlayerID )
					if( g_DoFCounter == nil or ( pPlayer2:GetDoFCounter( iPlayerID1 ) ~= nil and pPlayer2:GetDoFCounter( iPlayerID1 ) > g_DoFCounter ) ) then
							g_DoFCounter = pPlayer2:GetDoFCounter( iPlayerID1 )
					end
					if( g_DoFCounter ~= nil and g_DoFCounter < g_MinTurnsDoF ) then
						return false
					end
				end
			end
		end
	end
	return true
end
)

function noWarIfDoF(myTeam, theirTeam, atWar)
	if( not atWar ) then return end
	for iPlayerID1 = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local pPlayer1 = Players[iPlayerID1]
		if( pPlayer1 ~= nil and pPlayer1:GetTeam() == myTeam and not pPlayer1:IsMinorCiv() ) then
			for iPlayerID2 = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
				local pPlayer2 = Players[iPlayerID2]
				if( pPlayer2 ~= nil and pPlayer2:GetTeam() == theirTeam and not pPlayer2:IsMinorCiv() ) then
					local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iPlayerID2
					-- choose smaller posArray value
					if( iPlayerID2*GameDefines.MAX_MAJOR_CIVS + iPlayerID1 < posArray ) then
						posArray = iPlayerID2*GameDefines.MAX_MAJOR_CIVS + iPlayerID1
					end

					-- if there was a DoF last turn
					if( g_CurrentDoF[posArray] == true ) then
						-- set turn counter
						g_TurnsTruceLeft[posArray] = g_TurnsTruce
						local tTeam1 = Teams[pPlayer1:GetTeam()]
						local iTeam2ID = pPlayer2:GetTeam()
						-- make peace
						tTeam1:MakePeace(theirTeam)
						g_CurrentDoF[posArray] = false
						return
					end
				end
			end
		end
	end
end
Events.WarStateChanged.Add(noWarIfDoF)

function SetTextDuringDoF( turns )
	-- find language
	local g_language = getLanguage()

	-- update button "Declare War"
	local query = "UPDATE " .. g_language .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_DIPLO_CANCEL_DOF") .. "' WHERE Tag = 'TXT_KEY_DIPLO_DECLARE_WAR'"
	for result in DB.Query(query) do end

	-- update tooltip with turns left
	if( turns > 0 ) then
		query = "UPDATE " .. g_language .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_DIPLO_MAY_NOT_ATTACK_DOF", turns) .. "' WHERE Tag = 'TXT_KEY_DIPLO_MAY_NOT_ATTACK_MOD'"
		for result in DB.Query(query) do end
	else
		-- update tooltip to end DoF
		query = "UPDATE " .. g_language .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_DIPLO_CANCEL_DOF_TT") .. "' WHERE Tag = 'TXT_KEY_DIPLO_DECLARES_WAR_TT'"
		for result in DB.Query(query) do end

		-- update question if want to cancel DoF
		query = "UPDATE " .. g_language .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_POPUP_DOES_THIS_MEAN_END_DOF") .. "' WHERE Tag = 'TXT_KEY_POPUP_DOES_THIS_MEAN_WAR'"
		for result in DB.Query(query) do end
	end

	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
	g_TextChanged = true
end

function OnOpenDiploScreen( iAIPlayerID, iDiploUIState, g_LeaderMessage, iAnimationAction, iData1 )
	local iPlayerID1 = Game.GetActivePlayer()
	local pPlayer1 = Players[iPlayerID1]
	local pPlayer2 = Players[iAIPlayerID]

	local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iAIPlayerID
	
	--choose smaller posArray value
	if( iAIPlayerID*GameDefines.MAX_MAJOR_CIVS + iPlayerID1 < posArray ) then
		posArray = iAIPlayerID*GameDefines.MAX_MAJOR_CIVS + iPlayerID1
	end

	-- if there IS a DoF between AI and active player
	if( pPlayer2:IsDoF(iPlayerID1) ) then
		local g_DoFCounter = pPlayer1:GetDoFCounter( iAIPlayerID )
		if( g_DoFCounter == nil or ( pPlayer2:GetDoFCounter( iPlayerID1 ) ~= nil and pPlayer2:GetDoFCounter( iPlayerID1 ) > g_DoFCounter ) ) then
			g_DoFCounter = pPlayer2:GetDoFCounter( iPlayerID1 )
		end
		SetTextDuringDoF( g_MinTurnsDoF - g_DoFCounter )
	-- else if there WAS a DoF between AI and active player
	elseif ( g_TurnsTruceLeft[posArray] ~= nil and g_TurnsTruceLeft[posArray] > 0 ) then
		local query = "UPDATE " .. getLanguage() .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_DIPLO_MAY_NOT_ATTACK_AFTER_DOF", g_TurnsTruceLeft[posArray]) .. "' WHERE Tag = 'TXT_KEY_DIPLO_MAY_NOT_ATTACK_MOD'"
		for result in DB.Query(query) do end

		Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
		g_TextChanged = true
	end
end
Events.AILeaderMessage.Add( OnOpenDiploScreen )


function OnLeavingDiploScreen ()
	-- update DoFs
	for iPlayerID1 = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local pPlayer1 = Players[iPlayerID1]
		if( pPlayer1 ~= nil ) then
			for iPlayerID2 = iPlayerID1 + 1, GameDefines.MAX_PLAYERS-1 do
				local pPlayer2 = Players[iPlayerID2]
				if( pPlayer2 ~= nil ) then
					local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iPlayerID2
					-- keep track of DoFs
					if( pPlayer2:IsDoF(iPlayerID1) ) then
						g_CurrentDoF[posArray] = true
						print("dof")
					end
				end
			end
		end
	end

	if( g_TextChanged ) then
		-- find language
		local g_language = getLanguage()

		-- reset button "Cancel DoF" -> "Declare War"
		local query = "UPDATE " .. g_language .. " SET Text = '" .. g_TextDeclareWar .. "' WHERE Tag = 'TXT_KEY_DIPLO_DECLARE_WAR'"
		for result in DB.Query(query) do end

		-- reset tooltip "cannot declare war"
		query = "UPDATE " .. g_language .. " SET Text = '" .. Locale.ConvertTextKey("TXT_KEY_DIPLO_MAY_NOT_ATTACK_DOF") .. "' WHERE Tag = 'TXT_KEY_DIPLO_MAY_NOT_ATTACK_MOD'"
		for result in DB.Query(query) do end
		
		-- reset tooltip "Cancel DoF" -> "Declare War"
		query = "UPDATE " .. g_language .. " SET Text = '" .. g_TooltipDeclareWar .. "' WHERE Tag = 'TXT_KEY_DIPLO_DECLARES_WAR_TT'"
		for result in DB.Query(query) do end
		
		-- reset text "End DoF?" -> "Does this mean war?"
		query = "UPDATE " .. g_language .. " SET Text = '" .. g_TextDoesThisMeanWar .. "' WHERE Tag = 'TXT_KEY_POPUP_DOES_THIS_MEAN_WAR'"
		for result in DB.Query(query) do end

		Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
		g_TextChanged = false
	end
end
Events.LeavingLeaderViewMode.Add( OnLeavingDiploScreen )

function getLanguage( )
	local g_language = "Language_en_US"
	if( Locale.GetCurrentLanguage().Type == "DE_DE" ) then
		g_language = "Language_DE_DE"
	end
	return g_language
end

-- C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\Gameplay\XML\NewText\EN_US\CIV5GameTextInfos_Jon.xml
-- C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\Gameplay\XML\NewText\EN_US\CIV5GameTextInfos2.xml
-- TXT_KEY_MISC_YOU_DECLARED_WAR_ON: text mid screen
-- TXT_KEY_MISC_YOU_MADE_PEACE_WITH: notification made peace

-- GameDefines.DOF_EXPIRATION_TIME