//-------------------------------------------------
// Leather Armour (a thick, padded biker jacket)
//-------------------------------------------------
const LEATHERARMOUR=50;
const ENC_LEATHERARMOUR=100;
//const HDCONST_BATTLEARMOUR=70;
//const HDCONST_GARRISONARMOUR=144;

class HDLeatherArmour:HDArmour{
	default{
		//+inventory.invbar
		//+hdpickup.cheatnogive
		//+hdpickup.notinpockets
		//+inventory.isarmor
		//inventory.amount 1;
		hdmagammo.maxperunit LEATHERARMOUR;
		hdmagammo.magbulk ENC_LEATHERARMOUR;
		tag "leather jacket";
		inventory.icon "JAKTA0";
		inventory.pickupmessage "Picked up a leather jacket.";
	}
	
	override string pickupmessage(){
		return "Picked up a leather jacket!";
	}

	//because it can intentionally go over the maxperunit amount
	override void AddAMag(int addamt){
		if(addamt<0)addamt=LeatherArmour;
		mags.push(addamt);
		amount=mags.size();
	}
	//keep types the same when maxing
	override void MaxCheat(){
		syncamount();
		for(int i=0;i<amount;i++){
			mags[i]=LeatherArmour;
		}
	}

	action void A_WearJacket(){
		bool helptext=HDWeapon.CheckDoHelpText(self);
		invoker.syncamount();
		int dbl=invoker.mags[invoker.mags.size()-1];
		//if holding use, cycle to next armour
		if(!!player&&player.cmd.buttons&BT_USE){
			invoker.mags.insert(0,dbl);
			invoker.mags.pop();
			invoker.syncamount();
			return;
		}

		invoker.wornlayer=STRIP_ARMOUR;
		bool intervening=!HDPlayerPawn.CheckStrip(self,invoker,false);
		invoker.wornlayer=0;

		if(intervening){

			//check if it's ONLY the armour layer that's in the way
			invoker.wornlayer=STRIP_ARMOUR+1;
			bool notarmour=!HDPlayerPawn.CheckStrip(self,invoker,false);
			invoker.wornlayer=0;

			if(
				notarmour
				||invoker.cooldown>0
			){
				HDPlayerPawn.CheckStrip(self,self);
			}else invoker.cooldown=10;
			return;
		}

		//and finally put on the actual armour
		HDLeatherArmour.JacketChangeEffect(self,100);
		A_GiveInventory("HDLeatherArmourWorn");
		let worn=HDLeatherArmourWorn(FindInventory("HDLeatherArmourWorn"));

		worn.durability=dbl;
		invoker.amount--;
		invoker.mags.pop();

		if(helptext){
			string blah=string.format("You put on the %s armour. ","leather");
			double qual=double(worn.durability)/(LEATHERARMOUR);
			if(qual<0.1)A_Log(blah.."It's like you're wearing nothing at all.",true);
			else if(qual<0.3)A_Log(blah.."Both sleeves are gone.",true);
			else if(qual<0.6)A_Log(blah.."It's missing a sleeve.",true);
			else if(qual<0.75)A_Log(blah.."There's a few holes in it.",true);
			else if(qual<0.95)A_Log(blah.."This jacket's scratched up.",true);
		}

		invoker.syncamount();
	}

	override void syncamount(){
		if(amount<1){destroy();return;}
		super.syncamount();
		for(int i=0;i<amount;i++){
			mags[i]=min(mags[i],LEATHERARMOUR);
		}
		checkmega();
	}

	override inventory createtossable(int amt){
		let sct=super.createtossable(amt);
		return sct;
	}

    bool checkmega(){
		mega=0;
		icon=texman.checkfortexture("JAKTA0",TexMan.Type_MiscPatch);
		return mega;
	}

	override void beginplay(){
		super.beginplay();
		cooldown=0;
		if(!mags.size())mags.push(LEATHERARMOUR); //not vital, just sets a default
	}

	override void consolidate(){}
	override double getbulk(){
		syncamount();
		double blk=0;
		for(int i=0;i<amount;i++){
			blk+=ENC_LEATHERARMOUR;
		}
		return blk;
	}

	override bool BeforePockets(actor other){
		//put on the armour right away
		if(
			other.player
			&&other.player.cmd.buttons&BT_USE
			&&!other.findinventory("HDLeatherArmourWorn")
		){
			wornlayer=STRIP_ARMOUR;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			HDLeatherArmour.JacketChangeEffect(other,50);
			let worn=HDLeatherArmourWorn(other.GiveInventoryType("HDLeatherArmourWorn"));
			int durability=mags[mags.size()-1];
			worn.durability=durability;
			destroy();
			return true;
		}
		return false;
	}


	override void actualpickup(actor other,bool silent){
		cooldown=0;
		if(!other)return;
		int durability=mags[mags.size()-1];
		HDLeatherArmour aaa=HDLeatherArmour(other.findinventory("HDLeatherArmour"));

		//one megaarmour = 2 regular armour
		if(aaa){
			double totalbulk=(durability>=1000)?2.:1.;
			for(int i=0;i<aaa.mags.size();i++){
				totalbulk+=(aaa.mags[i]>=1000)?2.:1.;
			}
			if(totalbulk*hdmath.getencumbrancemult()>3.)return;
		}
		if(!trypickup(other))return;
		aaa=HDLeatherArmour(other.findinventory("HDLeatherArmour"));
		aaa.syncamount();
		aaa.mags.insert(0,durability);
		aaa.mags.pop();
		aaa.checkmega();
		other.A_StartSound(pickupsound,CHAN_AUTO);
		HDPickup.LogPickupMessage(other,pickupmessage());
	}
	
	//modified to make removing your jacket faster than
	//removing an armor vest
	static void JacketChangeEffect(actor owner,int delay=25){
		owner.A_StartSound("weapons/pocket",CHAN_BODY);
		owner.vel.z+=1.;
		let onr=HDPlayerPawn(owner);
		if(onr){
			onr.stunned+=50;
			onr.striptime=delay;
			onr.AddBlackout(256,96,128);
		}else owner.A_SetBlend("00 00 00",1,6,"00 00 00");
	}
	states{
	spawn:
		JAKT A -1 nodelay{
			invoker.SyncAmount();
		}
	use:
		TNT1 A 0 A_WearJacket();
		fail;
	}
}


class HDLeatherArmourWorn:HDArmourWorn{
	default{
		+inventory.isarmor
		HDArmourworn.ismega false;
		inventory.maxamount 1;
		tag "leather jacket";
	}
	override void beginplay(){
		durability=LEATHERARMOUR;
		super.beginplay();
		//if(mega)settag("battle armour");
	}

	override double RestrictSpeed(double speedcap){
		return min(speedcap,4);//lighter than garrison armour
	}
	override double getbulk(){
		return (ENC_LEATHERARMOUR*0.1);
	}

	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		vector2 coords=
			(hdflags&HDSB_AUTOMAP)?(4,86):
			(hdflags&HDSB_MUGSHOT)?((sb.hudlevel==1?-85:-55),-4):
			(0,-sb.mIndexFont.mFont.GetHeight()*2)
		;
		string armoursprite="JAKTA0";//front layer
		string armourback="JAKET0";//back layer
		sb.drawbar(
			armoursprite,armourback,
			durability,LEATHERARMOUR,
			coords,-1,sb.SHADER_VERT,
			gzflags
		);
		sb.drawstring(
			sb.pnewsmallfont,sb.FormatNumber(durability),
			coords+(10,-7),gzflags|sb.DI_ITEM_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_DARKGRAY,scale:(0.5,0.5)
		);
	}


	override inventory CreateTossable(int amt){
		if(!HDPlayerPawn.CheckStrip(owner,self))return null;

		//armour sometimes crumbles into dust
		if(durability<random(1,3)){
			for(int i=0;i<10;i++){
				actor aaa=spawn("WallChunk",owner.pos+(0,0,owner.height-24),ALLOW_REPLACE);
				vector3 offspos=(frandom(-12,12),frandom(-12,12),frandom(-16,4));
				aaa.setorigin(aaa.pos+offspos,false);
				aaa.vel=owner.vel+offspos*frandom(0.3,0.6);
				aaa.scale*=frandom(0.8,2.);
			}
			destroy();
			return null;
		}

		//finally actually take off the armour
		let tossed=HDLeatherArmour(owner.spawn("HDLeatherArmour",
			(owner.pos.xy,owner.pos.z+owner.height-20),
			ALLOW_REPLACE
		));
		tossed.mags.clear();
		tossed.mags.push(durability);
		tossed.amount=1;
		HDLeatherArmour.JacketChangeEffect(owner,30);
		destroy();
		return tossed;
	}


	states{
	spawn:
		TNT1 A 0;
		stop;
	}
}

class JacketArmour:HDPickupGiver{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Leather Jacket"
		//$Sprite "JAKTA0"
		//+missilemore
		+hdpickup.fitsinbackpack
		+inventory.isarmor
		inventory.icon "JAKTA0";
		hdpickupgiver.pickuptogive "HDLeatherArmour";
		hdpickup.bulk ENC_LEATHERARMOUR;
		hdpickup.refid "arl";
		tag "leather jacket (spare)";
		inventory.pickupmessage "Picked up a leather jacket.";
	}
	override void configureactualpickup(){
		let aaa=HDLeatherArmour(actualitem);
		aaa.mags.clear();
		aaa.mags.push(LEATHERARMOUR);
		aaa.syncamount();
	}
}

class JacketArmourWorn:HDPickup{
	default{
		//+missilemore
		-hdpickup.fitsinbackpack
		+inventory.isarmor
		hdpickup.refid "awl";
		tag "leather jacket";
		inventory.maxamount 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(owner){
			owner.A_GiveInventory("HDLeatherArmourWorn");
			let ga=HDLeatherArmourWorn(owner.findinventory("HDLeatherArmourWorn"));
			ga.durability=(LEATHERARMOUR);
		}
		destroy();
	}
}
