--TODO: Tooltip turns left, "Declare War" -> "Cancel DoF", Popup Declare War, cancel Notifications "Peace made", include into GameOptions to avoid Bot-hate, Textmessage in screen

local iGameSpeed = PreGame.GetGameSpeed()

local g_MinTurnsDoF = 10
local g_TurnsTruce = 10
if ( iGameSpeed == GameInfo.GameSpeeds.GAMESPEED_EPIC.ID ) then
	g_MinTurnsDoF = 15
	g_TurnsTruce = 15
elseif ( iGameSpeed == GameInfo.GameSpeeds.GAMESPEED_MARATHON.ID ) then
	g_MinTurnsDoF = 30
	g_TurnsTruce = 30
end
local g_TurnsDoF = {}
local g_TurnsTruceLeft = {}

local g_TextDeclareWar = Locale.ConvertTextKey("TXT_KEY_DIPLO_DECLARE_WAR")

function manageDoFs()
	for iPlayerID1 = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local pPlayer1 = Players[iPlayerID1]
		if( pPlayer1 ~= nil ) then
			for iPlayerID2 = iPlayerID1, GameDefines.MAX_PLAYERS-1 do
				local pPlayer2 = Players[iPlayerID2]
				if( pPlayer2 ~= nil ) then
					local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iPlayerID2
					-- count down turns of truce
					if( g_TurnsTruceLeft[posArray] ~= nil and g_TurnsTruceLeft[posArray] > 0 ) then
						g_TurnsTruceLeft[posArray] = g_TurnsTruceLeft[posArray] - 1
						print("turns left:")
						print(g_TurnsTruceLeft[posArray])
					end

					-- count up turns of DoF
					if( g_TurnsDoF[posArray] ~= nil and g_TurnsDoF[posArray] >= 0 ) then
						g_TurnsDoF[posArray] = g_TurnsDoF[posArray] + 1
						print("turns of DoF:")
						print(g_TurnsDoF[posArray])
					end

					-- keep track of DoFs
					if( pPlayer2:IsDoF(iPlayerID1) and ( g_TurnsDoF[posArray] == -1 or g_TurnsDoF[posArray] == nil ) ) then
						g_TurnsDoF[posArray] = 1
						SetTextDuringDoF( 0 )
						print("dof")
					end
				end
			end
		end
	end
end
Events.ActivePlayerTurnStart.Add(manageDoFs)

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
					if( g_TurnsDoF[posArray] ~= nil and g_TurnsDoF[posArray] < g_MinTurnsDoF ) then
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
					if( g_TurnsDoF[posArray] ~= nil and g_TurnsDoF[posArray] >= 0 ) then
						-- set turn counter
						g_TurnsTruceLeft[posArray] = g_TurnsTruce
						local tTeam1 = Teams[pPlayer1:GetTeam()]
						local iTeam2ID = pPlayer2:GetTeam()
						-- make peace
						tTeam1:MakePeace(theirTeam)
						g_TurnsDoF[posArray] = -1
						return
					end
				end
			end
		end
	end
end
Events.WarStateChanged.Add(noWarIfDoF)

function SetTextDuringDoF( turns )
	-- update button "Declare War"
	local query = "UPDATE Language_en_US SET Text = 'Cancel Friendship' WHERE Tag = 'TXT_KEY_DIPLO_DECLARE_WAR'"
	for result in DB.Query(query) do end
	query = "UPDATE Language_DE_DE SET Text = 'Freundschaft aufheben' WHERE Tag = 'TXT_KEY_DIPLO_DECLARE_WAR'"
	for result in DB.Query(query) do end



	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
end

function OnOpenDiploScreen( iAIPlayerID, iDiploUIState, g_LeaderMessage, iAnimationAction, iData1 )
	local iPlayerID1 = Game.GetActivePlayer()
	local pPlayer2 = Players[iAIPlayerID]

	-- if there is a DoF between AI and active player
	if( pPlayer2:IsDoF(iPlayerID1) ) then
		local posArray = iPlayerID1*GameDefines.MAX_MAJOR_CIVS + iAIPlayerID

		--choose smaller posArray value
		if( iAIPlayerID*GameDefines.MAX_MAJOR_CIVS + iPlayerID1 < posArray ) then
			posArray = iAIPlayerID*GameDefines.MAX_MAJOR_CIVS + iPlayerID1
		end

		SetTextDuringDoF( g_MinTurnsDoF - g_TurnsDoF[posArray] )
	end
end
Events.AILeaderMessage.Add( OnOpenDiploScreen )


function OnLeavingDiploScreen ()
	print("leaving diplo screen")
end
Events.LeavingLeaderViewMode.Add( OnLeavingDiploScreen )