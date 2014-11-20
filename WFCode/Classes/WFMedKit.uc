class WFMedKit extends WFWeapon;

var() string CureStatusTypes[16];

var float MedBeamRange;
var() float HealTime;
var() int HealAmount;

var pawn MedKitTarget;

function Fire( float Value )
{
	if (!WeaponActive())
		return;

	bPointing=True;
	bCanClientFire = true;
	AmbientSound = FireSound;
	Pawn(Owner).PlayRecoil(FiringSpeed);
	//if (MedBeam == None) MedBeam = spawn(class'WFMedKitBeam',,Location);
	//else MedBeam.bHidden = false;
	SoundVolume = 255*Pawn(Owner).SoundDampening;
	ClientFire(value);
	GoToState('NormalFire');
}

simulated function PlayAltFiring()
{
	PlayAnim('Fire', 0.5);
	PlayOwnedSound(AltFireSound, SLOT_Misc, 1.7*Pawn(Owner).SoundDampening,,,);
}

simulated function PlayFiring()
{
	if ( Affector != None )
		Affector.FireEffect();
	//PlayOwnedSound(AltFireSound, SLOT_Misc, 1.7*Pawn(Owner).SoundDampening,,,);
	LoopAnim( 'Shake', 0.9);
}

function AltFire( float Value )
{
	if (!WeaponActive())
		return;

	GotoState('AltFiring');
	bPointing=True;
	bCanClientFire = true;
	ClientAltFire(Value);
	if ( bRapidFire || (FiringSpeed > 0) )
		Pawn(Owner).PlayRecoil(FiringSpeed);
	if ( bAltInstantHit )
		TraceFire(0.0);
	else
		ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
}

state NormalFire
{
ignores AnimEnd;

	function AltFire(float Value) { }
	function Fire(float Value) { }

	function BeginState()
	{
		super.BeginState();
		SetTimer(HealTime, false);
		AmbientSound = FireSound;
	}

	function Timer()
	{
		//if (!ValidTarget(MedKitTarget))
		//	MedKitTarget = FindMedKitTarget();
		//HealTarget(MedKitTarget);
		HealPlayers();
		SetTimer(HealTime, false);
	}

	function Tick(float DeltaTime)
	{
		if ((pawn(owner) == None) || (pawn(Owner).bFire == 0))
			Finish();
	}

	function EndState()
	{
		SetTimer(0.0, false);
		AmbientSound = None;
		super.EndState();
	}
}

function HealPlayers()
{
	local pawn aPawn;

	foreach VisibleCollidingActors(class'pawn', aPawn, MedBeamRange, Owner.Location)
		if (ValidTarget(aPawn))
			HealTarget(aPawn);
}

function HealTarget(pawn Other)
{
	local effects e;
	local int MaxHealth;

	if (ValidTarget(Other))
	{
		MaxHealth = GetMaxHealthFor(Other);
		if (Other.Health < MaxHealth)
		{
			Other.Health = Min(Other.Health + HealAmount, MaxHealth);
			e = Spawn(class'WFMedKitHealEffect', Other,, Other.Location);
			e.Mesh = Other.Mesh;
		}
		CurePlayer(Other);
	}
}

// remove any bad status effects
// TODO: maybe change to: Status.CuredBy(pawn(Owner));
function CurePlayer(pawn Other)
{
	local WFPlayerStatus Status;
	local inventory Item, NextItem;
	local int num;
	local bool bCuredStatus;
	local effects e;

	Item = Other.Inventory;
	NextItem = None;
	bCuredStatus = false;
	while (Item != None)
	{
		NextItem = Item.Inventory;
		Status = WFPlayerStatus(Item);
		if ((Status != None) && CanCure(Status.StatusType))
		{
			bCuredStatus = true;
			Status.Destroy();
		}
		Item = NextItem;
	}

	if (bCuredStatus)
	{
		e = Spawn(class'WFMedKitHealEffect', Other,, Other.Location);
		e.Mesh = Other.Mesh;
	}
}

function bool CanCure(string StatusType)
{
	local int i;
	for (i=0; i<16; i++)
		if (StatusType ~= CureStatusTypes[i])
			return true;

	return false;
}

function int GetMaxHealthFor(pawn Other)
{
	local class<WFS_PlayerClassInfo> PCI;

	PCI = class'WFS_PlayerClassInfo'.static.GetPCIFor(Other);
	if (PCI != None)
		return PCI.default.MaxHealth;

	return Other.default.Health;
}

state ClientFiring
{
	simulated function BeginState()
	{
		SoundVolume = 255*Pawn(Owner).SoundDampening;
		AmbientSound = FireSound;
		super.BeginState();
	}
}

function bool ValidTarget(pawn Other)
{
	local vector X, Y, Z;

	GetAxes(Pawn(owner).ViewRotation, X, Y, Z);
	if ((Other != None) && (Other != Owner) && Other.bIsPlayer && (Other.Health > 0)
		&& (VSize(Other.Location - Owner.Location) <= MedBeamRange)
		&& (Other.PlayerReplicationInfo.Team == pawn(Owner).PlayerReplicationInfo.Team)
		&& ((Normal(Other.Location - Owner.Location) dot X) > 0.7) )
		return true;

	return false;
}

function pawn FindMedKitTarget()
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local pawn aPawn, best;
	local Projectile P;
	local float speed, bestproduct, dotproduct;

	//Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation, X, Y, Z);

	bestproduct = 0.0;
	best = None;
	foreach VisibleCollidingActors(class'pawn', aPawn, MedBeamRange, Owner.Location)
	{
		if (ValidTarget(aPawn))
		{
			dotproduct = Normal(aPawn.Location - Owner.Location) dot X;
			if ((dotproduct > 0.7) && (dotproduct > bestproduct))
			{
				best = aPawn;
				bestProduct = dotproduct;
			}
		}
	}

	return Best;
}

simulated function PlayIdleAnim()
{
	TweenAnim( 'Still', 1.0);
}

// trace the alt fire mode
function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;

	PawnOwner = Pawn(Owner);

	Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(PawnOwner.ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;
	AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2*AimError, False, False);
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000;
	X = vector(AdjustedAim);
	EndTrace += (120.0 * X);
	Other = PawnOwner.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local pawn PawnOther;
	local WFPlayerStatus s;

	if (Other == None)
		return;

	if (Other.bIsPawn)
		PawnOther = pawn(Other);

	if ((Other != None) && Other.bIsPawn && PawnOther.bIsPlayer && (PawnOther.health > 0)
		&& (PawnOther.PlayerReplicationInfo.Team == pawn(Owner).PlayerReplicationInfo.Team))
	{
		// vaccinate player
		s = WFPlayerStatus(PawnOther.FindInventoryType(class'WFStatusVaccinated'));
		if (s == None)
		{
			s = spawn(class'WFStatusVaccinated',,, Other.Location);
			s.GiveStatusTo(PawnOther, pawn(Owner));
		}
		else s.LifeSpan = s.default.LifeSpan;
	}
}

defaultproperties
{
	MedBeamRange=180.0
	HealAmount=10
	HealTime=1.0
	bMeshEnviroMap=True
	Texture=Texture'JDomN0'
	AltProjectileClass=class'WFMedKitGasPuff'
	FireSound=sound'TargetHum'
	AltFireSound=Sound'ImpactAltFireRelease'
	FireOffset=(Y=-15.000000,Z=-13.000000)
	CureStatusTypes(0)="Infected"
	CureStatusTypes(1)="Concussed"
	CureStatusTypes(2)="Blinded"
	CureStatusTypes(3)="Tranquilised"
	CureStatusTypes(4)="Leg damage"
	Mass=20
	DeathMessage="%o was killed by %k's toxic gas"
	SoundRadius=50
	SoundVolume=128
	InventoryGroup=2
	AutoSwitchPriority=2
     PlayerViewOffset=(X=3.800000,Y=-1.600000,Z=-1.800000)
     PlayerViewMesh=LodMesh'Botpack.ImpactHammer'
     PickupViewMesh=LodMesh'Botpack.ImpPick'
     ThirdPersonMesh=LodMesh'Botpack.ImpactHandm'
     ThirdPersonScale=0.5
     StatusIcon=Texture'Botpack.Icons.UseHammer'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UseHammer'
     Mesh=LodMesh'Botpack.ImpPick'
    bAltInstantHit=true
}