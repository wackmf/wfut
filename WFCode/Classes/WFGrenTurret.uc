class WFGrenTurret extends WFGrenadeItem;

function actor ThrowGrenade()
{
	local vector dir, InitialVelocity;
	local float VelocityScale;
	local projectile DroppedGrenade;

	// calculate the grenades starting direction and velocity
	dir = vector(pawn(Owner).ViewRotation);
	dir.z = dir.Z + 0.35 * (1 - Abs(dir.Z));

	VelocityScale = Max(1.0, ThrowingTime);
	InitialVelocity = (FMin(BaseVelocity * VelocityScale, MaximumVelocity) * Normal(dir)) + Owner.Velocity*0.5;

	DroppedGrenade = DropProjectile(InitialVelocity);
	class'WFS_PlayerClassInfo'.static.AddRelatedActor(PCSOwner, DroppedGrenade);

	return DroppedGrenade;
}

function bool CanThrowGrenade()
{
	if (class'WFS_PlayerClassInfo'.static.RelatedActorCount(PCSOwner, class'WFGrenTurretProj') < 2)
		return true;

	return false;
}

defaultproperties
{
	ProjectileClass=class'WFGrenTurretProj'
	ThrowDelayTime=0.5
	GrenadeSlot=2
	bCanHaveMultipleCopies=True
	bActivatable=True
	bDisplayableInv=True
	PickupMessage="You picked up a Turret Grenade"
	ItemName="Turret Grenade"
	PickupViewMesh=LodMesh'UnrealShare.VoiceBoxMesh'
	PickupSound=Sound'UnrealShare.Pickups.GenPickSnd'
	Icon=Texture'UnrealI.Icons.I_SludgeAmmo'
	CollisionRadius=18.000000
	CollisionHeight=8.000000
	PrimingTime=0.500000
	NumCopies=1
	bSingleGrenade=False
	StatusIcon=Texture'WFMedia.GrenadeTurret'
}
