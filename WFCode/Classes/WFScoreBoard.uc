//=============================================================================
// WFScoreBoard.
//
// Ob1: This is a bit of a mess, most of the code is overridden here to display
// custom team names, and prevent spectating players from being displayed as
// Gold Team.
//=============================================================================
class WFScoreBoard extends UnrealCTFScoreBoard;

function DrawHeader( canvas Canvas )
{
  local GameReplicationInfo GRI;
  local float XL, YL;
  local font CanvasFont;

  Canvas.DrawColor = WhiteColor;
  GRI = PlayerPawn(Owner).GameReplicationInfo;

  Canvas.Font = Canvas.LargeFont;

  Canvas.bCenter = True;
  Canvas.StrLen("Test", XL, YL);
  ScoreStart = 58.0/768.0 * Canvas.ClipY;
  CanvasFont = Canvas.Font;
  if ( GRI.GameEndedComments != "" )
  {
    Canvas.DrawColor = GoldColor;
    Canvas.SetPos(0, ScoreStart);
    Canvas.DrawText(GRI.GameEndedComments, True);
  }
  else
  {
    Canvas.SetPos(0, ScoreStart);
    DrawVictoryConditions(Canvas);
  }
  Canvas.bCenter = False;
  Canvas.Font = CanvasFont;
}

function ShowScores( canvas Canvas )
{
	local PlayerReplicationInfo PRI;
	local int PlayerCount, i;
	local float LoopCountTeam[4];
	local float XL, YL, XOffset, YOffset, XStart;
	local int PlayerCounts[4];
	local int LongLists[4];
	local int BottomSlot[4];
	local font CanvasFont;
	local bool bCompressed;
	local float r;

	OwnerInfo = Pawn(Owner).PlayerReplicationInfo;
	OwnerGame = TournamentGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	Canvas.Style = ERenderStyle.STY_Normal;
	CanvasFont = Canvas.Font;

	// Header
	DrawHeader(Canvas);

	for ( i=0; i<32; i++ )
		Ordered[i] = None;

	for ( i=0; i<32; i++ )
	{
		if (PlayerPawn(Owner).GameReplicationInfo.PRIArray[i] != None)
		{
			PRI = PlayerPawn(Owner).GameReplicationInfo.PRIArray[i];
			if ( (!PRI.bIsSpectator || PRI.bWaitingPlayer) && (PRI.Team < 4))
			{
				Ordered[PlayerCount] = PRI;
				PlayerCount++;
				PlayerCounts[PRI.Team]++;
			}
		}
	}

	SortScores(PlayerCount);
	Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
	Canvas.StrLen("TEXT", XL, YL);
	ScoreStart = Canvas.CurY + YL*2;
	if ( ScoreStart + PlayerCount * YL + 2 > Canvas.ClipY )
	{
		bCompressed = true;
		CanvasFont = Canvas.Font;
		Canvas.Font = font'SmallFont';
		r = YL;
		Canvas.StrLen("TEXT", XL, YL);
		r = YL/r;
		Canvas.Font = CanvasFont;
	}
	for ( I=0; I<PlayerCount; I++ )
	{
		if ( Ordered[I].Team < 4 )
		{
			if ( Ordered[I].Team % 2 == 0 )
				XOffset = (Canvas.ClipX / 4) - (Canvas.ClipX / 8);
			else
				XOffset = ((Canvas.ClipX / 4) * 3) - (Canvas.ClipX / 8);

			Canvas.StrLen("TEXT", XL, YL);
			Canvas.DrawColor = AltTeamColor[Ordered[I].Team];
			YOffset = ScoreStart + (LoopCountTeam[Ordered[I].Team] * YL) + 2;
			if (( Ordered[I].Team > 1 ) && ( PlayerCounts[Ordered[I].Team-2] > 0 ))
			{
				BottomSlot[Ordered[I].Team] = 1;
				YOffset = ScoreStart + YL*11 + LoopCountTeam[Ordered[I].Team]*YL;
			}

			// Draw Name and Ping
			if ( (Ordered[I].Team < 2) && (BottomSlot[Ordered[I].Team] == 0) && (PlayerCounts[Ordered[I].Team+2] == 0))
			{
				LongLists[Ordered[I].Team] = 1;
				WF_DrawNameAndPing( Canvas, Ordered[I], XOffset, YOffset, bCompressed);
			}
			else if (LoopCountTeam[Ordered[I].Team] < 8)
				WF_DrawNameAndPing( Canvas, Ordered[I], XOffset, YOffset, bCompressed);
			if ( bCompressed )
				LoopCountTeam[Ordered[I].Team] += 1;
			else
				LoopCountTeam[Ordered[I].Team] += 2;
		}
	}

	for ( i=0; i<4; i++ )
	{
		Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
		if ( PlayerCounts[i] > 0 )
		{
			if ( i % 2 == 0 )
				XOffset = (Canvas.ClipX / 4) - (Canvas.ClipX / 8);
			else
				XOffset = ((Canvas.ClipX / 4) * 3) - (Canvas.ClipX / 8);
			YOffset = ScoreStart - YL + 2;

			if ( i > 1 )
				if (PlayerCounts[i-2] > 0)
					YOffset = ScoreStart + YL*10;

			Canvas.DrawColor = TeamColor[i];
			Canvas.SetPos(XOffset, YOffset);
			Canvas.StrLen(OwnerGame.Teams[i].TeamName, XL, YL);
			Canvas.DrawText(OwnerGame.Teams[i].TeamName, false);
			Canvas.StrLen(int(OwnerGame.Teams[i].Score), XL, YL);
			Canvas.SetPos(XOffset + (Canvas.ClipX/4) - XL, YOffset);
			Canvas.DrawText(int(OwnerGame.Teams[i].Score), false);

			if ( PlayerCounts[i] > 4 )
			{
				if ( i < 2 )
					YOffset = ScoreStart + YL*8;
				else
					YOffset = ScoreStart + YL*19;
				Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
				Canvas.SetPos(XOffset, YOffset);
				if (LongLists[i] == 0)
					Canvas.DrawText(PlayerCounts[i] - 4 @ PlayersNotShown, false);
			}
		}
	}

	// Trailer
	if ( !(Level.GetPropertyText("bLowRes") ~= "True") )
	{
		Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
		DrawTrailer(Canvas);
	}
	Canvas.Font = CanvasFont;
	Canvas.DrawColor = WhiteColor;
}

function WF_DrawNameAndPing(Canvas Canvas, PlayerReplicationInfo PRI, float XOffset, float YOffset, bool bCompressed)
{
	local float XL, YL, XL2, YL2, YB;
	local BotReplicationInfo BRI;
	local String S, O, L;
	local Font CanvasFont;
	local bool bAdminPlayer;
	local PlayerPawn PlayerOwner;
	local int Time;

	PlayerOwner = PlayerPawn(Owner);

	bAdminPlayer = PRI.bAdmin;

	// Draw Name
	if (PRI.PlayerName == PlayerOwner.PlayerReplicationInfo.PlayerName)
		Canvas.DrawColor = GoldColor;

	if ( bAdminPlayer )
		Canvas.DrawColor = WhiteColor;

	Canvas.SetPos(XOffset, YOffset);
	Canvas.DrawText(PRI.PlayerName, False);
	Canvas.StrLen(PRI.PlayerName, XL, YB);

	if ( Canvas.ClipX > 512 )
	{
		CanvasFont = Canvas.Font;
		Canvas.Font = Font'SmallFont';
		Canvas.DrawColor = WhiteColor;

		if (Level.NetMode != NM_Standalone)
		{
			if ( !bCompressed || (Canvas.ClipX > 640) )
			{
				// Draw Time
				Time = Max(1, (Level.TimeSeconds + PlayerOwner.PlayerReplicationInfo.StartTime - PRI.StartTime)/60);
				Canvas.StrLen(TimeString$":     ", XL, YL);
				Canvas.SetPos(XOffset - XL - 6, YOffset);
				Canvas.DrawText(TimeString$":"@Time, false);
			}

			// Draw Ping
			Canvas.StrLen(PingString$":     ", XL2, YL2);
			Canvas.SetPos(XOffset - XL2 - 6, YOffset + (YL+1));
			Canvas.DrawText(PingString$":"@PRI.Ping, false);
		}
		Canvas.Font = CanvasFont;
	}

	// Draw Score
	if (PRI.PlayerName == PlayerOwner.PlayerReplicationInfo.PlayerName)
		Canvas.DrawColor = GoldColor;
	else
		Canvas.DrawColor = TeamColor[PRI.Team];
	DrawScore(Canvas, PRI.Score, XOffset, YOffset);

	if (Canvas.ClipX < 512)
		return;

	// Draw location, Order
	if ( !bCompressed && (PRI.Team == OwnerInfo.Team) )
	{
		CanvasFont = Canvas.Font;
		Canvas.Font = Font'SmallFont';

		if ( PRI.PlayerLocation != None )
			L = PRI.PlayerLocation.LocationName;
		else if ( PRI.PlayerZone != None )
			L = PRI.PlayerZone.ZoneName;
		else
			L = "";
		if ( L != "" )
		{
			L = InString@L;
			Canvas.SetPos(XOffset, YOffset + YB);
			Canvas.DrawText(L, False);
		}
		O = OwnerGame.GetOrderString(PRI);
		if (O != "")
		{
			O = OrdersString@O;
			Canvas.StrLen(O, XL2, YL2);
			Canvas.SetPos(XOffset, YOffset + YB + YL2);
			Canvas.DrawText(O, False);
		}
		Canvas.Font = CanvasFont;
	}
}

defaultproperties
{
}