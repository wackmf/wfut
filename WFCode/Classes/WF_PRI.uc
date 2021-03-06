//=============================================================================
// WF_PRI.
//=============================================================================
class WF_PRI extends PlayerReplicationInfo;

// --- Status flags ---

// These are managed by the WFPlayerStatus classes.
const PS_Normal		= 0;	// normal health

const PS_Concussed 	= 1;	// player is concussed
const PS_Blinded	= 2;	// player is blinded
const PS_Infected	= 4;	// player has been infected
const PS_Frozen		= 8;	// player is frozen
const PS_OnFire		= 16;	// player is on fire
const PS_Tranqed	= 32;	// player has been traquilised
const PS_LegDamage	= 64;	// player has leg damage

// misc flags
const PS_Disguised	= 128;	// the player is currently disguised

var int StatusFlags; // the players current status
var string ClassName; // string name of player class

var int MiscScoreArray[8]; // miscellaneous scoring vars

replication
{
	reliable if (Role == ROLE_Authority)
		StatusFlags, ClassName, MiscScoreArray;
}

defaultproperties
{
}