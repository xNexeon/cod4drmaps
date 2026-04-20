//--------------------------------------------------
//	Deathrun Essentials - By GCZ|Slaya (JR-Imagine)
//--------------------------------------------------

#include maps\mp\gametypes\_hud_util;
#include braxi\_dvar;
#include braxi\_common;

init( modVersion )
{
	level endon ("map_restart");
//	self endon ("death");
//	self endon ("joined_spectator");
//	self endon ("disconnect");

	addDvar( "essentials_menu_enabled", "plugin_essentials_menu_enable", 1, 0, 1, "int" );
	addDvar( "essentials_menu_points_max", "plugin_essentials_menu_points_max", 256, 0, 256, "int" );
	addDvar( "healthbar_enabled", "plugin_healthbar_enable", 1, 0, 1, "int" );
	addDvar( "guid_spoof_enabled", "plugin_guid_spoofing_enable", 1, 0, 1, "int" );
	addDvar( "no_double_music", "plugin_no_double_music", 1, 0, 1, "int" );
	addDvar( "disco_enabled", "plugin_disco_enable", 1, 0, 1, "int" );
	addDvar( "rtd_enabled", "plugin_rtd_enable", 1, 0, 1, "int" );
	addDvar( "antiwallbang_enabled", "plugin_antiwallbang_enable", 1, 0, 1, "int" );

	if( level.dvar["essentials_menu_enabled"] == 1 )
		EssentialsMenu_init(); // Essentials menu

	thread playerSpawned(); // Disable Jumper Weapons at start of round
	level thread PlayerDamage(); // Hitmarkers
	thread tomahawk_init(); // Tomahawk
	thread killcam_init();
	thread anti_afk_acti_init();

	if( level.dvar["healthbar_enabled"] == 1 )
	thread healthbar();

	if( level.dvar["guid_spoof_enabled"] == 1 )
		thread GUID_Spoofing();

	if( level.dvar["no_double_music"] == 1 )
	{
		thread onIntermission();
		thread no_double_music();
	}

	if( level.dvar["disco_enabled"] == 1 )
		thread partymode();

	if( level.dvar["rtd_enabled"] == 1 )
		thread rtd_init();

	if( level.dvar["antiwallbang_enabled"] == 1 )
		level.callbackPlayerDamage = ::Callback_PlayerDamage;
}

// ESSENTIALS MENU - Based of VIP Menu by Duffman //
EssentialsMenu_init()
{
	// This button is used to open the menu, you can change it to any UNUSED button you want
	level.menubutton = "P";

	addDvar( "essentials_menu_points_enabled", "plugin_essentials_menu_points_enable", 1, 0, 1, "int" );

	addDvar( "price_m9", "plugin_price_m9", 20, 1, 32569, "int" );
	addDvar( "price_m1911", "plugin_price_m1911", 25, 1, 32569, "int" );
	addDvar( "price_usp", "plugin_price_usp", 25, 1, 32569, "int" );
	addDvar( "price_deagle", "plugin_price_deagle", 30, 1, 32569, "int" );
	addDvar( "price_gold_deagle", "plugin_price_gold_deagle", 30, 1, 32569, "int" );
	addDvar( "price_colt44", "plugin_price_colt44", 30, 1, 32569, "int" );
	addDvar( "price_m40a3", "plugin_price_m40a3", 30, 1, 32569, "int" );
	addDvar( "price_r700", "plugin_price_r700", 30, 1, 32569, "int" );

	if( level.dvar["essentials_menu_points_enabled"] == 1 )
	{
		level.ess_allow_weap_buy = true;

		endtrig = getEnt("endmap_trig","targetname");
		if(isDefined(endtrig))
		{
			level.ess_allow_weap_buy = true;
			iPrintln("^3Essentials Menu:^7 Buying Weapons ^1Enabled");
			if( level.dvar["essentials_menu_points_enabled"] == 1 )
				thread ess_onMapFinish();
		}
		else
		{
			level.ess_allow_weap_buy = false;
			iPrintln("^3Essentials Menu:^7 Buying Weapons ^1Disabled ^7(EndMap Trigger not Found)");
		}
	}

	//-------------------------------------------------
	
	/*------------------Menu options-------------------
		STEP 1

		Syntax:  addMenuOption(a,b,c);
		a = name which will be displayed in the menu NOTE: the total of all Displayed names must be !!!shorter then 256 characters!!! otherwise they are invisible
		b = Menu Alias, if the option is in the main window you have to use "main"
			else you have to use a submenu which can be defined in STEP 2
		c = script function you want to call using the menu
			example: braxi\_mod::giveLife  NOTE: if the function is located in THIS file you can also use ::XXXXX 

		STEP 2

		Syntax: addSubMenu(a,b);
		a = Displayname of the Menu
		b = Menu Alias like "giveweapon" or "shit_things"
	*/

	addMenuOption("Fullbright","main",::ess_fullbright);
	addSubMenu("FOV","fov");
		addMenuOption("65","fov",::ess_fov65);
		addMenuOption("70","fov",::ess_fov70);
		addMenuOption("75","fov",::ess_fov75);
		addMenuOption("80","fov",::ess_fov80);
	addSubMenu("FOV Scale","fovscale");
		addMenuOption("1.00","fovscale",::ess_fovscale_1);
		addMenuOption("1.05","fovscale",::ess_fovscale_2);
		addMenuOption("1.10","fovscale",::ess_fovscale_3);
		addMenuOption("1.15","fovscale",::ess_fovscale_4);
		addMenuOption("1.20","fovscale",::ess_fovscale_5);
		addMenuOption("1.25","fovscale",::ess_fovscale_6);
		addMenuOption("1.30","fovscale",::ess_fovscale_7);
	addMenuOption("Laser","main",::ess_laser);
	if( level.dvar["essentials_menu_points_enabled"] == 1 )
	{
		addSubMenu("Weapons","give_weap");
			addMenuOption("M9 (Cost: " + level.dvar["price_m9"] + ")","give_weap",::ess_weap_m9);
			addMenuOption("Colt M1911 (Cost: " + level.dvar["price_m1911"] + ")","give_weap",::ess_weap_m1911);
			addMenuOption("USP .45 (Cost: " + level.dvar["price_usp"] + ")","give_weap",::ess_weap_usp);
			addMenuOption("Desert Eagle (Cost: " + level.dvar["price_deagle"] + ")","give_weap",::ess_weap_deagle);
			addMenuOption("Gold Desert Eagle (Cost: " + level.dvar["price_gold_deagle"] + ")","give_weap",::ess_weap_gold_deagle);
			addMenuOption("Colt 44 Magnum (Cost: " + level.dvar["price_colt44"] + ")","give_weap",::ess_weap_colt44);
			addMenuOption("M40A3 (Cost: " + level.dvar["price_m40a3"] + ")","give_weap",::ess_weap_m40a3);
			addMenuOption("Remington 700 (Cost: " + level.dvar["price_r700"] + ")","give_weap",::ess_weap_r700);
	}
	if( level.dvar["rtd_enabled"] == 1 )
		addMenuOption("Roll the Dice","main",::rtd_activate);
	addMenuOption("Ammo","main",::ess_ammo);
	addMenuOption("Suicide","main",::ess_suicide);

	//----------------------DO NOT EDIT ANYTHING BELOW THIS LINE---------------------------
	shaders = strTok("ui_host;line_vertical;nightvision_overlay_goggles;hud_arrow_left",";");
	for(i=0;i<shaders.size;i++) precacheShader(shaders[i]);
	thread ess_onPlayerConnected();
	thread ess_onPlaySpawned();
}
ess_onPlayerConnected() {
	for(;;) {
		level waittill("connected",player);
		player.inessentials_menu = false; // Initialize as false
        player.frozen = 0;               // Initialize as 0
		player setClientDvar("r_fullbright",(player getStat(714)));
		player setClientDvar("cg_laserForceOn",(player getStat(3254)));

		player.scale = player getStat(3255);
		if(player.scale == 2)
			player setClientDvar("cg_fovscale",1.05);
		else if(player.scale == 3)
			player setClientDvar("cg_fovscale",1.1);
		else if(player.scale == 4)
			player setClientDvar("cg_fovscale",1.15);
		else if(player.scale == 5)
			player setClientDvar("cg_fovscale",1.2);
		else if(player.scale == 6)
			player setClientDvar("cg_fovscale",1.25);
		else if(player.scale == 7)
			player setClientDvar("cg_fovscale",1.3);
		else
			player setClientDvar("cg_fovscale",1);

		player braxi\_common::clientCmd("bind "+level.menubutton+" openscriptmenu y essentials_menu");
		player thread OnMenuResponse();
	}
}
ess_onPlaySpawned()
{
	for(;;)
	{
		level waittill("player_spawn",player);
		player iPrintln("Press ^3"+level.menubutton+"^7 to open Essentials Menu");
		if( level.dvar["essentials_menu_points_enabled"] == 1 )
			player thread ess_points();
	}
}
ess_onMapFinish()
{
	trig = getEnt("endmap_trig","targetname");
	if( isDefined(trig) )
	{
		trig waittill("trigger");
		if(level.ess_allow_weap_buy == true)
		{
			level.ess_allow_weap_buy = false;
			iPrintln("^3Essentials Menu:^7 Buying Weapons ^1Disabled");
		}
	}
}
OnMenuResponse() {
	self endon("disconnect");
	self.inessentials_menu = false;
	for(;;wait .05) {
		self waittill("menuresponse", menu, response);
		if(!self.inessentials_menu && response == "essentials_menu" && self.frozen == 0) {
			self.inessentials_menu = true;
			for(;self.sessionstate == "playing" && !self isOnGround();wait .05){}
			self thread EssentialsMenu();
			self disableWeapons();
			self freezeControls(true);			
			self allowSpectateTeam( "allies", false );
			self allowSpectateTeam( "axis", false );
			self allowSpectateTeam( "none", false );			
		}
		else if(self.inessentials_menu && response == "essentials_menu") self endMenu();	
	}
}
endMenu() {
	self notify("close_essentials_menu");
	for(i=0;i<self.essentials_menu.size;i++) self.essentials_menu[i] thread FadeOut(1,true,"right");
	self thread Blur(2,0);
	self.essentials_menubg thread FadeOut(1);
	self.inessentials_menu = false;
	self enableWeapons();
	self freezeControls(false);
	self allowSpectateTeam( "allies", true );
	self allowSpectateTeam( "axis", true );
	self allowSpectateTeam( "none", true );
}
addMenuOption(name,menu,script) {
	if(!isdefined(level.menuoption)) level.menuoption["name"] = [];	
	if(!isDefined(level.menuoption["name"][menu])) level.menuoption["name"][menu] = [];
	level.menuoption["name"][menu][level.menuoption["name"][menu].size] = name;
	level.menuoption["script"][menu][level.menuoption["name"][menu].size] = script;
}
addSubMenu(displayname,name) {
	addMenuOption(displayname,"main",name);
}
GetMenuStuct(menu) {
	itemlist = "";
	for(i=0;i<level.menuoption["name"][menu].size;i++) itemlist = itemlist + level.menuoption["name"][menu][i] + "\n";
	return itemlist;
}
EssentialsMenu() {
	self endon("close_essentials_menu");
	self endon("disconnect");
	self thread Blur(0,2);
	submenu = "main";
	self.essentials_menu[0] = addTextHud( self, -200, 0, .6, "left", "top", "right",0, 101 );	
	self.essentials_menu[0] setShader("nightvision_overlay_goggles", 400, 650);
	self.essentials_menu[0] thread FadeIn(.5,true,"right");
	self.essentials_menu[1] = addTextHud( self, -200, 0, .5, "left", "top", "right", 0, 101 );	
	self.essentials_menu[1] setShader("black", 400, 650);	
	self.essentials_menu[1] thread FadeIn(.5,true,"right");
	self.essentials_menu[2] = addTextHud( self, -200, 89, .5, "left", "top", "right", 0, 102 );		
	self.essentials_menu[2] setShader("line_vertical", 600, 22);
	self.essentials_menu[2] thread FadeIn(.5,true,"right");	
	self.essentials_menu[3] = addTextHud( self, -190, 93, 1, "left", "top", "right", 0, 104 );		
	self.essentials_menu[3] setShader("ui_host", 14, 14);			
	self.essentials_menu[3] thread FadeIn(.5,true,"right");
	self.essentials_menu[4] = addTextHud( self, -165, 100, 1, "left", "middle", "right", 1.4, 103 );
	self.essentials_menu[4] settext(GetMenuStuct(submenu));
	self.essentials_menu[4] thread FadeIn(.5,true,"right");
	self.essentials_menu[5] = addTextHud( self, -170, 400, 1, "left", "middle", "right" ,1.4, 103 );
	self.essentials_menu[5] settext("^7Select: ^3[Right or Left Mouse]^7\nUse: ^3[[{+activate}]]^7\nLeave: ^3[[{+melee}]]\n^3Essentials Menu ^7by GCZ|Slaya");	
	self.essentials_menu[5] thread FadeIn(.5,true,"right");
	self.essentials_menubg = addTextHud( self, 0, 0, .5, "left", "top", undefined , 0, 101 );	
	self.essentials_menubg.horzAlign = "fullscreen";
	self.essentials_menubg.vertAlign = "fullscreen";
	self.essentials_menubg setShader("black", 640, 480);
	self.essentials_menubg thread FadeIn(.2);
	for(selected=0;!self meleebuttonpressed();wait .05) {
		if(self Attackbuttonpressed()) {
			self playLocalSound( "mouse_over" );
			if(selected == level.menuoption["name"][submenu].size-1) selected = 0;
			else selected++;	
		}
		if(self adsbuttonpressed()) {
			self braxi\_common::clientCmd("-speed_throw");
			self playLocalSound( "mouse_over" );
			if(selected == 0) selected = level.menuoption["name"][submenu].size-1;
			else selected--;
		}
		if(self adsbuttonpressed() || self Attackbuttonpressed()) {
			if(submenu == "main") {
				self.essentials_menu[2] moveOverTime( .05 );
				self.essentials_menu[2].y = 89 + (16.8 * selected);	
				self.essentials_menu[3] moveOverTime( .05 );
				self.essentials_menu[3].y = 93 + (16.8 * selected);	
			}
			else {
				self.essentials_menu[7] moveOverTime( .05 );
				self.essentials_menu[7].y = 10 + self.essentials_menu[6].y + (16.8 * selected);	
			}
		}
		if((self adsbuttonpressed() || self Attackbuttonpressed()) && !self useButtonPressed()) wait .15;
		if(self useButtonPressed()) {
			if(!isString(level.menuoption["script"][submenu][selected+1])) {
				self thread [[level.menuoption["script"][submenu][selected+1]]]();
				self thread endMenu();
				self notify("close_essentials_menu");
			}
			else {
				abstand = (16.8 * selected);
				submenu = level.menuoption["script"][submenu][selected+1];
				self.essentials_menu[6] = addTextHud( self, -430, abstand + 50, .5, "left", "top", "right", 0, 101 );	
				self.essentials_menu[6] setShader("black", 200, 300);	
				self.essentials_menu[6] thread FadeIn(.5,true,"left");
				self.essentials_menu[7] = addTextHud( self, -430, abstand + 60, .5, "left", "top", "right", 0, 102 );		
				self.essentials_menu[7] setShader("line_vertical", 200, 22);
				self.essentials_menu[7] thread FadeIn(.5,true,"left");
				self.essentials_menu[8] = addTextHud( self, -219, 93 + (16.8 * selected), 1, "left", "top", "right", 0, 104 );		
				self.essentials_menu[8] setShader("hud_arrow_left", 14, 14);			
				self.essentials_menu[8] thread FadeIn(.5,true,"left");
				self.essentials_menu[9] = addTextHud( self, -420, abstand + 71, 1, "left", "middle", "right", 1.4, 103 );
				self.essentials_menu[9] settext(GetMenuStuct(submenu));
				self.essentials_menu[9] thread FadeIn(.5,true,"left");
				selected = 0;
				wait .2;
			}
		}
	}
	self thread endMenu();
}
addTextHud( who, x, y, alpha, alignX, alignY, vert, fontScale, sort ) { //stealed braxis function like a boss xD
	if( isPlayer( who ) ) hud = newClientHudElem( who );
	else hud = newHudElem();

	hud.x = x;
	hud.y = y;
	hud.alpha = alpha;
	hud.sort = sort;
	hud.alignX = alignX;
	hud.alignY = alignY;
	if(isdefined(vert))
		hud.horzAlign = vert;
	if(fontScale != 0)
		hud.fontScale = fontScale;
	return hud;
}
FadeOut(time,slide,dir) {	
	if(!isDefined(self)) return;
	if(isdefined(slide) && slide) {
		self MoveOverTime(0.2);
		if(isDefined(dir) && dir == "right") self.x+=600;
		else self.x-=600;
	}
	self fadeovertime(time);
	self.alpha = 0;
	wait time;
	if(isDefined(self)) self destroy();
}
FadeIn(time,slide,dir) {
	if(!isDefined(self)) return;
	if(isdefined(slide) && slide) {
		if(isDefined(dir) && dir == "right") self.x+=600;
		else self.x-=600;	
		self moveOverTime( .2 );
		if(isDefined(dir) && dir == "right") self.x-=600;
		else self.x+=600;
	}
	alpha = self.alpha;
	self.alpha = 0;
	self fadeovertime(time);
	self.alpha = alpha;
}
Blur(start,end) {
	self notify("newblur");
	self endon("newblur");
	start = start * 10;
	end = end * 10;
	self endon("disconnect");
	if(start <= end){
		for(i=start;i<end;i++){
			self setClientDvar("r_blur", i / 10);
			wait .05;
		}
	}
	else for(i=start;i>=end;i--){
		self setClientDvar("r_blur", i / 10);
		wait .05;
	}
}

// ESSENTIALS MENU - POINTS //
ess_points()
{
    self endon("disconnect"); // Add this!
    self endon("death");      // Add this!
	while(1)
	{
		self.points = self getStat(3256);
		if( self.points < level.dvar["essentials_menu_points_max"] )
		{
			self.points += 1;
			self setStat(3256,self.points);
			if( self.points == level.dvar["essentials_menu_points_max"] )
			{
				self iPrintln("^3Essentials Menu:^7 Maximum amount of Points reached");
			}
		}
		self thread ess_points_hud(self.points);
		wait 5;
	}
}

ess_points_hud(points)
{
	self endon( "disconnect" );

    while( !isPlayer( self ) || !isAlive( self ) )
        wait( 0.05 );

    if( isDefined( self.pnts ) )
        self.pnts destroy();

    self.pnts = newClientHudElem( self );
    self.pnts.alignX = "left";
    self.pnts.alignY = "bottom";
    self.pnts.horzAlign = "left";
    self.pnts.vertAlign = "bottom";
    self.pnts.x = 8;
    self.pnts.y = -54;
    self.pnts.font = "objective";
    self.pnts.fontScale = 1.8;
    self.pnts.color = ( 1, 1, 1 );
    self.pnts.alpha = 1;
    self.pnts.glowColor = ( 0, 1, 0 );
    self.pnts.glowAlpha = 1;
    self.pnts.label     = &"Points: &&1";
    self.pnts.hideWhenInMenu = true;

    self.pnts setValue( points );
}

// ESSENTIALS MENU - OPTIONS //
ess_fullbright()
{
	if(self getStat(714))
	{
		self iPrintln( "Fullbright ^1[OFF]" );
		self setClientDvar( "r_fullbright", 0 );
		self setStat(714,0);
	}
	else
	{
		self iPrintln( "Fullbright ^1[ON]" );
		self setClientDvar( "r_fullbright", 1 );
		self setStat(714,1);
	}
}
ess_fov65()
{
	self setClientDvar("cg_fov",65);
	self iPrintln( "FOV set to ^165" );
}
ess_fov70()
{
	self setClientDvar("cg_fov",70);
	self iPrintln( "FOV set to ^170" );
}
ess_fov75()
{
	self setClientDvar("cg_fov",75);
	self iPrintln( "FOV set to ^175" );
}
ess_fov80()
{
	self setClientDvar("cg_fov",80);
	self iPrintln( "FOV set to ^180" );
}
ess_fovscale_1()
{
	self setClientDvar("cg_fovscale",1);
	self setStat(3255,1);
	self iPrintln( "FOV Scale set to ^11.00" );
}
ess_fovscale_2()
{
	self setClientDvar("cg_fovscale",1.05);
	self setStat(3255,2);
	self iPrintln( "FOV Scale set to ^11.05" );
}
ess_fovscale_3()
{
	self setClientDvar("cg_fovscale",1.1);
	self setStat(3255,3);
	self iPrintln( "FOV Scale set to ^11.10" );
}
ess_fovscale_4()
{
	self setClientDvar("cg_fovscale",1.15);
	self setStat(3255,4);
	self iPrintln( "FOV Scale set to ^11.15" );
}
ess_fovscale_5()
{
	self setClientDvar("cg_fovscale",1.2);
	self setStat(3255,5);
	self iPrintln( "FOV Scale set to ^11.20" );
}
ess_fovscale_6()
{
	self setClientDvar("cg_fovscale",1.25);
	self setStat(3255,6);
	self iPrintln( "FOV Scale set to ^11.25" );
}
ess_fovscale_7()
{
	self setClientDvar("cg_fovscale",1.3);
	self setStat(3255,7);
	self iPrintln( "FOV Scale set to ^11.30" );
}
ess_laser()
{
	if(self getStat(3254))
	{
		self iPrintln( "Laser ^1[OFF]" );
		self setClientDvar( "cg_laserForceOn", 0 );
		self setStat(3254,0);
	}
	else
	{
		self iPrintln( "Laser ^1[ON]" );
		self setClientDvar( "cg_laserForceOn", 1 );
		self setStat(3254,1);
	}
}
ess_weap_m9()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("beretta_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_m9"] - 1))
				{
					PrecacheItem("beretta_mp");
					self TakeAllWeapons();
					self giveWeapon("beretta_mp");
					self GiveMaxAmmo("beretta_mp");
					self SwitchToWeapon("beretta_mp");
					self.points -= 20;
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_m1911()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("colt45_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_m1911"] - 1))
				{
					PrecacheItem("colt45_mp");
					self TakeAllWeapons();
					self giveWeapon("colt45_mp");
					self GiveMaxAmmo("colt45_mp");
					self SwitchToWeapon("colt45_mp");
					self.points -= level.dvar["price_m1911"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_usp()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("usp_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_usp"] - 1))
				{
					PrecacheItem("usp_mp");
					self TakeAllWeapons();
					self giveWeapon("usp_mp");
					self GiveMaxAmmo("usp_mp");
					self SwitchToWeapon("usp_mp");
					self.points -= level.dvar["price_usp"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_deagle()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("deserteagle_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_deagle"] - 1))
				{
					PrecacheItem("deserteagle_mp");
					self TakeAllWeapons();
					self giveWeapon("deserteagle_mp");
					self GiveMaxAmmo("deserteagle_mp");
					self SwitchToWeapon("deserteagle_mp");
					self.points -= level.dvar["price_deagle"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_gold_deagle()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("deserteaglegold_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_gold_deagle"] - 1))
				{
					PrecacheItem("deserteaglegold_mp");
					self TakeAllWeapons();
					self giveWeapon("deserteaglegold_mp");
					self GiveMaxAmmo("deserteaglegold_mp");
					self SwitchToWeapon("deserteaglegold_mp");
					self.points -= level.dvar["price_gold_deagle"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_colt44()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("colt44_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_colt44"] - 1))
				{
					PrecacheItem("colt44_mp");
					self TakeAllWeapons();
					self giveWeapon("colt44_mp");
					self GiveMaxAmmo("colt44_mp");
					self SwitchToWeapon("colt44_mp");
					self.points -= level.dvar["price_colt44"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_m40a3()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("m40a3_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_m40a3"] - 1))
				{
					PrecacheItem("m40a3_mp");
					self TakeAllWeapons();
					self giveWeapon("m40a3_mp");
					self GiveMaxAmmo("m40a3_mp");
					self SwitchToWeapon("m40a3_mp");
					self.points -= level.dvar["price_m40a3"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_weap_r700()
{
	if(level.ess_allow_weap_buy == true)
	{
		if( self.pers["team"] == "allies" )
		{
			if(!self hasWeapon("remington700_mp"))
			{
				self.points = self getStat(3256);
				if(self.points > (level.dvar["price_r700"] - 1))
				{
					PrecacheItem("remington700_mp");
					self TakeAllWeapons();
					self giveWeapon("remington700_mp");
					self GiveMaxAmmo("remington700_mp");
					self SwitchToWeapon("remington700_mp");
					self.points -= level.dvar["price_r700"];
					self setStat(3256,self.points);
					self thread ess_points_hud(self.points);
				}
				else
					self iPrintln("You do not have enough ^1Points^7!");
			}
			else
				self iPrintln("You already have this weapon equipped!");
		}
		else
			self iPrintln("^1Activators ^7are not allowed to buy weapons!");
	}
	else
		self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled");
}
ess_ammo()
{
	self GiveMaxAmmo("beretta_mp");
	self GiveMaxAmmo("usp_mp");
	self GiveMaxAmmo("colt44_mp");
	self GiveMaxAmmo("colt45_mp");
	self GiveMaxAmmo("deserteagle_mp");
	self GiveMaxAmmo("deserteaglegold_mp");
	self GiveMaxAmmo("m40a3_mp");
	self GiveMaxAmmo("remington700_mp");
	self iPrintln( "Ammo Refilled" );
}
ess_suicide()
{
	if( self.pers["team"] == "allies" )
	{
		self suicide();
		iPrintln("^1"+ self.name + "^7 commited suicide!");
	}
	else if( self.pers["team"] == "axis" )
		self iPrintln("^3Activators can not commit suicide!");
}

// DISABLE WEAPONS TO PREVENT SHOOTING AT ACTIVATOR -- Script by Gabriel //
playerSpawned()
{
    level waittill( "player_spawn", player );//this is there just to show the weapons disabled iprintln.
		
		if (player.pers["team"] == "allies" && level.freerun == true)
		{
			level waittill( "round_started" );
			player iprintln("^8Weapons ^3Enabled ^8During ^3Free run^8!");
		}
		if (player.pers["team"] == "allies" && level.freerun == false)//this is here so that the script doesnt bug out because it will be doing the same script to Spectators and Activators.
		{
			level waittill( "round_started" );//after the countdown
			player DisableWeapons();//Disables the Fucking weapons :dave:
			player iprintln("^8Weapons ^9Disabled");
			wait 1.8;
			player EnableWeapons();//Enables the fucking weapons :dave:
			player iprintln("^8Weapons ^3Enabled");//shows to the jumpers when the fucking weapons are enabled again :dave:
		}
}

// HITMARKER -- Script by Phaedrean //
PlayerDamage()
{
	for(;;)
	{
		level waittill( "player_damage", owned, attacker );
		if( isDefined(attacker) && isPlayer(attacker) && owned != attacker && isDefined(level.activ) && ( level.activ == owned || level.activ == attacker) )
			attacker Marker();
	}
}

Marker()
{
	self playlocalsound("MP_hit_alert");
	self.hud_damagefeedback.alpha = 1;
	self.hud_damagefeedback fadeOverTime(1);
	self.hud_damagefeedback.alpha = 0;
}

// TOMAHAWK -- Scripts by Rycoon //
tomahawk_init()
{
	addDvar( "pi_tt", "plugin_tomahawk_enable", 1, 0, 1, "int" );
	addDvar( "pi_tt_acti_a", "plugin_tomahawk_activator_amount", 2, 0, 8, "int" );
	addDvar( "pi_tt_jumper", "plugin_tomahawk_jumper", 1, 0, 1, "int" );
	addDvar( "pi_tt_jumper_a", "plugin_tomahawk_jumper_amount", 2, 0, 8, "int" );
	addDvar( "pi_tt_dmg", "plugin_tomahawk_damage", 150, 10, 1000, "int" );
	addDvar( "pi_tt_empty", "plugin_tomahawk_empty", 1, 0, 1, "int" );
	addDvar( "pi_tt_emptygun", "plugin_tomahawk_emptygun", "knife", "", "", "string" );
	addDvar( "pi_tt_switch", "plugin_tomahawk_autoswitch", 1, 0, 1, "int" );
	addDvar( "pi_tt_collect", "plugin_tomahawk_collect", 1, 0, 1, "int" );
	addDvar( "pi_tt_last", "plugin_tomahawk_last", 20, 5, 120, "int" );
	
	if( !level.dvar["pi_tt"] )
		return;

	thread onJumper();
	thread onActivator();
	thread WatchTomahawkDamage();
}

onJumper()
{
	while(1)
	{
		level waittill( "jumper", jumper );
		jumper giveTomahawk();
	}
}

onActivator()
{
	level waittill( "activator", player );
	player giveTomahawk();
}

giveTomahawk()
{
	if( !isDefined( self ) || !isPlayer( self ) || !isAlive( self ) )
		return;
	
	if( self.pers["team"] == "allies" )
	{
		if( !level.dvar["pi_tt_jumper"] )
			return;
		
		if( !self hasWeapon( "tomahawk_mp" ) )
			self giveWeapon( "tomahawk_mp" );
		self setWeaponAmmoClip( "tomahawk_mp", int( level.dvar["pi_tt_jumper_a"] ) );
	}
	else
	{
		if( !self hasWeapon( "tomahawk_mp" ) )
			self giveWeapon( "tomahawk_mp" );
		self setWeaponAmmoClip( "tomahawk_mp", int( level.dvar["pi_tt_acti_a"] ) );
	}
	if( self hasWeapon( "tomahawk_mp" ) && level.dvar["pi_tt_empty"] )
		self thread RemoveTomahawk();
}

AddTomahawk( count )
{
	if( !isDefined( self ) || !isPlayer( self ) || !isAlive( self ) )
		return;
	
	if( !self hasWeapon( "tomahawk_mp" ) )
	{
		self giveWeapon( "tomahawk_mp" );
		self setWeaponAmmoClip( "tomahawk_mp", count );
	}
	else
		self setWeaponAmmoClip( "tomahawk_mp", self GetWeaponAmmoClip( "tomahawk_mp" )+count );
	
	if( level.dvar["pi_tt_empty"] )
		self thread RemoveTomahawk();
}

RemoveTomahawk()	//...when empty
{
	self notify( "remove_toma" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "remove_toma" );
	
	wait 0.1;
	
	while( self GetWeaponAmmoClip( "tomahawk_mp" ) > 0 )
	{
		self waittill( "grenade_fire", proj, weap );
		if( weap != "tomahawk_mp" )
			continue;
		proj thread TomahawkPickUp();
	}
	
	self DropItem( "tomahawk_mp" );
	if( !level.dvar["pi_tt_switch"] )
		return;
	
	weaps = self GetWeaponsList();
	for(i=0;i<weaps.size;i++)
	{
		if( WeaponType( weaps[i] ) == "bullet" || WeaponType( weaps[i] ) == "projectile" )
		{
			self SwitchToWeapon( weaps[i] );
			return;
		}
	}
	self iPrintln( "^1>> ^2No more weapons found you could switch to!" );
	if( isDefined( level.dvar["pi_tt_emptygun"] ) )
	{
		gun = strTok( level.dvar["pi_tt_emptygun"], ";" );
		gun = gun[RandomInt(gun.size)];
		self giveWeapon( gun+"_mp" );
		wait 0.05;
		self SwitchToWeapon( gun+"_mp" );
	}
}

TomahawkPickUp()
{
	self endon( "death" );
	
	wait 2;
	
	oldpos = self.origin;
	while(1)		//lets check if its still moving - would be pretty stupid if you could pick it up while it is in mid air xD
	{
		wait 0.25;
		if( oldpos == self.origin )
			break;
		oldpos = self.origin;
	}
	
	if( level.dvar["pi_tt_last"] < 2 )
	{
		self delete();
		return;
	}
	
	time = level.dvar["pi_tt_last"];
	players = getEntArray( "player", "classname" );
	self thread RemoveAfterTime( time );
	
	self.trig = spawn( "trigger_radius", self.origin, 0, 64, 128 );
	
	while(1)
	{
		self.trig waittill( "trigger", player );
		if( !player useButtonPressed() || player.doingBH || player GetWeaponAmmoClip( "tomahawk_mp" ) >= 8 )
			continue;
		player addTomahawk( 1 );
		player PlaySound( "grenade_pickup" );
		player iPrintln( "^1>> ^2You've picked up ^31 ^2tomahawk!" );
		self delete();
	}
}

RemoveAfterTime( time )
{
	if( !isDefined( time ) || !isDefined( self ) )
		return;
	wait time;
	if( isDefined( self.trig ) )
		self.trig delete();
	if( isDefined( self ) )
	{
		self notify( "death" );
		self delete();
	}
}

CreatePickupHud()
{
	if( isDefined( self.pickup_hud ) )
		return;
	
	self.pickup_hud = NewClientHudElem( self );
	self.pickup_hud.alignX = "center";
	self.pickup_hud.alignY = "middle";
	self.pickup_hud.horzalign = "center";
	self.pickup_hud.vertalign = "middle";
	self.pickup_hud.alpha = 0.75;
	self.pickup_hud.x = 0;
	self.pickup_hud.y = 60;
	self.pickup_hud.font = "default";
	self.pickup_hud.fontscale = 1.6;
	self.pickup_hud.glowalpha = 1;
	self.pickup_hud.glowcolor = (1,0,0);
	self.pickup_hud setText( "^1>> ^2Press ^1[{+activate}] ^2to pick up tomahawk!" );
}

WatchTomahawkDamage()
{
	while(1)
	{
		level waittill( "player_damage", victim, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
		if( sWeapon != "tomahawk_mp" || sMeansOfDeath == "MOD_MELEE" || sMeansOfDeath == "MOD_FALLING" || victim.pers["team"] == eAttacker.pers["team"] )
			continue;
		victim FinishPlayerDamage( eAttacker, eAttacker, int( (level.dvar["pi_tt_dmg"]-1) ), iDFlags, sMeansOfDeath, "tomahawk_mp", vPoint, vDir, sHitLoc, psOffsetTime );
		//iPrintln( int( (level.dvar["pi_tt_dmg"]-1) ) );
	}
}

// NO DOUBLE MUSIC - by BraXi //
no_double_music()
{
	level waittill( "round_ended" );
    ambientStop( 0 );
}

onIntermission()
{
    level waittill( "intermission" );
    ambientStop( 0 );
}

// GUID SPOOFING PREVENTION - by Duffman //
GUID_Spoofing()
{
	while( 1 )
	{
		level waittill( "connected", player );
		player thread GuidCheck();
	}
}

GuidCheck()
{
    self endon( "disconnect" );
    
    while(1)
    {
        guid = self getGuid();
        isInvalid = false;
        
        // 1. Basic empty/zero check
        if( !isDefined(guid) || guid == "" || guid == "0" )
            isInvalid = true;

        // 2. Updated for your specific environment:
        // CoD4X SteamIDs are 17, but your internal IDs are 19.
        // We will allow anything between 17 and 20 characters.
        if( guid.size < 17 || guid.size > 20 )
            isInvalid = true;

        // 3. Ensure it only contains numbers
        for(i = 0; i < guid.size; i++)
        {
            char = GetSubStr(guid, i, i+1);
            if( !isSubStr("0123456789", char) )
            {
                isInvalid = true;
                break;
            }
        }

        if( isInvalid )
        {
            logPrint("GUID SPOOFER;" + guid + ";" + self getEntityNumber() + ";" + self.name + "\n");
            // Only print this to console for now to be safe
            printLn("GUID CHECK FAILED: " + self.name + " | GUID: " + guid + " | Size: " + guid.size);
            
            // Uncomment below if you want to warn/kick
            // self iPrintlnBold("^1Invalid GUID format detected!");
            // wait 2;
            // Kick( self getEntityNumber() ); 
            return; 
        }

        wait 20; 
    }
}

isRealGuid(guid)
{
	chars = [];
	for(i=0;i<16;i++)
		chars[i] = 0;
	
	for(i=0;i<32;i++)
	{
		char = GetSubStr(guid, i, i+1);
		if(char == "a")
			chars[0]++;
		else if(char == "b")
			chars[1]++;
		else if(char == "c")
			chars[2]++;	
		else if(char == "d")
			chars[3]++;	
		else if(char == "e")
			chars[4]++;	
		else if(char == "f")
			chars[5]++;	
		else if(char == "0")
			chars[6]++;	
		else if(char == "1")
			chars[7]++;	
		else if(char == "2")
			chars[8]++;	
		else if(char == "3")
			chars[9]++;	
		else if(char == "4")
			chars[10]++;	
		else if(char == "5")
			chars[11]++;
		else if(char == "6")
			chars[12]++;
		else if(char == "7")
			chars[13]++;
		else if(char == "8")
			chars[14]++;
		else if(char == "9")
			chars[15]++;
	}
	
	for(i=0;i<16;i++)
		if(chars[i] >= 12)
			return false;
	
	return true;
}


isHex(value)
{
	if(value == "a" || value == "b" || value == "c" || value == "d" || value == "e" || value == "f" || value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7" || value == "8" || value == "9")
		return true;
	else
		return false;
}

// PARTYMODE -- by Sinister //
partymode()
{
	level waittill( "endround" );
	thread partymode_events();
}

partymode_events()
{
 for(;;)
 { 
  SetExpFog(256, 900, 1, 0, 0, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0, 1, 0, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 0, 1, 0.1); 
  wait .5; 
        SetExpFog(256, 900, 0.4, 1, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.8, 0, 0.6, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 1, 0.6, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 1, 1, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 0, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.2, 1, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.4, 0.4, 1, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 0, 0, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.4, 0.2, 0.2, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.4, 1, 1, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0.6, 0, 0.4, 0.1); 
       wait .5; 
        SetExpFog(256, 900, 1, 0, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 1, 0, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.6, 1, 0.6, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 0, 0, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 1, 0, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0, 0, 1, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.4, 1, 0.8, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0.8, 0, 0.6, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 1, 0.6, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 1, 1, 1, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 0, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.2, 1, 0.8, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0.4, 0.4, 1, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0, 0, 0, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0.4, 0.2, 0.2, 0.1); 
       wait .5; 
        SetExpFog(256, 900, 0.4, 1, 1, 0.1); 
        wait .5; 
        SetExpFog(256, 900, 0.6, 0, 0.4, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 0, 0.8, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 1, 1, 0, 0.1); 
         wait .5; 
        SetExpFog(256, 900, 0.6, 1, 0.6, 0.1); 
 }
}

// HEALTHBAR -- by Bear //
healthbar()
{
	while( 1 )
    {
        level waittill( "connected", player );
        player thread numerical_health();
    }
}

numerical_health()
{
    self endon( "disconnect" );

    while( !isPlayer( self ) || !isAlive( self ) )
        wait( 0.05 );

    self.hp = newClientHudElem( self );
    self.hp.alignX = "left";
    self.hp.alignY = "bottom";
    self.hp.horzAlign = "left";
    self.hp.vertAlign = "bottom";
    self.hp.x = 8;
    self.hp.y = -38;
    self.hp.font = "objective";
    self.hp.fontScale = 1.8;
    self.hp.color = ( 1, 1, 1 );
    self.hp.alpha = 1;
    self.hp.glowColor = ( 0, 1, 0 );
    self.hp.glowAlpha = 1;
    self.hp.label     = &"Health: &&1";
    self.hp.hideWhenInMenu = true;

    while( self.health > 0 )
    {
        self.hp setValue( self.health );
        self.hp.glowColor = ( 1 - ( self.health / self.maxhealth ), self.health / self.maxhealth, 0 );
        wait( 0.05 );
    }

    if( isDefined( self.hp ) )
        self.hp destroy();

    self thread numerical_health();
}

// KILLCAM -- by Phaedrean //
killcam_init()
{
	addDvar( "pi_kc", "plugin_killcam_enable", 1, 0, 1, "int" );
	addDvar( "pi_kc_show", "plugin_killcam_show", 2, 0, 2, "int" );
	addDvar( "pi_kc_tp", "plugin_killcam_thirdperson", 1, 0, 1, "int" );
	addDvar( "pi_kc_blur", "plugin_killcam_blur", 0, 0, 5.0, "float" );
	//0 = When Jumper killed Acti
	//1 = When Activator killed jumper
	//2 = Every Kill
	if( !level.dvar["pi_kc"] || game["roundsplayed"] >= level.dvar[ "round_limit" ] )
		return;
	
	setArchive( true );
	self thread WatchForKillcam();
}

WatchForKillcam()
{
	if( game["roundsplayed"] >= level.dvar[ "round_limit" ] || level.freeRun )
		return;
	
	while(1)
	{
		level waittill( "player_killed", who, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );
		if( !isDefined( who ) || !isDefined( attacker ) || !isDefined( eInflictor ) || !isPlayer( who ) || !isPlayer( attacker ) || who == attacker )
			continue;
		if( sMeansOfDeath == "MOD_FALLING" )
			continue;
		if( GetTeamPlayersAlive( "axis" ) > 0 && GetTeamPlayersAlive( "allies" ) > 0 )
			continue;
		if( ( level.dvar["pi_kc_show"] == 0 && ( isDefined( level.activ ) && who == level.activ ) && attacker.pers["team"] == "allies" ) || ( level.dvar["pi_kc_show"] == 1 && who.pers["team"] == "allies" && ( isDefined( level.activ ) && level.activ == attacker ) ) || level.dvar["pi_kc_show"] == 2 )
		{
			thread StartKillcam( attacker, sWeapon );
			return;
		}
	}
}

StartKillcam( attacker, sWeapon )
{
	wait 2;
	players = getEntArray( "player", "classname" );
	for(i=0;i<players.size;i++)
	{
		players[i] setClientDvars( "cg_thirdperson", int( level.dvar["pi_kc_tp"] ), "r_blur", level.dvar["pi_kc_blur"] );
		players[i] thread killcam( attacker GetEntityNumber(), -1, sWeapon, 0, 0, 0, 8, undefined, attacker );
	}
}

killcam(
	attackerNum, // entity number of the attacker
	killcamentity, // entity number of the attacker's killer entity aka helicopter or airstrike
	sWeapon, // killing weapon
	predelay, // time between player death and beginning of killcam
	offsetTime, // something to do with how far back in time the killer was seeing the world when he made the kill; latency related, sorta
	respawn, // will the player be allowed to respawn after the killcam?
	maxtime, // time remaining until map ends; the killcam will never last longer than this. undefined = no limit
	perks, // the perks the attacker had at the time of the kill
	attacker // entity object of attacker
)
{
	// monitors killcam and hides HUD elements during killcam session
	//if ( !level.splitscreen )
	//	self thread killcam_HUD_off();
	
	self endon("disconnect");
	self endon("spawned");
	level endon("game_ended");

	if(attackerNum < 0)
		return;

	camtime = 6.5;
	
	if (isdefined(maxtime)) {
		if (camtime > maxtime)
			camtime = maxtime;
		if (camtime < .05)
			camtime = .05;
	}
	
	// time after player death that killcam continues for
	if (getdvar("scr_killcam_posttime") == "")
		postdelay = 2;
	else {
		postdelay = getdvarfloat("scr_killcam_posttime");
		if (postdelay < 0.05)
			postdelay = 0.05;
	}

	killcamlength = camtime + postdelay;
	
	// don't let the killcam last past the end of the round.
	if (isdefined(maxtime) && killcamlength > maxtime)
	{
		// first trim postdelay down to a minimum of 1 second.
		// if that doesn't make it short enough, trim camtime down to a minimum of 1 second.
		// if that's still not short enough, cancel the killcam.
		if (maxtime < 2)
			return;

		if (maxtime - camtime >= 1) {
			// reduce postdelay so killcam ends at end of match
			postdelay = maxtime - camtime;
		}
		else {
			// distribute remaining time over postdelay and camtime
			postdelay = 1;
			camtime = maxtime - 1;
		}
		
		// recalc killcamlength
		killcamlength = camtime + postdelay;
	}

	killcamoffset = camtime + predelay;
	
	self notify ( "begin_killcam", getTime() );
	
	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.killcamentity = killcamentity;
	self.archivetime = killcamoffset;
	self.killcamlength = killcamlength;
	self.psoffsettime = offsetTime;

	// ignore spectate permissions
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	
	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if ( self.archivetime <= predelay ) // if we're not looking back in time far enough to even see the death, cancel
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.killcamentity = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		
		return;
	}
	self.killcam = true;
	
	self thread waitKillcamTime();

	self waittill("end_killcam");

	self endKillcam();

	self.sessionstate = "dead";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
}

waitKillcamTime()
{
	self endon("disconnect");
	self endon("end_killcam");

	wait 8;
	self notify("end_killcam");
}

endKillcam()
{
	self.killcam = undefined;
}

// ROLL THE DICE -- by Star & Darmuh //
rtd_init()
{
 
PreCacheItem("brick_blaster_mp");
PreCacheItem("saw_mp");
precacheitem("m16_mp");
PreCacheShellShock( "damage_mp" );
 
VisionSetNight( "mp_deathrun_long", 5 );
 
level.meteorfx = LoadFX( "fire/tank_fire_engine" );
level.expbullt = loadfx("explosions/grenadeExp_concrete_1");
level.flame = loadfx("fire/tank_fire_engine");
 
 
  for(;;)
  {
     
     level waittill("player_spawn",player);
        player SetClientDvar ( "nightVisionDisableEffects", "1" );
        self.frozen = 0;
        player.has_used_rtd = false;
        player thread credit();
  }
}
 
credit()
{
  level endon ( "endmap" );
  self endon("disconnect");
  self endon ( "death" );
  self endon("joined_spectators");
 
 
  level waittill( "round_started" );

  self iprintln( "^2R^7oll ^2t^7he ^2d^7ice active." );
}

rtd_activate()
{
	if(self.has_used_rtd == false)
	{
		currentweapon = self GetCurrentWeapon();
		self.has_used_rtd = true;
		wait 1.5;
		self iprintlnbold( "^7You have ^2rolled ^7the dice!" );
		self switchtoweapon( currentweapon );
		
		
		 if (self.pers["team"] == "axis" && self isReallyAlive())
		  {
		    self iprintlnbold( "^2Activators ^2can not ^1use ^7RTD." );  
		  }
		  else
		  {
		    self thread rtd();
		  }
	       
		level waittill ("round_ended");
	 
	 
		wait .1;
	}
	else
		self iprintlnbold("^4You have already used ^1RTD^7!");
}
 
drawInformation( start_offset, movetime, mult, text )
{
    start_offset *= mult;
    hud = new_ending_hud( "center", 0.1, start_offset, 60 );
    hud setText( text );
    hud moveOverTime( movetime );
    hud.x = 0;
    wait( movetime );
    wait( 3 );
    hud moveOverTime( movetime );
    hud.x = start_offset * -1;
 
    wait movetime;
    wait 5;
    hud destroy();
}
 
new_ending_hud( align, fade_in_time, x_off, y_off )
{
    hud = newHudElem();
    hud.foreground = true;
    hud.x = x_off;
    hud.y = y_off;
    hud.alignX = align;
    hud.alignY = "middle";
    hud.horzAlign = align;
    hud.vertAlign = "middle";
 
    hud.fontScale = 3;
 
    hud.color = (0.8, 1.0, 0.8);
    hud.font = "objective";
    hud.glowColor = (0.3, 0.6, 0.3);
    hud.glowAlpha = 1;
 
    hud.alpha = 0;
    hud fadeovertime( fade_in_time );
    hud.alpha = 1;
    hud.hidewheninmenu = true;
    hud.sort = 10;
    return hud;
}
 
rtd()
{
    self endon("disconnect");
    self endon ( "death" );
    self endon("joined_spectators");
    self endon("killed_player");
   
     x = RandomInt( 17 );
     
     if (x==1) //positive
     {
       
        self iprintlnbold( "^1Gratz!!^7!!, You got  ^1R700" );  
        self takeAllWeapons();
        self ClearPerks();
        self giveWeapon( "remington700_mp" );
        self GiveMaxAmmo( "remington700_mp" );
        self SwitchToWeapon( "remington700_mp" );
        iprintln( "^2" + self.name + " ^7got a ^3R700" );
       
     }
     
     else if (x==15) //positive
     {
       
        self iprintlnbold( "^1Gratz!!^7!!,^1Health ^4Boost" );  
        self.health = 200;
        iprintln( "^1" + self.name + " ^7has ^1extra ^7Health ^1!" );
     }
     
     else if (x==2) //negative
     {
       
        self iprintlnbold( "You are ^1HIGH^7 up in the clouds." );  
        self shellshock( "damage_mp", 15);
        self thread illusion_fx();
        iprintln( "^1" + self.name + " ^7is ^1higher than the clouds^7!" );
     }
     
     else if (x==3) //positive
     {
       
        self iprintlnbold( "^1You ^7Just ^3Got ^6A ^5LIFE^7." );  
        self braxi\_mod::giveLife();
       
       iprintln( "^2" + self.name + " ^7got a ^2Life^7!" );
     }
     
     else if (x==4) //negative
     {
     
        self iprintlnbold( "^1Better luck ^7Next- ^2Time^7." );  
        self endon( "disconnect" );
    self endon( "death" );
 
    self playSound( "wtf" );
   
    wait 0.8;
    playFx( level.fx["bombexplosion"], self.origin );
    iprintln( "^1" + self.name + " ^7spontaneously ^1exploded." );
    self suicide();
   
   
     }
     
     else if (x==5) //negative
     {
         
         self iprintlnbold ( "^7You are ^1DRUNK ^7for ^315 ^7Seconds." );
         self shellshock( "damage_mp", 15);
         iprintln( "^1" + self.name + " ^7is ^1DRUNK^7." );
       
     }
     
     else if (x==14) //positive
     {
        self endon("disconnect");
          self endon ( "death" );
          self endon("joined_spectators");
          self endon("killed_player");
       
        self iprintlnbold( "^1Gratz!!^7!!, You got a ^3GOLDEN ^7DEAGLE!" );  
        self takeAllWeapons();
        self ClearPerks();
        self giveWeapon( "deserteaglegold_mp" );
        self GiveMaxAmmo( "deserteaglegold_mp" );
        self SwitchToWeapon( "deserteaglegold_mp" );
        iprintln( "^2" + self.name + " ^7got a ^3GOLDEN ^7Deagle^7!" );
     }

	else if (x==11 && level.dvar["essentials_menu_points_enabled"] == 1) //positive
	{
		self.points = self getStat(3256);
		if( self.points < 236 )
		{
			self.points += 20;
			self setStat(3256,self.points);
			self thread ess_points_hud(self.points);

			self iprintlnbold( "^7You got ^220 Points!^7!!" );
			iprintln( "^2" + self.name + " ^7got ^220 Points^7!" );
		}
		else
		{
			self iprintlnbold( "^1You ^2get ^1nothing^7." );
			iprintln( "^1" + self.name + "^7 got ^1nothing." );
		}
	}
     
     else if (x==8) //negative
     {
     
          self iprintlnbold( "^7You are ^5Frozen^7 For ^313 ^7Seconds." );
          self FreezeControls(1);
          self.frozen = 1;
          iprintln( "^1" + self.name + " ^7is ^5Frozen^7!" );
          wait 13;
          self FreezeControls(0);
          self.frozen = 0;          
       
     }
     
     else if (x==9) //positive
     {
          self endon("disconnect");
          self endon ( "death" );
          self endon("joined_spectators");
          self endon("killed_player");
         
        self iprintlnbold( "Nice!! ^2You Got ^1Brick ^4Blaster^7!!!!" );
        self takeAllWeapons();
        self giveWeapon( "brick_blaster_mp" );
        self SwitchToWeapon( "brick_blaster_mp" );
        iprintln( "^2" + self.name + " ^7got a ^2Brick Blaster^7!" );
     }
     
     else if (x==17) //negitive
     {
          self endon("disconnect");
          self endon ( "death" );
          self endon("joined_spectators");
          self endon("killed_player");
         
        self iprintlnbold( "Nice!! ^2You Got ^1A....... ^4Briefcase^7????" );
        self takeAllWeapons();
        self giveWeapon( "briefcase_bomb_mp" );
        self SwitchToWeapon( "briefcase_bomb_mp" );
        iprintln( "^2" + self.name + " ^7got a ^2Briefcase^7?" );
     }
     
     else if (x==10) //negative
     {
      self takeAllWeapons();
      self iprintlnbold( "^1You ^2get ^1nothing^7." );
      self giveweapon( "knife_mp" );
      self SwitchToWeapon( "knife_mp" );
      iprintln( "^1" + self.name + "^7 got ^1nothing." );
     }
     
     else if (x==16) //positive
     {
        self iprintlnbold( "^1Boost ^3!!!" );
        self thread Speed();
        iprintln( "^1" + self.name + "^7is ^1Pumped ^7!!" );
     }
     
     else if (x==7) //negative
     {
      self iprintlnbold( "^7You're ^1too pro ^7for that weapon! Try ^2this^7 for a ^2challenge^7!" );
      self takeAllWeapons();
      self giveWeapon( "m16_mp" );
      self SwitchToWeapon( "m16_mp" );
      self SetWeaponAmmoClip( "m16_mp", 6 );
      self SetWeaponAmmoStock( "m16_mp", 0 );
      iprintln( "^1" + self.name + " ^7got a ^1broken ^7M16 with only ^12 bursts^7!" );
     }
     
     else if (x==12) //negative
     {
      self iprintlnbold( "^7You're ^1BURNING ^7alive!" );
      self thread flameon();
      self PlayLocalSound("last_alive");
      wait 2;
      self thread hurttodeath();
      wait 5;
      iprintln( "^1" + self.name + " ^7is on ^1FIRE^7!" );
     }
     
     else if (x==13) //negative
     {
      self iprintlnbold( "^7Sprint ^1Disabled." );
      self AllowSprint(false);
      self SayAll( "^3" + self.name + "^7@^1nosprint" );
      iprintln( "^1" + self.name + "'s ^7sprint has been ^1disabled^7." );
     }
     
     else if (x==6) //positive
     {
      self iprintlnbold( "^7You got ^3NUKE BULLETS^7!" );
      self thread killstreak3();
      iprintln( "^2" + self.name + " ^7got ^2NUKE BULLETS^7!" );
     }
     
     else //positive
     {
       self iprintlnbold( "^3Lucky one, ^7Enjoy your ^2500 ^1Xp." );  
       self braxi\_rank::giveRankXP( "", 500 );
       iprintln( "^2" + self.name + " ^7got ^3500^2xp^7!!" );
     }
}
 
killstreak3()
{
self endon("death");
while(1)
{
self waittill("weapon_fired");
my = self gettagorigin("j_head");
trace=bullettrace(my, my + anglestoforward(self getplayerangles())*100000,true,self)["position"];
playfx(level.expbullt,trace);
self playSound( "artillery_impact" );
dis=distance(self.origin, trace);
if(dis<101) RadiusDamage( trace, dis, 200, 50, self );
RadiusDamage( trace, 60, 250, 50, self );
RadiusDamage( trace, 100, 800, 50, self );
vec = anglestoforward(self getPlayerAngles());
end = (vec[0] * 200000, vec[1] * 200000, vec[2] * 200000);
SPLOSIONlocation = BulletTrace( self gettagorigin("tag_eye"), self gettagorigin("tag_eye")+end, 0, self)[ "position" ];
explode = loadfx( "fire/tank_fire_engine" );
playfx(explode, SPLOSIONlocation);
self thread DamageArea(SPLOSIONlocation,500,800,200,"artillery_mp",false);
}
}
 
DamageArea(Point,Radius,MaxDamage,MinDamage,Weapon,TeamKill)
{
KillMe = false;
Damage = MaxDamage;
for(i=0;i<level.players.size+1;i++){
DamageRadius = distance(Point,level.players[i].origin);
if(DamageRadius<Radius){
if(MinDamage<MaxDamage)
Damage = int(MinDamage+((MaxDamage-MinDamage)*(DamageRadius/Radius)));
if((level.players[i] != self) && ((TeamKill && level.teamBased) || ((self.pers["team"] != level.players[i].pers["team"]) && level.teamBased) || !level.teamBased))
level.players[i] FinishPlayerDamage(level.players[i],self,Damage,0,"MOD_PROJECTILE_SPLASH",Weapon,level.players[i].origin,level.players[i].origin,"none",0);
if(level.players[i] == self)
KillMe = true;
}
wait 0.01;
}
RadiusDamage(Point,Radius-(Radius*0.25),MaxDamage,MinDamage,self);
if(KillMe)
self FinishPlayerDamage(self,self,Damage,0,"MOD_PROJECTILE_SPLASH",Weapon,self.origin,self.origin,"none",0);
}
 
hurttodeath()
{
        self endon("disconnect");
          self endon ( "death" );
          self endon("joined_spectators");
          self endon("killed_player");
 
  for(;;)
   { //  FinishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
    self FinishPlayerDamage(self, self, 15, 0, "MOD_SUICIDE", "knife_mp", self.origin, self.angles, "none", 0);
    self PlayLocalSound("breathing_hurt");
    wait 1.4;
   }
}
   
 
illusion_fx()
{
    self endon("disconnect");
    self endon("joined_spectators");
    self endon("killed_player");
    self endon("death");
 
        while(1)
        {
        i = 0;
        angles = self GetPlayerAngles();
        angles1 = self GetPlayerAngles();
        while(i<17.2)
                {
                wait 0.06;
                 i+=0.06;
                angles+=(0,5,5);
                self SetPlayerAngles(angles);
                     }
        if(i>11.2)
        wait 0.06;
        self SetPlayerAngles(angles1);
            break;
 
}
}
 
 
burn()
{
    PlayFXOnTag( level.burn_fx, self, "head" );
    PlayFXOnTag( level.burn_fx, self, "neck" );
    PlayFXOnTag( level.burn_fx, self, "j_shoulder_le" );
    PlayFXOnTag( level.burn_fx, self, "j_spinelower" );
    PlayFXOnTag( level.burn_fx, self, "j_knee_ri" );
   
    for(i=0;i<5;i++)
    {
        self ShellShock("burn_mp", 2.5 );
        self PlayLocalSound("breathing_hurt");
        wait 1.4;
    }
    self suicide();
}
 
flameon()
{
 
          self endon("disconnect");
          self endon ( "death" );
          self endon("joined_spectators");
          self endon("killed_player");
 
    while( isAlive( self ) && isDefined( self ) )
    {
        playFx( level.meteorfx , self.origin );
        wait .1;
    }
}
 
hud()
{
 
    self.xxx = NewClientHudElem(self);    //hud visible for all, to make it only visible for one replace level. with self. and change newHudElem() to newClientHudElem(self)
    self.xxx.x = -20;    //position on the x-axis
    self.xxx.y = 75;    //position on the <-axis
    self.xxx.horzAlign = "right";    
    self.xxx.vertAlign = "middle";
    self.xxx.alignX = "right";
    self.xxx.alignY = "middle";
    self.xxx.sort = 102;    //if there are lots of huds you can tell them which is infront of which
    self.xxx.foreground = 1;    //to do with the one above, if it's in front a lower sorted hud
    self.xxx.archived = false;    //visible in killcam
    self.xxx.alpha = 1;    //transparency    0 = invicible, 1 = visible
    self.xxx.fontScale = 1.9;    //textsize
    self.xxx.hidewheninmenu = false;    //will it be visble when a player is in a menu
    self.xxx.color = (1,0,0);    //RGB color code
    self.xxx.label = &"^5Fuel: &&1 ^7/ ^2800";    //The text for the hud & is required, &&1 is the value which will be added below
   
    self.xx1 = NewClientHudElem(self);    //hud visible for all, to make it only visible for one replace level. with self. and change newHudElem() to newClientHudElem(self)
    self.xx1.x = -20;    //position on the x-axis
    self.xx1.y = 95;    //position on the <-axis
    self.xx1.horzAlign = "right";    
    self.xx1.vertAlign = "middle";
    self.xx1.alignX = "right";
    self.xx1.alignY = "middle";
    self.xx1.sort = 102;    //if there are lots of huds you can tell them which is infront of which
    self.xx1.foreground = 1;    //to do with the one above, if it's in front a lower sorted hud
    self.xx1.archived = false;    //visible in killcam
    self.xx1.alpha = 1;    //transparency    0 = invicible, 1 = visible
    self.xx1.fontScale = 1.9;    //textsize
    self.xx1.hidewheninmenu = false;    //will it be visble when a player is in a menu
    self.xx1.color = (1,0,0);    //RGB color code
    self.xx1.label = &"^2Knife^1 to Raise";    //The text for the hud & is required, &&1 is the value which will be added below
   
    self.xx2 = NewClientHudElem(self);    //hud visible for all, to make it only visible for one replace level. with self. and change newHudElem() to newClientHudElem(self)
    self.xx2.x = -20;    //position on the x-axis
    self.xx2.y = 115;    //position on the <-axis
    self.xx2.horzAlign = "right";    
    self.xx2.vertAlign = "middle";
    self.xx2.alignX = "right";
    self.xx2.alignY = "middle";
    self.xx2.sort = 102;    //if there are lots of huds you can tell them which is infront of which
    self.xx2.foreground = 1;    //to do with the one above, if it's in front a lower sorted hud
    self.xx2.archived = false;    //visible in killcam
    self.xx2.alpha = 1;    //transparency    0 = invicible, 1 = visible
    self.xx2.fontScale = 1.9;    //textsize
    self.xx2.hidewheninmenu = false;    //will it be visble when a player is in a menu
    self.xx2.color = (1,0,0);    //RGB color code
    self.xx2.label = &"^2Fire^1 to go Forward";    //The text for the hud & is required, &&1 is the value which will be added below
   
    self.xx3 = NewClientHudElem(self);    //hud visible for all, to make it only visible for one replace level. with self. and change newHudElem() to newClientHudElem(self)
    self.xx3.x = -20;    //position on the x-axis
    self.xx3.y = 135;    //position on the <-axis
    self.xx3.horzAlign = "right";    
    self.xx3.vertAlign = "middle";
    self.xx3.alignX = "right";
    self.xx3.alignY = "middle";
    self.xx3.sort = 102;    //if there are lots of huds you can tell them which is infront of which
    self.xx3.foreground = 1;    //to do with the one above, if it's in front a lower sorted hud
    self.xx3.archived = false;    //visible in killcam
    self.xx3.alpha = 1;    //transparency    0 = invicible, 1 = visible
    self.xx3.fontScale = 1.9;    //textsize
    self.xx3.hidewheninmenu = false;    //will it be visble when a player is in a menu
    self.xx3.color = (1,0,0);    //RGB color code
    self.xx3.label = &"^2Grenade^1 to detach";    //The text for the hud & is required, &&1 is the value which will be added below
 
    self thread monitorhud();
    while(1)
    {
    wait 1;
            if(self.fuel>500)
            {
            self.xxx setValue("^2" +self.fuel);    //if level.count is a integer
            self.xxx setText("^2" +self.fuel);    //if level.count is a string
            }
            if(self.fuel>200 && self.fuel<500)
            {
            self.xxx setValue("^3" +self.fuel);    //if level.count is a integer
            self.xxx setText("^3" +self.fuel);    //if level.count is a string
            }
            if(self.fuel<200)
            {
            self.xxx setValue("^1" +self.fuel);    //if level.count is a integer
            self.xxx setText("^1" +self.fuel);    //if level.count is a string
            }
        }
    }
   
monitorhud()
{
self endon("round_end");
self endon("disconnect");
self.monitorhud=true;
while(self.monitorhud==true)
{
    if( self isReallyAlive())
    {
    }
    else
            {    
            self.xxx Destroy();
            self.xx1 Destroy();
            self.xx2 Destroy();
            self.xx3 Destroy();
            self.monitorhud=false;
            }
    wait 0.05;
}
}
 
showCredit( text, scale, alap )
{
 
if ( alap == 1 )
{
    hud = rtd_addTextHud( self, 320, 60, 0, "center", "top", scale );
}
else if( alap == 2 )
{
    hud = rtd_addTextHud( self, 320, 95, 0, "center", "top", scale );
}
else if( alap == 3 )
{
    hud = rtd_addTextHud( self, 320, 130, 0, "center", "top", scale );
}
else if( alap == 4 )
{
    hud = rtd_addTextHud( self, 320, 165, 0, "center", "top", scale );
}
else if( alap == 5 )
{
    hud = rtd_addTextHud( self, 320, 200, 0, "center", "top", scale );
}
else if( alap == 6 )
{
    hud = rtd_addTextHud( self, 320, 235, 0, "center", "top", scale );
}
else if( alap == 7 )
{
    hud = rtd_addTextHud( self, 320, 270, 0, "center", "top", scale );
}
else if( alap == 8 )
{
    hud = rtd_addTextHud( self, 320, 305, 0, "center", "top", scale );
}
else if( alap == 9 )
{
    hud = rtd_addTextHud( self, 320, 340, 0, "center", "top", scale );
}
else if( alap == 10 )
{
    hud = rtd_addTextHud( self, 320, 375, 0, "center", "top", scale );
}
else
{
    hud = rtd_addTextHud( self, 320, 60, 0, "center", "top", scale );
}
 
 
    hud setText( text );
 
    hud.glowColor = (0.7,0,0);
    hud.glowAlpha = 1;
    hud SetPulseFX( 30, 100000, 700 );
 
    hud fadeOverTime( 0.5 );
    hud.alpha = 1;
 
    wait 2.6;
 
    hud fadeOverTime( 0.4 );
    hud.alpha = 0;
    wait 0.4;
 
    hud destroy();
}
 
rtd_addTextHud( who, x, y, alpha, alignX, alignY, fontScale )
{
    hud = newClientHudElem(self);
 
    hud.x = x;
    hud.y = y;
    hud.alpha = alpha;
    hud.alignX = alignX;
    hud.alignY = alignY;
    hud.fontScale = fontScale;
    return hud;
}
 
Speed()
{
    self endon("disconnect");
   
    self SetMoveSpeedScale(1.4);
    self setClientDvar("g_gravity", 70 );
   
    while(isDefined(self) && self.sessionstate == "playing" && game["state"] != "round ended")
    {
        if(!self isOnGround() && !self.doingBH)
        {
            while(!self isOnGround())
                wait 0.05;
               
            playfx(level.fx[2], self.origin - (0, 0, 10));
            earthquake (0.3, 1, self.origin, 100);
        }
        wait .2;
    }
   
    if(isDefined(self))
    {
        self setClientDvar("g_gravity", 70 );
        self SetMoveSpeedScale(1);
    }
}

// ANTI WALLBANG -- by Viking //

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(isDefined(eAttacker) && isPlayer(eAttacker))
	{
		if(!SightTracePassed( eAttacker Geteye(), self.origin + (0, 0, getHitLocHeight(sHitloc)), false, undefined))
			return;
	}
	
	self braxi\_mod::PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

// ANTI AFK ACTIVATOR -- by Darmuh //
anti_afk_acti_init()
{
	addDvar( "antiafkacti", "antiafk_enable", 1, 0, 1, "int" );
	if( !level.dvar["antiafkacti"] )
		return;

	addDvar( "aa_traps", "antiafk_traps", 0, 0, 1, "int" );
	addDvar( "aa_warn", "antiafk_warn", 10, 3, 60, "int" );
	addDvar( "aa_time", "antiafk_time", 15, 5, 120, "int" );
	addDvar( "aa_team", "antiafk_team", 0, 0, 1, "int" );
	addDvar( "aa_trapdelay", "antiafk_trapdelay", 5, 1, 60, "int" );
	addDvar( "aa_teltotraps", "antiafk_teleporttotraps", 0, 0, 1, "int" );
	addDvar( "aa_wmsg", "antiafk_wmessage", "Please move your ass!", "", "", "string" );
	while(1)
	{
		level waittill( "activator", guy );
		thread finmapcheck();
		guy thread TrapActivation();
	}
}

NoTelMap()
{
return isSubStr( "godfather caelum long bigfall iwillrockyou sewers jurapark factory diehard azteca cherry backlot cosmic dragonball flow highrise disco darmuhv2 watercity sm_v2 ruin2", braxi\_maps::getMapNameString( level.mapName ) );
}

newacti()
{
	level notify( "picking activator" );
	level endon( "picking activator" );
	
	players = getAllPlayers();
	if( !isDefined( players ) || isDefined( players ) && !players.size || players.size <= 2 )
		return;

	num = randomInt( players.size );
	guy = players[num];

	if( level.dvar["dont_make_peoples_angry"] == 1 && guy getEntityNumber() == getDvarInt( "last_picked_player" ) )
	{	
		if( isDefined( players[num-1] ) && isPlayer( players[num-1] ) )
			guy = players[num-1];
		else if( isDefined( players[num+1] ) && isPlayer( players[num+1] ) )
			guy = players[num+1];
	}
	
	if( !isDefined( guy ) && !isPlayer( guy ) || level.dvar["dont_pick_spec"] && guy.sessionstate == "spectator"  || !guy isReallyAlive() )
	{
		level thread newacti();
		return;
	}
	
	bxLogPrint( ("A: " + guy.name + " ; guid: " + guy.guid) );
	iPrintlnBold( guy.name + "^2 was picked to be the new ^1Activator^2!" );
		
	guy thread braxi\_teams::setTeam( "axis" );
	guy braxi\_mod::spawnPlayer();
	guy braxi\_rank::giveRankXp( "activator" );
		
	setDvar( "last_picked_player", guy getEntityNumber() );
	level notify( "activator", guy );
	level.activ = guy;
	wait 0.1;
}

finmapcheck()
{
	trig = getent("endmap_trig", "targetname");

	trig waittill ( "trigger", player );
	level notify( "mapfin" );
}

TrapActivation()
{
	level endon( "newactivator" );
	level endon( "intermission" );
	level endon( "game over" );
	level endon( "mapfin" );
	level endon( "endround" );
	self endon( "disconnect" );
	self endon( "trapsdone" );
	self endon( "death" );
	

	if( !isDefined( self ) || !isPlayer( self ) || !isAlive( self ) )
		return;

	if (level.jumpers <= 2 )
			return;	
	self checkAFK();

	if( level.dvar["aa_traps"] == 1 )
		{
			if(  level.trapsDisabled || !isDefined( level.trapTriggers ) || !level.trapTriggers.size )
			{
				if (level.jumpers < 2)
					return;
				iprintlnbold( "^1>> ^2Picking new Activator due to inactivity (AFK)!" );
				thread newacti();
				if( isAlive( self ) )
					self suicide();
				level.activators = 0;
				level.activatorKilled = false;
				level.activ = undefined;
				team = "allies";
				if( getdvarInt("aa_team") == 1 )
					team = "spectator";
				self.pers["team"] = team;
				self.team = team;
				self.sessionteam = team;
				self braxi\_mod::spawnSpectator( level.spawn["spectator"].origin, level.spawn["spectator"].angles );
				level notify( "newactivator" );
				return;
			}

			if( !isDefined( self ) || !isPlayer( self ) || !isAlive( self ) )
				return;
				
			iprintlnbold( "^7Server now activating for Activator(AFK)!" );
			for(i=0;i<level.trapTriggers.size;i++)
			{
				if( !isDefined( self ) || !isAlive( self ) )
					return;

				if( !isDefined( level.trapTriggers[i] ) )
					continue;

				origin = level.trapTriggers[i].origin;
				pos = PlayerPhysicsTrace( origin+(0,0,100), origin-(0,0,40) );
				level.trapTriggers[i] UseBy( self );
				self iPrintln( "Trap #" + (i+1) );
				if( getdvarInt("aa_teltotraps") == 0  || NoTelMap() )
				{
					oldang = self.angles;
					oldpos = self.origin;
					wait level.dvar["aa_trapdelay"];
					if( oldpos != self.origin || oldang != self.angles)
					{
						iPrintlnbold( "Activator is back!" );
						return;
					}
				}
				else
				{
					self setOrigin( pos );
					wait 0.25;
					oldang = self.angles;
					oldpos = self.origin;			
					wait level.dvar["aa_trapdelay"];
					if( oldpos != self.origin || oldang != self.angles )
					{
						iPrintlnbold( "Activator is back!" );
						return;
					}
				}
			}
			iPrintlnbold( "End of trap activation!" );

		}
	else if( level.dvar["aa_traps"] == 0 )
		{
			if (level.jumpers < 2)
					return;
				iprintlnbold( "^1>> ^2Picking new Activator due to inactivity (AFK)!" );
				thread newacti();
				if( isAlive( self ) )
					self suicide();
				level.activators = 0;
				level.activatorKilled = false;
				level.activ = undefined;
				team = "allies";
				if( getdvarInt("aa_team") == 1 )
					team = "spectator";
				self.pers["team"] = team;
				self.team = team;
				self.sessionteam = team;
				self braxi\_mod::spawnSpectator( level.spawn["spectator"].origin, level.spawn["spectator"].angles );
				level notify( "newactivator" );
				return;
		}
	else
		{
			if(  level.trapsDisabled || !isDefined( level.trapTriggers ) || !level.trapTriggers.size )
			{
				if (level.jumpers < 2)
					return;
				iprintlnbold( "^1>> ^2Picking new Activator due to inactivity (AFK)!" );
				thread newacti();
				if( isAlive( self ) )
					self suicide();
				level.activators = 0;
				level.activatorKilled = false;
				level.activ = undefined;
				team = "allies";
				if( getdvarInt("aa_team") == 1 )
					team = "spectator";
				self.pers["team"] = team;
				self.team = team;
				self.sessionteam = team;
				self braxi\_mod::spawnSpectator( level.spawn["spectator"].origin, level.spawn["spectator"].angles );
				level notify( "newactivator" );
				return;
			}

			if( !isDefined( self ) || !isPlayer( self ) || !isAlive( self ) )
				return;
				
			iprintlnbold( "^7Server now activating for Activator(AFK)!" );
			for(i=0;i<level.trapTriggers.size;i++)
			{
				if( !isDefined( self ) || !isAlive( self ) )
					return;

				if( !isDefined( level.trapTriggers[i] ) )
					continue;

				origin = level.trapTriggers[i].origin;
				pos = PlayerPhysicsTrace( origin+(0,0,100), origin-(0,0,40) );
				level.trapTriggers[i] UseBy( self );
				self iPrintln( "Trap #" + (i+1) );
				if( getdvarInt("aa_teltotraps") == 0  || NoTelMap() )
				{
					oldang = self.angles;
					oldpos = self.origin;
					wait level.dvar["aa_trapdelay"];
					if( oldpos != self.origin || oldang != self.angles)
					{
						iPrintlnbold( "Activator is back!" );
						return;
					}
				}
				else
				{
					self setOrigin( pos );
					wait 0.25;
					oldang = self.angles;
					oldpos = self.origin;			
					wait level.dvar["aa_trapdelay"];
					if( oldpos != self.origin || oldang != self.angles )
					{
						iPrintlnbold( "Activator is back!" );
						return;
					}
				}
			}
			iPrintlnbold( "End of trap activation!" );

		}
}

checkAFK()
{
	self endon( "disconnect" );
	self endon( "death" );

	wmessage = (level.dvar["aa_wmsg"]);
	oldpos = self.origin;
	oldang = self.angles;
	time = 0;

	while(1)
	{
		wait 1;
		if( Distance( self.origin, oldpos ) < 10 && self.angles == oldang )
		{
			time++;
			if( time == level.dvar["aa_time"] )
				return;
			else if( time == level.dvar["aa_warn"] )
				self iPrintlnBold( wmessage );
		}
		else
		{
			oldpos = self.origin;
			oldang = self.angles;
			time = 0;
		}
	}
}