class WFDemomanHUDMenu extends WFClassHUDMenu;

// proccess a selection
function ProcessSelection(int Selection)
{
	DisplayTimeLeft = DisplayTime;

	//Log("procsel"@Selection);
	if (ChildMenu != none)
	{
		ChildMenu.ProcessSelection(Selection);
		return;
	}

	switch (Selection)
	{
		case 0:
			break;
		case 1:
			PlayerOwner.Special("setmine");
			CloseMenu();
			break;
		case 2:
			PlayerOwner.Special("removemine");
			CloseMenu();
			break;
		case 3:
			CreateChildMenu(class'WFDemomanTriggerHUDMenu');
			break;
		case 10:
			CloseMenu();
			break;
	}
}

defaultproperties
{
	DisplayTime=10
	NumOptions=5
	bAlignAppendString=True
	SeparatorString=":  "
	MenuTitle="[ - Demoman Options - ]"
	MenuOptions(0)="Set Laser Tripmine"
	MenuOptions(1)="Remove Laser Tripmine"
	MenuOptions(2)="Deploy Prox Trigger"
	MenuOptions(8)=" "
	MenuOptions(9)="Close Menu"
	MenuOptionColors(3)=(R=128,G=128,B=128)
	MenuOptionColors(4)=(R=128,G=128,B=128)
	bUseColors=True
}
