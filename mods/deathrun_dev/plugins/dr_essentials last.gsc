//--------------------------------------------------
//  Deathrun Essentials (Extended)
//  Original: GCZ|Slaya (JR-Imagine)
//  Extended with role-based menus
//  Roles: Owner > Co-Owner > Admin > VIP > Player
//--------------------------------------------------

#include maps\mp\gametypes\_hud_util;
#include braxi\_dvar;
#include braxi\_common;

init( modVersion )
{
	level endon ("map_restart");

	addDvar( "essentials_menu_enabled", "plugin_essentials_menu_enable", 1, 0, 1, "int" );
	addDvar( "essentials_menu_points_max", "plugin_essentials_menu_points_max", 256, 0, 256, "int" );
	addDvar( "healthbar_enabled", "plugin_healthbar_enable", 1, 0, 1, "int" );
	addDvar( "guid_spoof_enabled", "plugin_guid_spoofing_enable", 1, 0, 1, "int" );
	addDvar( "no_double_music", "plugin_no_double_music", 1, 0, 1, "int" );
	addDvar( "disco_enabled", "plugin_disco_enable", 1, 0, 1, "int" );
	addDvar( "rtd_enabled", "plugin_rtd_enable", 1, 0, 1, "int" );
	addDvar( "antiwallbang_enabled", "plugin_antiwallbang_enable", 1, 0, 1, "int" );

	if( level.dvar["essentials_menu_enabled"] == 1 )
		EssentialsMenu_init();

	thread playerSpawned();
	level thread PlayerDamage();
	thread tomahawk_init();
	thread killcam_init();
	thread anti_afk_acti_init();

	if( level.dvar["healthbar_enabled"] == 1 )
	thread healthbar();

	if( level.dvar["guid_spoof_enabled"] == 0 )
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

//=============================================================================
// ROLE SYSTEM
// Add GUIDs (last 8 hex digits) below for each role.
// Owner > Co-Owner > Admin > VIP
//=============================================================================
EssentialsMenu_init()
{
	level.menubutton = "P";

	// ---------- DEFINE ROLES HERE ----------
	// Use the last 8 characters of the player's GUID.
	// Example: if GUID is "76561198012345678", use "12345678"

	// -------------------------------------------------------
	// GUID ROLE LISTS - edit these directly.
	// Use only the last 8 characters of each player's GUID.
	// Separate multiple GUIDs with a comma (see examples).
	// The debug line in console prints the full GUID on connect
	// so you can confirm the correct suffix.
	// -------------------------------------------------------

	// OWNERS
	level.role_owners    = [];
	level.role_owners[0] = "84832824";	
	// level.role_owners[1] = "OWNER002";	

	// CO-OWNERS
	level.role_coowners    = [];
	level.role_coowners[0] = "79750408";

	// ADMINS
	level.role_admins    = [];
	// level.role_admins[0] = "ADMIN001";

	// VIPS
	level.role_vips      = [];
	// level.role_vips[0] = "VIP00001";
	

	// ---------- POINTS / WEAPON BUY SYSTEM ----------
	addDvar( "essentials_menu_points_enabled", "plugin_essentials_menu_points_enable", 1, 0, 1, "int" );
	addDvar( "price_m9",         "plugin_price_m9",         20, 1, 32569, "int" );
	addDvar( "price_m1911",      "plugin_price_m1911",      25, 1, 32569, "int" );
	addDvar( "price_usp",        "plugin_price_usp",        25, 1, 32569, "int" );
	addDvar( "price_deagle",     "plugin_price_deagle",     30, 1, 32569, "int" );
	addDvar( "price_gold_deagle","plugin_price_gold_deagle",30, 1, 32569, "int" );
	addDvar( "price_colt44",     "plugin_price_colt44",     30, 1, 32569, "int" );
	addDvar( "price_m40a3",      "plugin_price_m40a3",      30, 1, 32569, "int" );
	addDvar( "price_r700",       "plugin_price_r700",       30, 1, 32569, "int" );

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

	// ---------- PRECACHE ----------
	shaders = strTok("ui_host;line_vertical;nightvision_overlay_goggles;hud_arrow_left",";");
	for(i=0;i<shaders.size;i++) precacheShader(shaders[i]);

	precacheModel("body_mp_usmc_cqb");
	precacheModel("body_mp_sas_urban_sniper");
	precacheModel("body_zoey");
	precacheModel("body_shepherd");
	precacheModel("body_juggernaut");
	precacheModel("body_masterchief");
	precacheModel("body_makarov");
	precacheModel("body_complete_mp_russian_farmer");
	precacheModel("body_complete_mp_zakhaev");
	precacheModel("body_complete_mp_velinda_desert");
	precacheModel("body_complete_mp_al_asad");
	precacheItem("remington700_acog_mp");
	precacheItem("mp5_silencer_mp");
	precacheItem("rpg_mp");
	precacheItem("barrett_acog_mp");
	precacheItem("ak47_acog_mp");
	precacheItem("brick_blaster_mp");
	precacheItem("saw_acog_mp");
	precacheItem("m40a3_mp");

	thread ess_onPlayerConnected();
	thread ess_onPlaySpawned();
}


getPlayerRole( player )
{
    fullGuid = player getGuid();
    
    // If the GUID is 8 characters or less, use the whole thing 
    if( fullGuid.size <= 8 )
        guid8 = fullGuid;
    else
        guid8 = getSubStr( fullGuid, fullGuid.size - 8 );

    // Check each array for the suffix [cite: 28, 29]
    for(i=0; i<level.role_owners.size; i++)
        if(level.role_owners[i] == guid8) return "owner";
    for(i=0; i<level.role_coowners.size; i++)
        if(level.role_coowners[i] == guid8) return "coowner";
    for(i=0; i<level.role_admins.size; i++)
        if(level.role_admins[i] == guid8) return "admin";
    for(i=0; i<level.role_vips.size; i++)
        if(level.role_vips[i] == guid8) return "vip";

    return "player";
}

getRoleLabel( role )
{
	if(role == "owner")   return "^1[Owner]";
	if(role == "coowner") return "^4[Co-Owner]";
	if(role == "admin")   return "^3[Admin]";
	if(role == "vip")     return "^5[VIP]";
	return "^7[Player]";
}

roleAtLeast( role, minimum )
{
	order = [];
	order[0] = "player";
	order[1] = "vip";
	order[2] = "admin";
	order[3] = "coowner";
	order[4] = "owner";

	roleVal = 0;
	minVal  = 0;
	for(i=0;i<5;i++)
	{
		if(order[i] == role)    roleVal = i;
		if(order[i] == minimum) minVal  = i;
	}
	return (roleVal >= minVal);
}

//=============================================================================
// PLAYER CONNECTED / SPAWNED HOOKS
//=============================================================================
ess_onPlayerConnected()
{
	for(;;)
	{
		level waittill("connected",player);
		// iPrintln("^1DEBUG: ^7Full GUID: " + player getGuid());
        // iPrintln("^1DEBUG: ^7Role Detected: " + getPlayerRole(player));
		player.inessentials_menu = false;
		player.frozen = 0;
		player.ess_role = getPlayerRole(player);
		player.promod = false;
		player.tpg = false;
		player.DM = false;

		player setClientDvar("r_fullbright",(player getStat(714)));
		player setClientDvar("cg_laserForceOn",(player getStat(3254)));

		player.scale = player getStat(3255);
		if(player.scale == 2)      player setClientDvar("cg_fovscale",1.05);
		else if(player.scale == 3) player setClientDvar("cg_fovscale",1.1);
		else if(player.scale == 4) player setClientDvar("cg_fovscale",1.15);
		else if(player.scale == 5) player setClientDvar("cg_fovscale",1.2);
		else if(player.scale == 6) player setClientDvar("cg_fovscale",1.25);
		else if(player.scale == 7) player setClientDvar("cg_fovscale",1.3);
		else if(player.scale == 8) player setClientDvar("cg_fovscale",1.4); // Add this line
		else                       player setClientDvar("cg_fovscale",1);

		player braxi\_common::clientCmd("bind "+level.menubutton+" openscriptmenu y essentials_menu");
		player thread OnMenuResponse();

		// Greet privileged players
		if(player.ess_role != "player")
		{
			if(!isDefined(player.pers["ess_welcomed"]))
			{
				player.pers["ess_welcomed"] = true;
				iPrintln("^3Welcome ^7"+getRoleLabel(player.ess_role)+" ^5"+player.name+"^7 to the server!");
			}
		}

		// Give VIP+ extra lives at start
		if(roleAtLeast(player.ess_role,"vip"))
			player thread ess_vip_lives();
	}
}

ess_onPlaySpawned()
{
	for(;;)
	{
		level waittill("player_spawn",player);
		player iPrintln("Press ^3"+level.menubutton+"^7 to open "+getRoleLabel(player.ess_role)+" Menu");
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

ess_vip_lives()
{
	while(1)
	{
		level waittill("player_spawn", player);
		if(player == self)
		{
			if(!isDefined(self.pers["ess_got_lives"]))
			{
				self.pers["ess_got_lives"] = true;
				self braxi\_mod::giveLife();
				self braxi\_mod::giveLife();
			}
			return;
		}
	}
}

//=============================================================================
// MENU RESPONSE / OPEN
//=============================================================================
OnMenuResponse()
{
	self endon("disconnect");
	self.inessentials_menu = false;
	for(;;wait .05)
	{
		self waittill("menuresponse", menu, response);
		if(!self.inessentials_menu && response == "essentials_menu" && self.frozen == 0)
		{
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

endMenu()
{
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

//=============================================================================
// DYNAMIC PER-PLAYER MENU BUILDING
// Instead of a global option list, we build a per-player option array each
// time the menu opens based on the player's role.
//=============================================================================
buildMenuOptions( role )
{
	// Returns a struct: self.pmenu["name"][submenu][], self.pmenu["script"][submenu][]
	self.pmenu = [];
	self.pmenu["name"]   = [];
	self.pmenu["script"] = [];

	// ---- EVERY PLAYER GETS THESE ----
	pm_addSub( "FOV", "fov" );
		pm_addOpt( "65",   "fov", ::ess_fov65 );
		pm_addOpt( "70",   "fov", ::ess_fov70 );
		pm_addOpt( "75",   "fov", ::ess_fov75 );
		pm_addOpt( "80",   "fov", ::ess_fov80 );
	pm_addSub( "FOV Scale", "fovscale" );
		pm_addOpt( "1.00", "fovscale", ::ess_fovscale_1 );
		pm_addOpt( "1.05", "fovscale", ::ess_fovscale_2 );
		pm_addOpt( "1.10", "fovscale", ::ess_fovscale_3 );
		pm_addOpt( "1.15", "fovscale", ::ess_fovscale_4 );
		pm_addOpt( "1.20", "fovscale", ::ess_fovscale_5 );
		pm_addOpt( "1.25", "fovscale", ::ess_fovscale_6 );
		pm_addOpt( "1.30", "fovscale", ::ess_fovscale_7 );
		pm_addOpt( "1.40", "fovscale", ::ess_fovscale_8 );
	pm_addOpt( "Fullbright",  "main", ::ess_fullbright );
	pm_addOpt( "Laser",       "main", ::ess_laser );
	pm_addOpt( "Ammo",        "main", ::ess_ammo );
	pm_addOpt( "Suicide",     "main", ::ess_suicide );

	if( level.dvar["essentials_menu_points_enabled"] == 1 )
	{
		pm_addSub( "Weapons (Buy)", "give_weap" );
			pm_addOpt( "M9 (Cost: "+level.dvar["price_m9"]+")",                 "give_weap", ::ess_weap_m9 );
			pm_addOpt( "Colt M1911 (Cost: "+level.dvar["price_m1911"]+")",      "give_weap", ::ess_weap_m1911 );
			pm_addOpt( "USP .45 (Cost: "+level.dvar["price_usp"]+")",           "give_weap", ::ess_weap_usp );
			pm_addOpt( "Desert Eagle (Cost: "+level.dvar["price_deagle"]+")",   "give_weap", ::ess_weap_deagle );
			pm_addOpt( "Gold Deagle (Cost: "+level.dvar["price_gold_deagle"]+")", "give_weap", ::ess_weap_gold_deagle );
			pm_addOpt( "Colt 44 (Cost: "+level.dvar["price_colt44"]+")",        "give_weap", ::ess_weap_colt44 );
			pm_addOpt( "M40A3 (Cost: "+level.dvar["price_m40a3"]+")",           "give_weap", ::ess_weap_m40a3 );
			pm_addOpt( "R700 (Cost: "+level.dvar["price_r700"]+")",             "give_weap", ::ess_weap_r700 );
	}

	if( level.dvar["rtd_enabled"] == 1 )
		pm_addOpt( "Roll the Dice", "main", ::rtd_activate );

	pm_addSub( "FPS", "fps" );
		pm_addOpt( "125", "fps", ::ess_fps125 );
		pm_addOpt( "250", "fps", ::ess_fps250 );
		pm_addOpt( "333", "fps", ::ess_fps333 );
		pm_addOpt( "FPS Counter", "fps", ::ess_fpscounter );

	// ---- VIP AND ABOVE ----
	if( roleAtLeast(role,"vip") )
	{
		pm_addSub( "^5Visuals", "vis" );
			pm_addOpt( "Normal Vision",    "vis", ::vis_normal );
			pm_addOpt( "Night Vision",     "vis", ::vis_nightvision );
			pm_addOpt( "Thermal Vision",   "vis", ::vis_thermal );
			pm_addOpt( "AC130 Vision",     "vis", ::vis_ac130 );
			pm_addOpt( "Aftermath Vision", "vis", ::vis_aftermath );
			pm_addOpt( "Cobra Sun Vision", "vis", ::vis_cobra_sun );
			pm_addOpt( "Greyscale",        "vis", ::vis_greyscale );
			pm_addOpt( "Explosion Vision", "vis", ::vis_cargo_blast );
			pm_addOpt( "Sepia Vision",     "vis", ::vis_serpia );
			pm_addOpt( "Sniper Glow",      "vis", ::vis_sniper_glow );
			pm_addOpt( "Chrome",           "vis", ::vis_chrome );
			pm_addOpt( "Promod Vision",    "vis", ::vis_promod_active );
			pm_addOpt( "Disco Vision",     "vis", ::vis_disco );

		pm_addSub( "^5Speed Options", "sped" );
			pm_addOpt( "Super Speed",  "sped", ::ess_speedsuper );
			pm_addOpt( "Fast Speed",   "sped", ::ess_speedfast );
			pm_addOpt( "Normal Speed", "sped", ::ess_speednormal );
			pm_addOpt( "Slow Speed",   "sped", ::ess_speedslow );

		pm_addSub( "^5VIP Weapons", "vwep" );
			pm_addOpt( "R700",       "vwep", ::vwep_r700 );
			pm_addOpt( "Barrett",    "vwep", ::vwep_barrett );
			pm_addOpt( "AK-47",      "vwep", ::vwep_ak47 );
			pm_addOpt( "Desert Eagle","vwep", ::vwep_deagle );
			pm_addOpt( "Colt 44",    "vwep", ::vwep_colt );
			pm_addOpt( "M40A3",      "vwep", ::vwep_m40a3 );
			pm_addOpt( "Brick Blaster","vwep",::vwep_brick );
			pm_addOpt( "RPG",        "vwep", ::vwep_rpg );
			pm_addOpt( "Saw",        "vwep", ::vwep_saw );

		pm_addSub( "^5Player Options", "pot" );
			pm_addOpt( "Heal Me",       "pot", ::ess_healme );
			pm_addOpt( "Toggle Ninja",  "pot", ::ess_ninja );
			pm_addOpt( "Give Life",     "pot", braxi\_mod::giveLife );
			pm_addOpt( "Spawn Me",      "pot", ::ess_spawnme );
			pm_addOpt( "Extra Health",  "pot", ::ess_extrahealth );
			pm_addOpt( "All Perks",     "pot", ::ess_perks );
			pm_addOpt( "Fast Reload",   "pot", ::ess_fastreload );
			pm_addOpt( "Melee Range",   "pot", ::ess_meleerange );

		pm_addSub( "^5Models", "mod" );
			pm_addOpt( "Price (USMC CQB)",  "mod", ::model_usmccqb );
			pm_addOpt( "SAS Soldier",       "mod", ::model_usmcsnip );
			pm_addOpt( "Zoey",              "mod", ::model_zoey );
			pm_addOpt( "Farmer",            "mod", ::model_farmer );
			pm_addOpt( "Zakhaev",           "mod", ::model_zakhaev );
			pm_addOpt( "Velinda",           "mod", ::model_velinda );
			pm_addOpt( "Al-Asad",           "mod", ::model_alasad );
			pm_addOpt( "Shepherd",          "mod", ::model_shepherd );
			pm_addOpt( "Makarov",           "mod", ::model_makarov );
			pm_addOpt( "Masterchief",       "mod", ::model_masterchief );

		pm_addSub( "^5Quick Chat", "qr" );
			pm_addOpt( "Hello!",      "qr", ::qr_hi );
			pm_addOpt( "Yes!",        "qr", ::qr_yes );
			pm_addOpt( "No!",         "qr", ::qr_no );
			pm_addOpt( "Nice one!",   "qr", ::qr_niceone );
			pm_addOpt( "Nice try!",   "qr", ::qr_nicetry );
			pm_addOpt( "Come on!",    "qr", ::qr_comeon );
			pm_addOpt( "Not FreeRun!","qr", ::qr_notfree );
			pm_addOpt( "GoodBye!",    "qr", ::qr_bye );
	}

	// ---- ADMIN AND ABOVE ----
	if( roleAtLeast(role,"admin") )
	{
		pm_addSub( "^3Admin: Players", "adm_pl" );
			pm_addOpt( "Spawn All",     "adm_pl", ::adm_spawnall );
			pm_addOpt( "Heal All",      "adm_pl", ::adm_healall );
			pm_addOpt( "Give XP (Self)","adm_pl", ::adm_xp_self );
			pm_addOpt( "Give XP (All)", "adm_pl", ::adm_xp_all );

		pm_addSub( "^3Admin: Fun", "adm_fun" );
			pm_addOpt( "Nuke Bullets (Unlimited)", "adm_fun", ::ess_nuke );
			pm_addOpt( "3 Nuke Bullets",           "adm_fun", ::ess_shootnuke );
			pm_addOpt( "Jetpack",                  "adm_fun", ::ess_jetpack );
			pm_addOpt( "Water Bullets",            "adm_fun", ::ess_water );
			pm_addOpt( "Flamethrower",             "adm_fun", ::ess_flamethrower );
			pm_addOpt( "Teleport Gun",             "adm_fun", ::ess_TeleportGun );
			pm_addOpt( "Nova Gas",                 "adm_fun", ::ess_NovaNade );
			pm_addOpt( "Death Machine",            "adm_fun", ::ess_toggleDM );
	}

	// ---- CO-OWNER AND ABOVE ----
	if( roleAtLeast(role,"coowner") )
	{
		pm_addSub( "^4Co-Owner: Server", "co_srv" );
			pm_addOpt( "Ghost Mode",      "co_srv", ::ess_ghost );
			pm_addOpt( "Matrix Effect",   "co_srv", ::ess_matrix );
			pm_addOpt( "Party Mode",      "co_srv", ::ess_party );
			pm_addOpt( "Throwing Knives", "co_srv", ::ess_throw );
			pm_addOpt( "Clones",          "co_srv", ::ess_clones );
	}

	// ---- OWNER ONLY ----
	if( role == "owner" )
	{
		pm_addSub( "^1Owner: Server", "own_srv" );
			pm_addOpt( "Spawn All",          "own_srv", ::adm_spawnall );
			pm_addOpt( "Give All 500 XP",    "own_srv", ::own_xp_all500 );
			pm_addOpt( "Head Explode (Self)","own_srv", ::ess_RemoveYoHead );
	}
}

pm_addOpt( name, menu, script )
{
	if(!isDefined(self.pmenu["name"][menu])) self.pmenu["name"][menu] = [];
	self.pmenu["name"][menu][self.pmenu["name"][menu].size] = name;
	self.pmenu["script"][menu][self.pmenu["name"][menu].size] = script;
}

pm_addSub( displayname, name )
{
	pm_addOpt( displayname, "main", name );
}

pm_getMenuStruct( menu )
{
	itemlist = "";
	if(!isDefined(self.pmenu["name"][menu])) return itemlist;
	for(i=0;i<self.pmenu["name"][menu].size;i++)
		itemlist = itemlist + self.pmenu["name"][menu][i] + "\n";
	return itemlist;
}

//=============================================================================
// MENU RENDERING (unchanged logic, uses per-player pmenu)
//=============================================================================
EssentialsMenu()
{
	self endon("close_essentials_menu");
	self endon("disconnect");

	// Re-check role in case it changed (e.g. GUID loaded late)
	self.ess_role = getPlayerRole(self);
	self buildMenuOptions(self.ess_role);

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
	self.essentials_menu[4] settext(self pm_getMenuStruct(submenu));
	self.essentials_menu[4] thread FadeIn(.5,true,"right");
	self.essentials_menu[5] = addTextHud( self, -170, 400, 1, "left", "middle", "right" ,1.4, 103 );
	self.essentials_menu[5] settext("^7Select: ^3[Right or Left Mouse]^7\nUse: ^3[[{+activate}]]^7\nLeave: ^3[[{+melee}]]\n"+getRoleLabel(self.ess_role)+" ^7Menu");
	self.essentials_menu[5] thread FadeIn(.5,true,"right");
	self.essentials_menubg = addTextHud( self, 0, 0, .5, "left", "top", undefined , 0, 101 );
	self.essentials_menubg.horzAlign = "fullscreen";
	self.essentials_menubg.vertAlign = "fullscreen";
	self.essentials_menubg setShader("black", 640, 480);
	self.essentials_menubg thread FadeIn(.2);

	for(selected=0;!self meleebuttonpressed();wait .05)
	{
		if(self Attackbuttonpressed())
		{
			self playLocalSound( "mouse_over" );
			if(selected == self.pmenu["name"][submenu].size-1) selected = 0;
			else selected++;
		}
		if(self adsbuttonpressed())
		{
			self braxi\_common::clientCmd("-speed_throw");
			self playLocalSound( "mouse_over" );
			if(selected == 0) selected = self.pmenu["name"][submenu].size-1;
			else selected--;
		}
		if(self adsbuttonpressed() || self Attackbuttonpressed())
		{
			if(submenu == "main")
			{
				self.essentials_menu[2] moveOverTime( .05 );
				self.essentials_menu[2].y = 89 + (16.8 * selected);
				self.essentials_menu[3] moveOverTime( .05 );
				self.essentials_menu[3].y = 93 + (16.8 * selected);
			}
			else
			{
				self.essentials_menu[7] moveOverTime( .05 );
				self.essentials_menu[7].y = 10 + self.essentials_menu[6].y + (16.8 * selected);
			}
		}
		if((self adsbuttonpressed() || self Attackbuttonpressed()) && !self useButtonPressed()) wait .15;
		if(self useButtonPressed())
		{
			if(!isString(self.pmenu["script"][submenu][selected+1]))
			{
				self thread [[self.pmenu["script"][submenu][selected+1]]]();
				self thread endMenu();
				self notify("close_essentials_menu");
			}
			else
			{
				abstand = (16.8 * selected);
				submenu = self.pmenu["script"][submenu][selected+1];
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
				self.essentials_menu[9] settext(self pm_getMenuStruct(submenu));
				self.essentials_menu[9] thread FadeIn(.5,true,"left");
				selected = 0;
				wait .2;
			}
		}
	}
	self thread endMenu();
}

//=============================================================================
// HUD HELPERS
//=============================================================================
addTextHud( who, x, y, alpha, alignX, alignY, vert, fontScale, sort )
{
	if( isPlayer( who ) ) hud = newClientHudElem( who );
	else hud = newHudElem();
	hud.x = x;
	hud.y = y;
	hud.alpha = alpha;
	hud.sort = sort;
	hud.alignX = alignX;
	hud.alignY = alignY;
	if(isdefined(vert)) hud.horzAlign = vert;
	if(fontScale != 0)  hud.fontScale = fontScale;
	return hud;
}

FadeOut(time,slide,dir)
{
	if(!isDefined(self)) return;
	if(isdefined(slide) && slide)
	{
		self MoveOverTime(0.2);
		if(isDefined(dir) && dir == "right") self.x+=600;
		else self.x-=600;
	}
	self fadeovertime(time);
	self.alpha = 0;
	wait time;
	if(isDefined(self)) self destroy();
}

FadeIn(time,slide,dir)
{
	if(!isDefined(self)) return;
	if(isdefined(slide) && slide)
	{
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

Blur(start,end)
{
	self notify("newblur");
	self endon("newblur");
	start = start * 10;
	end = end * 10;
	self endon("disconnect");
	if(start <= end)
	{
		for(i=start;i<end;i++)
		{
			self setClientDvar("r_blur", i / 10);
			wait .05;
		}
	}
	else for(i=start;i>=end;i--)
	{
		self setClientDvar("r_blur", i / 10);
		wait .05;
	}
}

//=============================================================================
// POINTS SYSTEM
//=============================================================================
ess_points()
{
	self endon("disconnect");
	self endon("death");
	while(1)
	{
		self.points = self getStat(3256);
		if( self.points < level.dvar["essentials_menu_points_max"] )
		{
			self.points += 1;
			self setStat(3256,self.points);
			if( self.points == level.dvar["essentials_menu_points_max"] )
				self iPrintln("^3Essentials Menu:^7 Maximum Points reached");
		}
		self thread ess_points_hud(self.points);
		wait 5;
	}
}

ess_points_hud(points)
{
	self endon( "disconnect" );
	while( !isPlayer( self ) || !isAlive( self ) ) wait( 0.05 );
	if( isDefined( self.pnts ) ) self.pnts destroy();
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
	self.pnts.label = &"Points: &&1";
	self.pnts.hideWhenInMenu = true;
	self.pnts setValue( points );
}

//=============================================================================
// STANDARD MENU ACTIONS (all players)
//=============================================================================
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
ess_fov65()  { self setClientDvar("cg_fov",65);  self iPrintln("FOV set to ^165"); }
ess_fov70()  { self setClientDvar("cg_fov",70);  self iPrintln("FOV set to ^170"); }
ess_fov75()  { self setClientDvar("cg_fov",75);  self iPrintln("FOV set to ^175"); }
ess_fov80()  { self setClientDvar("cg_fov",80);  self iPrintln("FOV set to ^180"); }
ess_fovscale_1() { self setClientDvar("cg_fovscale",1);    self setStat(3255,1); self iPrintln("FOV Scale ^11.00"); }
ess_fovscale_2() { self setClientDvar("cg_fovscale",1.05); self setStat(3255,2); self iPrintln("FOV Scale ^11.05"); }
ess_fovscale_3() { self setClientDvar("cg_fovscale",1.1);  self setStat(3255,3); self iPrintln("FOV Scale ^11.10"); }
ess_fovscale_4() { self setClientDvar("cg_fovscale",1.15); self setStat(3255,4); self iPrintln("FOV Scale ^11.15"); }
ess_fovscale_5() { self setClientDvar("cg_fovscale",1.2);  self setStat(3255,5); self iPrintln("FOV Scale ^11.20"); }
ess_fovscale_6() { self setClientDvar("cg_fovscale",1.25); self setStat(3255,6); self iPrintln("FOV Scale ^11.25"); }
ess_fovscale_7() { self setClientDvar("cg_fovscale",1.3);  self setStat(3255,7); self iPrintln("FOV Scale ^11.30"); }
ess_fovscale_8() {self setClientDvar("cg_fovscale",1.4); self setStat(3255,8); self iPrintln("FOV Scale ^11.40");
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

ess_fps125()    { self setClientDvar("com_maxfps",125); self iPrintln("FPS ^1125"); }
ess_fps250()    { self setClientDvar("com_maxfps",250); self iPrintln("FPS ^1250"); }
ess_fps333()    { self setClientDvar("com_maxfps",333); self iPrintln("FPS ^1333"); }
ess_fpscounter(){ self setClientDvar("cg_drawFPS","Simple"); self setClientDvar("cg_drawFPSLabels","1"); }

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

//=============================================================================
// WEAPON BUY FUNCTIONS (points)
//=============================================================================
ess_buy_weapon( weapname, price )
{
	if(level.ess_allow_weap_buy != true)
	{ self iPrintln("^3Essentials Menu:^7 Buying Weapons is currently ^1Disabled"); return; }
	if( self.pers["team"] != "allies" )
	{ self iPrintln("^1Activators ^7are not allowed to buy weapons!"); return; }
	if( self hasWeapon(weapname) )
	{ self iPrintln("You already have this weapon equipped!"); return; }

	self.points = self getStat(3256);
	if(self.points < price)
	{ self iPrintln("You do not have enough ^1Points^7!"); return; }

	PrecacheItem(weapname);
	self TakeAllWeapons();
	self giveWeapon(weapname);
	self GiveMaxAmmo(weapname);
	self SwitchToWeapon(weapname);
	self.points -= price;
	self setStat(3256,self.points);
	self thread ess_points_hud(self.points);
}

ess_weap_m9()         { self ess_buy_weapon("beretta_mp",       level.dvar["price_m9"]); }
ess_weap_m1911()      { self ess_buy_weapon("colt45_mp",        level.dvar["price_m1911"]); }
ess_weap_usp()        { self ess_buy_weapon("usp_mp",           level.dvar["price_usp"]); }
ess_weap_deagle()     { self ess_buy_weapon("deserteagle_mp",   level.dvar["price_deagle"]); }
ess_weap_gold_deagle(){ self ess_buy_weapon("deserteaglegold_mp",level.dvar["price_gold_deagle"]); }
ess_weap_colt44()     { self ess_buy_weapon("colt44_mp",        level.dvar["price_colt44"]); }
ess_weap_m40a3()      { self ess_buy_weapon("m40a3_mp",         level.dvar["price_m40a3"]); }
ess_weap_r700()       { self ess_buy_weapon("remington700_mp",  level.dvar["price_r700"]); }

//=============================================================================
// VIP WEAPON FUNCTIONS (free, jumpers only)
//=============================================================================
vwep_give( weapname )
{
	if(self.pers["team"] != "allies")
	{ self iPrintlnBold("^7Activator can't get this weapon"); return; }
	self takeAllWeapons();
	self GiveWeapon(weapname);
	self GiveMaxAmmo(weapname);
	self SwitchToWeapon(weapname);
	iPrintln("^5[VIP] ^7"+self.name+" ^7got ^3"+weapname);
}

vwep_r700()    { self vwep_give("remington700_mp"); }
vwep_barrett() { self vwep_give("barrett_acog_mp"); }
vwep_ak47()    { self vwep_give("ak47_mp"); }
vwep_deagle()  { self vwep_give("deserteagle_mp"); }
vwep_colt()    { self vwep_give("colt44_mp"); }
vwep_m40a3()   { self vwep_give("m40a3_mp"); }
vwep_brick()   { self vwep_give("brick_blaster_mp"); }
vwep_rpg()     { self vwep_give("rpg_mp"); }
vwep_saw()     { self vwep_give("saw_acog_mp"); }

//=============================================================================
// VIP PLAYER OPTIONS
//=============================================================================
ess_healme()
{
	self.health = 100;
	iPrintln("^5[VIP] ^7"+self.name+" ^7was ^3Healed");
}

ess_spawnme()
{
	if( !isDefined( self.pers["team"] ) || self.pers["team"] == "spectator" )
		self braxi\_teams::setTeam( "allies" );
	self braxi\_mod::spawnPlayer();
	iPrintln("^5[VIP] ^7"+self.name+" ^7was ^3Respawned");
}

ess_extrahealth()
{
	self endon("disconnect");
	iPrintln("^5[VIP] ^7"+self.name+" ^7has extra ^3Health!");
	self.maxhealth = 200;
	self.health = self.maxhealth;
}

ess_fastreload()
{
	self endon("disconnect");
	self setperk("specialty_fastreload");
	iPrintln("^5[VIP] ^7"+self.name+" ^7has ^3Faster Reload!");
}

ess_meleerange()
{
	self endon("disconnect");
	iPrintln("^5[VIP] ^7"+self.name+" ^7got extra ^3Melee Range!");
	self setClientDvar( "player_meleeRange", "400" );
	level waittill( "endround" );
	self setClientDvar( "player_meleeRange", "100" );
}

ess_perks()
{
	iPrintln("^5[VIP] ^7"+self.name+" ^7has enabled ^3All Perks");
	self setPerk("specialty_armorvest");
	self setPerk("specialty_longersprint");
	self setPerk("specialty_fastreload");
	self setPerk("specialty_bulletdamage");
	self setPerk("specialty_bulletaccuracy");
	self setPerk("specialty_rof");
	self setPerk("specialty_holdbreath");
}

ess_ninja()
{
	self endon( "disconnect" );
	self endon( "death" );
	iPrintln("^5[VIP] ^7"+self.name+" ^7enabled ^3Ninja!");
	wait 1;
	setDvar( "sv_cheats", "1" );
	self hide();
	setDvar( "sv_cheats", "0" );
	for(i=0;i<120;i++)
	{
		wait .5;
	}
	setDvar( "sv_cheats", "1" );
	self show();
	setDvar( "sv_cheats", "0" );
	self iPrintlnBold("^1You are visible again");
}

//=============================================================================
// VIP SPEED OPTIONS
//=============================================================================
ess_speed_set( scale, label )
{
	self endon("disconnect");
	self SetMoveSpeedScale(scale);
	iPrintln("^5[VIP] ^7"+self.name+" ^7got ^3"+label);
	while(isDefined(self) && self.sessionstate == "playing" && game["state"] != "round ended")
	{
		if(!self isOnGround() && !self.doingBH)
		{
			while(!self isOnGround()) wait 0.05;
			earthquake (0.3, 1, self.origin, 100);
		}
		wait .2;
	}
	if(isDefined(self)) self SetMoveSpeedScale(1);
}

ess_speedsuper()  { self ess_speed_set(1.8, "Super Speed!"); }
ess_speedfast()   { self ess_speed_set(1.4, "Fast Speed!"); }
ess_speednormal() { self ess_speed_set(1.1, "Normal Speed!"); }
ess_speedslow()   { self ess_speed_set(0.2, "Turtle Speed!"); }

//=============================================================================
// VIP VISION OPTIONS
//=============================================================================
vis_normal()
{
	self iPrintln("Normal Vision ^3[ON]");
	self setClientDvar("r_glow", 0);
	self setClientDvar("r_filmTweakEnable", 0);
	self setClientDvar("r_filmUseTweaks", 0);
	self setClientDvar("r_filmTweakContrast", 1);
	self setClientDvar("r_filmTweakBrightness", 0);
	self setClientDvar("r_filmTweakDesaturation", 0.2);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1 1 1");
	self setClientDvar("r_filmTweakDarkTint", "1 1 1");
}
vis_nightvision()
{
	self iPrintln("Night Vision ^3[ON]");
	self setClientDvar("r_FilmTweakDarktint", "0 1.54321 0.000226783");
	self setClientDvar("r_FilmTweakLighttint", "1.5797 1.9992 2.0000");
	self setClientDvar("r_FilmTweakInvert", "0");
	self setClientDvar("r_FilmTweakContrast", "1.63");
	self setClientDvar("r_FilmTweakDesaturation", "1");
	self setClientDvar("r_FilmTweakEnable", "1");
	self setClientDvar("r_FilmUseTweaks", "1");
}
vis_thermal()
{
	self iPrintln("Thermal Vision ^3[ON]");
	self setClientDvar("r_filmTweakLightTint", "1 1 1");
	self setClientDvar("r_filmTweakDarkTint", "1 1 1");
	self setClientDvar("r_FilmTweakInvert", "1");
	self setClientDvar("r_FilmTweakBrightness", "0.13");
	self setClientDvar("r_FilmTweakContrast", "1.55");
	self setClientDvar("r_FilmTweakDesaturation", "1");
	self setClientDvar("r_FilmTweakEnable", "1");
	self setClientDvar("r_FilmUseTweaks", "1");
}
vis_ac130()
{
	self iPrintln("AC130 Vision ^3[ON]");
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_filmTweakContrast", 1.55);
	self setClientDvar("r_filmTweakBrightness", 0.13);
	self setClientDvar("r_filmTweakDesaturation", 1);
	self setClientDvar("r_filmTweakInvert", 1);
	self setClientDvar("r_filmTweakLightTint", "1 1 1");
	self setClientDvar("r_filmTweakDarkTint", "1 1 1");
}
vis_aftermath()
{
	self iPrintln("Aftermath Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_glow", 1);
	self setClientDvar("r_glowRadius0", 6.07651);
	self setClientDvar("r_glowBloomCutoff", 0.65);
	self setClientDvar("r_glowBloomDesaturation", 0.65);
	self setClientDvar("r_glowBloomIntensity0", 0.45);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 1.8);
	self setClientDvar("r_filmTweakBrightness", 0.05);
	self setClientDvar("r_filmTweakDesaturation", 0.58);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1 0.969 0.9");
	self setClientDvar("r_filmTweakDarkTint", "0.7 0.3 0.2");
}
vis_cobra_sun()
{
	self iPrintln("Cobra Sun Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 1.2);
	self setClientDvar("r_filmTweakBrightness", 0);
	self setClientDvar("r_filmTweakDesaturation", 0.48);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "0.7 0.85 1");
	self setClientDvar("r_filmTweakDarkTint", "0.5 0.75 1.08");
}
vis_greyscale()
{
	self iPrintln("Greyscale Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 1);
	self setClientDvar("r_filmTweakBrightness", 0);
	self setClientDvar("r_filmTweakDesaturation", 1);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1 1 1");
	self setClientDvar("r_filmTweakDarkTint", "1 1 1");
}
vis_cargo_blast()
{
	self iPrintln("Explosion Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_glow", 1);
	self setClientDvar("r_glowRadius0", 32);
	self setClientDvar("r_glowBloomCutoff", 0.1);
	self setClientDvar("r_glowBloomDesaturation", 0.822);
	self setClientDvar("r_glowBloomIntensity0", 8);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 1.45);
	self setClientDvar("r_filmTweakBrightness", 0.17);
	self setClientDvar("r_filmTweakDesaturation", 0.785);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1.99 0.798 0");
	self setClientDvar("r_filmTweakDarkTint", "1.99 1.32 0");
}
vis_serpia()
{
	self iPrintln("Sepia Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 1.43801);
	self setClientDvar("r_filmTweakBrightness", 0.1443);
	self setClientDvar("r_filmTweakDesaturation", 0.9525);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1.0074 0.6901 0.3281");
	self setClientDvar("r_filmTweakDarkTint", "1.0707 1.0679 0.9181");
}
vis_sniper_glow()
{
	self iPrintln("Sniper Glow Vision ^3[ON]");
	self setClientDvar("r_filmUseTweaks", 1);
	self setClientDvar("r_glow", 1);
	self setClientDvar("r_glowRadius0", 0);
	self setClientDvar("r_glowBloomCutoff", 0.231778);
	self setClientDvar("r_glowBloomDesaturation", 0);
	self setClientDvar("r_glowBloomIntensity0", 0);
	self setClientDvar("r_filmTweakEnable", 1);
	self setClientDvar("r_filmTweakContrast", 0.87104);
	self setClientDvar("r_filmTweakBrightness", 0);
	self setClientDvar("r_filmTweakDesaturation", 0.352396);
	self setClientDvar("r_filmTweakInvert", 0);
	self setClientDvar("r_filmTweakLightTint", "1.10838 1.10717 1.15409");
	self setClientDvar("r_filmTweakDarkTint", "0.7 0.928125 1");
}
vis_chrome()
{
	self iPrintln("Chrome Vision ^3[ON]");
	self setClientDvar( "r_specularmap", 2);
}
vis_promod_active()
{
	if(!isDefined(self.promod)) self.promod = false;
	if(self.promod == false)
	{
		self.promod = true;
		self thread vis_promod();
		self iPrintln("Promod Vision: ^3[ON]");
	}
	else
	{
		self.promod = false;
		self notify( "stop_promod" );
		self iPrintln("Promod Vision: ^1[OFF]");
	}
}
vis_promod()
{
	self endon("stop_promod");
	self endon("disconnect");
	while(1)
	{
		self setClientDvar("cg_fov", 110);
		self setClientDvar("cg_fovscale", 1.225);
		self setClientDvar("r_fullbright", 0);
		self setClientDvar("r_filmTweakEnable", "1");
		self setClientDvar("r_filmUseTweaks", "1");
		self setClientDvar("r_filmTweakContrast", "1.6");
		self setClientDvar("r_lighttweaksunlight", "1.57");
		level waittill("death");
		self setClientDvar("cg_fov", 95);
		self setClientDvar("cg_fovscale", 1);
		self setClientDvar("r_filmTweakEnable", "0");
		self setClientDvar("r_filmUseTweaks", "0");
		self setClientDvar("r_lighttweaksunlight", "1");
	}
}
vis_disco()
{
	self endon("death");
	self iPrintln("Disco Vision ^3[ON]");
	for(;;)
	{
		SetExpFog(256, 512, 1, 0, 0, 0); wait .8;
		SetExpFog(256, 512, 0, 1, 0, 0); wait .8;
		SetExpFog(256, 512, 0, 0, 1, 0); wait .8;
		SetExpFog(256, 512, 0.4, 1, 0.8, 0); wait .8;
		SetExpFog(256, 512, 0.8, 0, 0.6, 0); wait .8;
		SetExpFog(256, 512, 1, 1, 0.6, 0); wait .8;
		SetExpFog(256, 512, 1, 1, 1, 0); wait .8;
		SetExpFog(256, 512, 0, 0, 0.8, 0); wait .8;
	}
}

//=============================================================================
// VIP MODEL OPTIONS
//=============================================================================
model_set( modelname, label )
{
	self iPrintlnBold("^1Model: ^2"+label);
	wait 2;
	self setModel(modelname);
	iPrintln("^5[VIP] ^7"+self.name+" ^7is now ^3"+label);
}

model_usmccqb()   { self model_set("body_mp_usmc_cqb",                  "Cpt. Price"); }
model_usmcsnip()  { self model_set("body_mp_sas_urban_sniper",           "SAS Soldier"); }
model_zoey()      { self model_set("body_zoey",                          "Zoey"); }
model_farmer()    { self model_set("body_complete_mp_russian_farmer",     "Farmer"); }
model_zakhaev()   { self model_set("body_complete_mp_zakhaev",           "Zakhaev"); }
model_velinda()   { self model_set("body_complete_mp_velinda_desert",    "Velinda"); }
model_alasad()    { self model_set("body_complete_mp_al_asad",           "Al-Asad"); }
model_shepherd()  { self model_set("body_shepherd",                      "Shepherd"); }
model_makarov()   { self model_set("body_makarov",                       "Makarov"); }
model_masterchief(){ self model_set("body_masterchief",                  "Masterchief"); }

//=============================================================================
// VIP QUICK CHAT
//=============================================================================
qr_say( msg )
{
	self sayall("^3"+self.name+": ^7"+msg);
}
qr_hi()      { self qr_say("Hello everyone!"); }
qr_yes()     { self qr_say("Yes!"); }
qr_no()      { self qr_say("No!"); }
qr_niceone() { self qr_say("Nice one!"); }
qr_nicetry() { self qr_say("Nice try!"); }
qr_comeon()  { self qr_say("Come on!"); }
qr_notfree() { self qr_say("It's not free run!"); }
qr_bye()     { self qr_say("GoodBye everyone!"); }

//=============================================================================
// ADMIN ACTIONS
//=============================================================================
adm_spawnall()
{
	players = getEntArray("player","classname");
	for(i=0;i<players.size;i++)
		if(players[i].pers["team"] == "allies" && players[i].sessionstate != "playing")
			players[i] braxi\_mod::spawnPlayer();
	iPrintln("^3[Admin] ^7"+self.name+" ^7spawned all players!");
}

adm_healall()
{
	players = getEntArray("player","classname");
	for(i=0;i<players.size;i++)
		if(isAlive(players[i])) players[i].health = 100;
	iPrintln("^3[Admin] ^7"+self.name+" ^7healed everyone!");
}

adm_xp_self()
{
	self braxi\_rank::giveRankXP("", 1500);
	iPrintln("^3[Admin] ^7"+self.name+" ^7got ^31500 XP!");
}

adm_xp_all()
{
	players = getEntArray("player","classname");
	for(i=0;i<players.size;i++)
		players[i] braxi\_rank::giveRankXP("", 125);
	iPrintln("^3[Admin] ^7"+self.name+" ^7gave everyone ^3125 XP!");
}

//=============================================================================
// ADMIN FUN ACTIONS
//=============================================================================
ess_shootnuke()
{
	self endon("death");
	self GiveWeapon("m1014_grip_mp");
	wait .1;
	self SwitchToWeapon("m1014_grip_mp");
	i=0;
	while(i<3)
	{
		self waittill("weapon_fired");
		if(self getCurrentWeapon() == "m1014_grip_mp")
		{
			self playsound("rocket_explode_default");
			vec = anglestoforward(self getPlayerAngles());
			end = (vec[0] * 200000, vec[1] * 200000, vec[2] * 200000);
			SPLOSIONlocation = BulletTrace(self gettagorigin("tag_eye"), self gettagorigin("tag_eye")+end, 0, self)["position"];
			if(isDefined(level.chopper_fx["explode"]["medium"]))
				playfx(level.chopper_fx["explode"]["medium"], SPLOSIONlocation);
			RadiusDamage( SPLOSIONlocation, 200, 500, 60, self );
			earthquake (0.3, 1, SPLOSIONlocation, 400);
			i++;
			wait 1;
		}
	}
	self TakeWeapon("m1014_grip_mp");
	self GiveWeapon("knife_mp");
	self switchToWeapon("knife_mp");
}

ess_nuke()
{
	self endon("death");
	iPrintln("^3[Admin] ^7"+self.name+" ^7has ^3Nuke Bullets!");
	while(1)
	{
		self waittill("weapon_fired");
		my = self gettagorigin("j_head");
		trace = bullettrace(my, my + anglestoforward(self getplayerangles())*100000,true,self)["position"];
		self playSound("artillery_impact");
		dis = distance(self.origin, trace);
		if(dis<101) RadiusDamage(trace, dis, 200, 50, self);
		RadiusDamage(trace, 60, 250, 50, self);
		RadiusDamage(trace, 100, 800, 50, self);
	}
}

ess_water()
{
	self endon("death");
	self endon("disconnect");
	iPrintln("^3[Admin] ^7"+self.name+" ^7got ^3Water Bullets!");
	if(!isDefined(level._effect["iPRO"]))
		level._effect["iPRO"] = loadfx("explosions/grenadeExp_water");
	wait 1;
	for(;;)
	{
		self waittill("weapon_fired");
		playfx(level._effect["iPRO"],bullettrace(self getEye(), self getEye()+anglestoforward(self getplayerangles())*100000,0,self)["position"]);
	}
}

ess_flamethrower()
{
	self endon("death");
	self endon("disconnect");
	for(;;)
	{
		self giveweapon("defaultweapon_mp");
		self SwitchToWeapon("defaultweapon_mp");
		self waittill("weapon_fired");
		vec = anglestoforward(self getPlayerAngles());
		end = (vec[0] * 200000, vec[1] * 200000, vec[2] * 200000);
		SPLOSIONlocation = BulletTrace(self gettagorigin("tag_eye"), self gettagorigin("tag_eye")+end, 0, self)["position"];
		explode = loadfx("fire/tank_fire_engine");
		playfx(explode, SPLOSIONlocation);
	}
}

ess_TeleportGun()
{
	if(!isDefined(self.tpg)) self.tpg = false;
	if(self.tpg == false)
	{
		self.tpg = true;
		self GiveWeapon("m21_acog_mp");
		self SwitchToWeapon("m21_acog_mp");
		self thread ess_TeleportRun();
		iPrintln("^3[Admin] ^7"+self.name+" ^7has a ^3Teleport Gun!");
	}
	else
	{
		self.tpg = false;
		self TakeWeapon("m21_acog_mp");
		self notify("Stop_TP");
		iPrintln("^3[Admin] ^7"+self.name+" ^7disabled the ^3Teleport Gun!");
	}
}
ess_TeleportRun()
{
	self endon("death");
	self endon("Stop_TP");
	for(;;)
	{
		self waittill("weapon_fired");
		if(self GetCurrentWeapon() == "m21_acog_mp")
			self setorigin(BulletTrace(self gettagorigin("j_head"),self gettagorigin("j_head")+anglestoforward(self getplayerangles())*1000000,0,self)["position"]);
	}
}

ess_NovaNade()
{
	iPrintln("^3[Admin] ^7"+self.name+" ^7has ^3Nova Gas!");
	self giveWeapon("smoke_grenade_mp");
	self iPrintln("Press [{+smoke}] to throw Nova Gas");
	self waittill("grenade_fire", grenade, weaponName);
	if(weaponName == "smoke_grenade_mp")
	{
		nova = spawn("script_model", grenade.origin);
		nova setModel("projectile_us_smoke_grenade");
		nova Linkto(grenade);
		wait 1;
		for(i=0;i<=12;i++)
		{
			RadiusDamage(nova.origin,300,100,50,self);
			wait 1;
		}
		nova delete();
	}
}

ess_toggleDM()
{
	self endon("disconnect");
	self endon("death");
	if(!isDefined(self.DM)) self.DM = false;
	if(self.DM == false)
	{
		self.DM = true;
		iPrintln("^3[Admin] ^7"+self.name+" ^7has a ^3Death Machine!");
		self thread ess_DeathMachine();
	}
	else
	{
		self.DM = false;
		self notify("end_dm");
		iPrintln("^3[Admin] ^7"+self.name+" ^7disabled the ^3Death Machine!");
	}
}
ess_DeathMachine()
{
	self endon("disconnect");
	self endon("death");
	self endon("end_dm");
	self allowADS(false);
	self allowSprint(false);
	self setPerk("specialty_bulletaccuracy");
	self setPerk("specialty_rof");
	self setClientDvar("perk_weapSpreadMultiplier", 0.20);
	self setClientDvar("perk_weapRateMultiplier", 0.20);
	self giveWeapon("saw_grip_mp");
	self switchToWeapon("saw_grip_mp");
	self thread ess_watchDMGun();
	self thread ess_endDM();
	for(;;)
	{
		weap = self GetCurrentWeapon();
		self setWeaponAmmoClip(weap, 150);
		wait 0.2;
	}
}
ess_watchDMGun()
{
	self endon("disconnect"); self endon("death"); self endon("end_dm");
	for(;;)
	{
		if(self GetCurrentWeapon() != "saw_grip_mp") self switchToWeapon("saw_grip_mp");
		wait 0.01;
	}
}
ess_endDM()
{
	self endon("disconnect"); self endon("death");
	self waittill("end_dm");
	self takeWeapon("saw_grip_mp");
	self setClientDvar("perk_weapRateMultiplier", 0.7);
	self setClientDvar("perk_weapSpreadMultiplier", 0.6);
	self allowADS(true);
	self allowSprint(true);
}

//=============================================================================
// CO-OWNER ACTIONS
//=============================================================================
ess_ghost()
{
	self endon("disconnect");
	self endon("death");
	if(!isDefined(self.ghost)) self.ghost = false;
	if(self.ghost == false)
	{
		self.ghost = true;
		iPrintln("^4[Co-Owner] ^7"+self.name+" ^7enabled ^3Ghost Mode!");
		while(1)
		{
			self show();
			wait 1.5;
			self hide();
			wait 0.5;
		}
	}
}

ess_matrix()
{
	self endon("disconnect");
	self endon("death");
	iPrintln("^4[Co-Owner] ^7"+self.name+" ^7enabled ^3Matrix!");
	while(1)
	{
		self hide(); wait 0.01;
		self show(); wait 0.01;
	}
}

ess_party()
{
	ambientStop(0);
	ambientplay("end_map");
	iPrintlnBold("^4[Co-Owner] ^7"+self.name+" ^7threw a ^1P^2a^3r^4t^5y!");
	wait 1;
	for(;;)
	{
		SetExpFog(256, 900, 1, (randomint(20)/20),(randomint(20)/20),(randomint(20)/20));
		wait .5;
	}
}

ess_throw()
{
	iPrintln("^4[Co-Owner] ^7"+self.name+" ^7got ^32 Throwing Knives!");
	self thread ess_ThrowKnife();
	self.knifesleft = 2;
}
ess_ThrowKnife()
{
	self notify("knife_fix");
	self endon("knife_fix");
	self endon("disconnect");
	self endon("spawned_player");
	self endon("joined_spectators");
	self endon("death");
	for(;;)
	{
		while(!self SecondaryOffhandButtonPressed()) wait .05;
		if(self.knifesleft >= 1)
		{
			self GiveWeapon("flash_grenade_mp");
			self givemaxammo("flash_grenade_mp");
			self.knifesleft--;
			self braxi\_common::clientCmd("+frag;-frag");
			self waittill("grenade_fire", knife, weaponName);
			if(weaponName == "flash_grenade_mp")
			{
				knife thread ess_DeleteAfterKnifeThrow();
			}
			wait .2;
			self takeWeapon("flash_grenade_mp");
		}
		wait 0.8;
	}
}
ess_DeleteAfterKnifeThrow()
{
	self endon("death");
	prevorigin = self.origin;
	while(1)
	{
		wait .15;
		if(self.origin == prevorigin) break;
		prevorigin = self.origin;
	}
	if(isDefined(self)) self delete();
}

ess_clones()
{
	self endon("death");
	level endon("endround");
	iPrintln("^4[Co-Owner] ^7"+self.name+" ^7has enabled ^3Clones!");
	wait 1;
	while(self.sessionstate == "playing")
	{
		if(self getStance() != "stand")
		{
			self notify("newclone");
			self thread ess_hideClone();
			while(self getStance() != "stand") wait .05;
		}
		wait .05;
	}
}
ess_hideClone()
{
	self endon("disconnect");
	self endon("newclone");
	level endon("endround");
	self.clon = [];
	for(k=0;k<4;k++) self.clon[k] = self cloneplayer(10);
	while(self.sessionstate == "playing")
	{
		if(isDefined(self.clon[0]))
		{
			self.clon[0].origin = self.origin + (0,  60, 0);
			self.clon[1].origin = self.origin + (-60, 0, 0);
			self.clon[2].origin = self.origin + (0, -60, 0);
			self.clon[3].origin = self.origin + (60,  0, 0);
			for(j=0;j<4;j++) self.clon[j].angles = self.angles;
		}
		wait .05;
	}
	for(i=0;i<4;i++)
		if(isDefined(self.clon[i])) self.clon[i] delete();
}

//=============================================================================
// OWNER ACTIONS
//=============================================================================
own_xp_all500()
{
	players = getEntArray("player","classname");
	for(i=0;i<players.size;i++)
		players[i] braxi\_rank::giveRankXP("", 500);
	iPrintln("^1[Owner] ^7"+self.name+" ^7gave everyone ^3500 XP!");
}

ess_RemoveYoHead()
{
	self detachall();
	self playSound("exp_suitcase_bomb_main");
	iPrintln("^1[Owner] ^7"+self.name+"^7's head exploded!");
}

//=============================================================================
// JETPACK (admin+)
//=============================================================================
ess_jetpack()
{
	self endon("death");
	self endon("disconnect");
	iPrintln("^3[Admin] ^7"+self.name+" ^6Jetpack!");
	wait 2;
	if(!isDefined(self.jetpackwait) || self.jetpackwait == 0)
	{
		self.mover = spawn("script_origin", self.origin);
		self.mover.angles = self.angles;
		self linkto(self.mover);
		self.islinkedmover = true;
		self.mover moveto(self.mover.origin + (0,0,25), 0.5);
		self disableweapons();
		self thread ess_jetpack_spritleer();
		iPrintlnBold("^4Jetpack: ^2Melee=Up ^3Fire=Forward ^1G=Kill");

		while(self.islinkedmover == true)
		{
			Earthquake(.1, 1, self.mover.origin, 150);
			angle = self getplayerangles();
			if(self AttackButtonPressed()) self thread ess_moveonangle(angle);
			if(self fragbuttonpressed() || self.health < 1)
			{
				self notify("jepackkilled");
				self thread ess_killjetpack();
			}
			if(self meleeButtonPressed()) self ess_jetpack_vertical("up");
			wait .05;
		}
	}
}
ess_jetpack_vertical(dir)
{
	self endon("death"); self endon("disconnect");
	vertical = (0,0,50);
	if(dir == "up")
	{
		if(bullettracepassed(self.mover.origin, self.mover.origin + vertical, false, undefined))
			self.mover moveto(self.mover.origin + vertical, 0.25);
		else
			self.mover moveto(self.mover.origin - vertical, 0.25);
	}
}
ess_moveonangle(angle)
{
	self endon("death"); self endon("disconnect");
	forward = maps\mp\_utility::vector_scale(anglestoforward(angle), 50);
	forward2 = maps\mp\_utility::vector_scale(anglestoforward(angle), 75);
	if(bullettracepassed(self.origin, self.origin + forward2, false, undefined))
		self.mover moveto(self.mover.origin + forward, 0.25);
	else
		self.mover moveto(self.mover.origin - forward, 0.25);
}
ess_killjetpack()
{
	self endon("disconnect");
	self unlink();
	self.islinkedmover = false;
	wait .5;
	self enableweapons();
}
ess_jetpack_spritleer()
{
	self endon("disconnect");
	self endon("jepackkilled");
	self endon("death");
	for(i=100;i>1;i--)
	{
		if(i == 25) self iPrintlnBold("^1Jetpack fuel: 1/4 remaining");
		if(i == 10) self iPrintlnBold("^1Jetpack crashing in 5 seconds!");
		wait 0.5;
	}
	self iPrintlnBold("Jetpack out of gas");
	self thread ess_killjetpack();
}

//=============================================================================
// ORIGINAL ESSENTIAL SYSTEMS (unchanged from dr_essentials.gsc)
//=============================================================================

// DISABLE WEAPONS AT ROUND START
playerSpawned()
{
	level waittill("player_spawn", player);
	if(player.pers["team"] == "allies" && level.freerun == true)
	{
		level waittill("round_started");
		player iprintln("^8Weapons ^3Enabled ^8During ^3Free run^8!");
	}
	if(player.pers["team"] == "allies" && level.freerun == false)
	{
		level waittill("round_started");
		player DisableWeapons();
		player iprintln("^8Weapons ^9Disabled");
		wait 1.8;
		player EnableWeapons();
		player iprintln("^8Weapons ^3Enabled");
	}
}

// HITMARKER
PlayerDamage()
{
	for(;;)
	{
		level waittill("player_damage", owned, attacker);
		if(isDefined(attacker) && isPlayer(attacker) && owned != attacker && isDefined(level.activ) && (level.activ == owned || level.activ == attacker))
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

// TOMAHAWK
tomahawk_init()
{
	addDvar("pi_tt",          "plugin_tomahawk_enable",          1, 0, 1,    "int");
	addDvar("pi_tt_acti_a",   "plugin_tomahawk_activator_amount",2, 0, 8,    "int");
	addDvar("pi_tt_jumper",   "plugin_tomahawk_jumper",          1, 0, 1,    "int");
	addDvar("pi_tt_jumper_a", "plugin_tomahawk_jumper_amount",   2, 0, 8,    "int");
	addDvar("pi_tt_dmg",      "plugin_tomahawk_damage",          150,10,1000,"int");
	addDvar("pi_tt_empty",    "plugin_tomahawk_empty",           1, 0, 1,    "int");
	addDvar("pi_tt_emptygun", "plugin_tomahawk_emptygun",        "knife","","","string");
	addDvar("pi_tt_switch",   "plugin_tomahawk_autoswitch",      1, 0, 1,    "int");
	addDvar("pi_tt_collect",  "plugin_tomahawk_collect",         1, 0, 1,    "int");
	addDvar("pi_tt_last",     "plugin_tomahawk_last",            20,5, 120,  "int");

	if(!level.dvar["pi_tt"]) return;

	thread onJumper();
	thread onActivator();
	thread WatchTomahawkDamage();
}

onJumper()
{
	while(1)
	{
		level waittill("jumper", jumper);
		jumper giveTomahawk();
	}
}

onActivator()
{
	level waittill("activator", player);
	player giveTomahawk();
}

giveTomahawk()
{
	if(!isDefined(self) || !isPlayer(self) || !isAlive(self)) return;
	if(self.pers["team"] == "allies")
	{
		if(!level.dvar["pi_tt_jumper"]) return;
		if(!self hasWeapon("tomahawk_mp")) self giveWeapon("tomahawk_mp");
		self setWeaponAmmoClip("tomahawk_mp", int(level.dvar["pi_tt_jumper_a"]));
	}
	else
	{
		if(!self hasWeapon("tomahawk_mp")) self giveWeapon("tomahawk_mp");
		self setWeaponAmmoClip("tomahawk_mp", int(level.dvar["pi_tt_acti_a"]));
	}
	if(self hasWeapon("tomahawk_mp") && level.dvar["pi_tt_empty"])
		self thread RemoveTomahawk();
}

AddTomahawk(count)
{
	if(!isDefined(self) || !isPlayer(self) || !isAlive(self)) return;
	if(!self hasWeapon("tomahawk_mp"))
	{
		self giveWeapon("tomahawk_mp");
		self setWeaponAmmoClip("tomahawk_mp", count);
	}
	else
		self setWeaponAmmoClip("tomahawk_mp", self GetWeaponAmmoClip("tomahawk_mp")+count);
	if(level.dvar["pi_tt_empty"]) self thread RemoveTomahawk();
}

RemoveTomahawk()
{
	self notify("remove_toma");
	self endon("disconnect");
	self endon("death");
	self endon("remove_toma");
	wait 0.1;
	while(self GetWeaponAmmoClip("tomahawk_mp") > 0)
	{
		self waittill("grenade_fire", proj, weap);
		if(weap != "tomahawk_mp") continue;
		proj thread TomahawkPickUp();
	}
	self DropItem("tomahawk_mp");
	if(!level.dvar["pi_tt_switch"]) return;
	weaps = self GetWeaponsList();
	for(i=0;i<weaps.size;i++)
	{
		if(WeaponType(weaps[i]) == "bullet" || WeaponType(weaps[i]) == "projectile")
		{
			self SwitchToWeapon(weaps[i]);
			return;
		}
	}
	if(isDefined(level.dvar["pi_tt_emptygun"]))
	{
		gun = strTok(level.dvar["pi_tt_emptygun"],";");
		gun = gun[RandomInt(gun.size)];
		self giveWeapon(gun+"_mp");
		wait 0.05;
		self SwitchToWeapon(gun+"_mp");
	}
}

TomahawkPickUp()
{
	self endon("death");
	wait 2;
	oldpos = self.origin;
	while(1)
	{
		wait 0.25;
		if(oldpos == self.origin) break;
		oldpos = self.origin;
	}
	if(level.dvar["pi_tt_last"] < 2) { self delete(); return; }
	time = level.dvar["pi_tt_last"];
	self thread RemoveAfterTime(time);
	self.trig = spawn("trigger_radius", self.origin, 0, 64, 128);
	while(1)
	{
		self.trig waittill("trigger", player);
		if(!player useButtonPressed() || player.doingBH || player GetWeaponAmmoClip("tomahawk_mp") >= 8) continue;
		player addTomahawk(1);
		player PlaySound("grenade_pickup");
		player iPrintln("^1>> ^2Picked up ^31 ^2tomahawk!");
		self delete();
	}
}

RemoveAfterTime(time)
{
	if(!isDefined(time) || !isDefined(self)) return;
	wait time;
	if(isDefined(self.trig)) self.trig delete();
	if(isDefined(self)) { self notify("death"); self delete(); }
}

WatchTomahawkDamage()
{
	while(1)
	{
		level waittill("player_damage", victim, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		if(sWeapon != "tomahawk_mp" || sMeansOfDeath == "MOD_MELEE" || sMeansOfDeath == "MOD_FALLING" || victim.pers["team"] == eAttacker.pers["team"]) continue;
		victim FinishPlayerDamage(eAttacker, eAttacker, int(level.dvar["pi_tt_dmg"]-1), iDFlags, sMeansOfDeath, "tomahawk_mp", vPoint, vDir, sHitLoc, psOffsetTime);
	}
}

// NO DOUBLE MUSIC
no_double_music()
{
	level waittill("round_ended");
	ambientStop(0);
}

onIntermission()
{
	level waittill("intermission");
	ambientStop(0);
}

// GUID SPOOFING PREVENTION
GUID_Spoofing()
{
	while(1)
	{
		level waittill("connected", player);
		player thread GuidCheck();
	}
}

GuidCheck()
{
	self endon("disconnect");
	while(1)
	{
		guid = self getGuid();
		isInvalid = false;
		if(!isDefined(guid) || guid == "" || guid == "0") isInvalid = true;
		if(guid.size < 17 || guid.size > 20) isInvalid = true;
		for(i=0;i<guid.size;i++)
		{
			char = GetSubStr(guid, i, i+1);
			if(!isSubStr("0123456789", char)) { isInvalid = true; break; }
		}
		if(isInvalid)
		{
			logPrint("GUID SPOOFER;"+guid+";"+self getEntityNumber()+";"+self.name+"\n");
			printLn("GUID CHECK FAILED: "+self.name+" | GUID: "+guid);
			return;
		}
		wait 20;
	}
}

// PARTYMODE (post-round)
partymode()
{
	level waittill("endround");
	thread partymode_events();
}
partymode_events()
{
	for(;;)
	{
		SetExpFog(256, 900, 1, 0, 0, 0.1);         wait .5;
		SetExpFog(256, 900, 0, 1, 0, 0.1);         wait .5;
		SetExpFog(256, 900, 0, 0, 1, 0.1);         wait .5;
		SetExpFog(256, 900, 0.4, 1, 0.8, 0.1);     wait .5;
		SetExpFog(256, 900, 0.8, 0, 0.6, 0.1);     wait .5;
		SetExpFog(256, 900, 1, 1, 0.6, 0.1);       wait .5;
		SetExpFog(256, 900, 1, 1, 1, 0.1);         wait .5;
		SetExpFog(256, 900, 0, 0, 0.8, 0.1);       wait .5;
		SetExpFog(256, 900, 0.2, 1, 0.8, 0.1);     wait .5;
		SetExpFog(256, 900, 0.4, 0.4, 1, 0.1);     wait .5;
	}
}

// HEALTHBAR
healthbar()
{
	while(1)
	{
		level waittill("connected", player);
		player thread numerical_health();
	}
}
numerical_health()
{
	self endon("disconnect");
	while(!isPlayer(self) || !isAlive(self)) wait(0.05);
	self.hp = newClientHudElem(self);
	self.hp.alignX = "left";
	self.hp.alignY = "bottom";
	self.hp.horzAlign = "left";
	self.hp.vertAlign = "bottom";
	self.hp.x = 8;
	self.hp.y = -38;
	self.hp.font = "objective";
	self.hp.fontScale = 1.8;
	self.hp.color = (1,1,1);
	self.hp.alpha = 1;
	self.hp.glowColor = (0,1,0);
	self.hp.glowAlpha = 1;
	self.hp.label = &"Health: &&1";
	self.hp.hideWhenInMenu = true;
	while(self.health > 0)
	{
		self.hp setValue(self.health);
		self.hp.glowColor = (1-(self.health/self.maxhealth), self.health/self.maxhealth, 0);
		wait(0.05);
	}
	if(isDefined(self.hp)) self.hp destroy();
	self thread numerical_health();
}

// KILLCAM
killcam_init()
{
	addDvar("pi_kc",      "plugin_killcam_enable",      1, 0, 1,   "int");
	addDvar("pi_kc_show", "plugin_killcam_show",        2, 0, 2,   "int");
	addDvar("pi_kc_tp",   "plugin_killcam_thirdperson", 1, 0, 1,   "int");
	addDvar("pi_kc_blur", "plugin_killcam_blur",        0, 0, 5.0, "float");
	if(!level.dvar["pi_kc"] || game["roundsplayed"] >= level.dvar["round_limit"]) return;
	setArchive(true);
	self thread WatchForKillcam();
}

WatchForKillcam()
{
	if(game["roundsplayed"] >= level.dvar["round_limit"] || level.freeRun) return;
	while(1)
	{
		level waittill("player_killed", who, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
		if(!isDefined(who) || !isDefined(attacker) || !isDefined(eInflictor) || !isPlayer(who) || !isPlayer(attacker) || who == attacker) continue;
		if(sMeansOfDeath == "MOD_FALLING") continue;
		if(GetTeamPlayersAlive("axis") > 0 && GetTeamPlayersAlive("allies") > 0) continue;
		if((level.dvar["pi_kc_show"] == 0 && isDefined(level.activ) && who == level.activ && attacker.pers["team"] == "allies") ||
		   (level.dvar["pi_kc_show"] == 1 && who.pers["team"] == "allies" && isDefined(level.activ) && level.activ == attacker) ||
		    level.dvar["pi_kc_show"] == 2)
		{
			thread StartKillcam(attacker, sWeapon);
			return;
		}
	}
}

StartKillcam(attacker, sWeapon)
{
	wait 2;
	players = getEntArray("player","classname");
	for(i=0;i<players.size;i++)
	{
		players[i] setClientDvars("cg_thirdperson", int(level.dvar["pi_kc_tp"]), "r_blur", level.dvar["pi_kc_blur"]);
		players[i] thread killcam(attacker getEntityNumber(), -1, sWeapon, 0, 0, 0, 8, undefined, attacker);
	}
}

killcam(attackerNum, killcamentity, sWeapon, predelay, offsetTime, respawn, maxtime, perks, attacker)
{
	self endon("disconnect");
	self endon("spawned");
	level endon("game_ended");
	if(attackerNum < 0) return;
	camtime = 6.5;
	if(isDefined(maxtime)) { if(camtime > maxtime) camtime = maxtime; if(camtime < .05) camtime = .05; }
	if(getdvar("scr_killcam_posttime") == "") postdelay = 2;
	else { postdelay = getdvarfloat("scr_killcam_posttime"); if(postdelay < 0.05) postdelay = 0.05; }
	killcamlength = camtime + postdelay;
	if(isDefined(maxtime) && killcamlength > maxtime)
	{
		if(maxtime < 2) return;
		if(maxtime - camtime >= 1) postdelay = maxtime - camtime;
		else { postdelay = 1; camtime = maxtime - 1; }
		killcamlength = camtime + postdelay;
	}
	killcamoffset = camtime + predelay;
	self notify("begin_killcam", getTime());
	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.killcamentity = killcamentity;
	self.archivetime = killcamoffset;
	self.killcamlength = killcamlength;
	self.psoffsettime = offsetTime;
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	wait 0.05;
	if(self.archivetime <= predelay)
	{
		self.sessionstate = "dead"; self.spectatorclient = -1;
		self.killcamentity = -1;   self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}
	self.killcam = true;
	self thread waitKillcamTime();
	self waittill("end_killcam");
	self endKillcam();
	self.sessionstate = "dead"; self.spectatorclient = -1;
	self.killcamentity = -1;   self.archivetime = 0;
	self.psoffsettime = 0;
}

waitKillcamTime()
{
	self endon("disconnect"); self endon("end_killcam");
	wait 8;
	self notify("end_killcam");
}
endKillcam() { self.killcam = undefined; }

// ROLL THE DICE
rtd_init()
{
	PreCacheItem("brick_blaster_mp");
	PreCacheItem("saw_mp");
	precacheitem("m16_mp");
	PreCacheShellShock("damage_mp");
	VisionSetNight("mp_deathrun_long", 5);
	level.meteorfx = LoadFX("fire/tank_fire_engine");
	level.expbullt = loadfx("explosions/grenadeExp_concrete_1");
	level.flame = loadfx("fire/tank_fire_engine");
	if(!isDefined(level.chopper_fx)) level.chopper_fx = [];
	if(!isDefined(level.chopper_fx["explode"])) level.chopper_fx["explode"] = [];
	level.chopper_fx["explode"]["medium"] = loadfx("explosions/aerial_explosion");
	if(!isDefined(level._effect)) level._effect = [];
	level._effect["iPRO"] = loadfx("explosions/grenadeExp_water");

	for(;;)
	{
		level waittill("player_spawn",player);
		player SetClientDvar("nightVisionDisableEffects","1");
		player.frozen = 0;
		player.has_used_rtd = false;
		player thread rtd_credit();
	}
}

rtd_credit()
{
	level endon("endmap");
	self endon("disconnect");
	self endon("death");
	self endon("joined_spectators");
	level waittill("round_started");
	self iprintln("^2R^7oll ^2t^7he ^2d^7ice active.");
}

rtd_activate()
{
	if(self.has_used_rtd == false)
	{
		currentweapon = self GetCurrentWeapon();
		self.has_used_rtd = true;
		wait 1.5;
		self iprintlnbold("^7You have ^2rolled ^7the dice!");
		self switchtoweapon(currentweapon);
		if(self.pers["team"] == "axis" && self isReallyAlive())
			self iprintlnbold("^2Activators ^2can not ^1use ^7RTD.");
		else
			self thread rtd();
		level waittill("round_ended");
		wait .1;
	}
	else
		self iprintlnbold("^4You have already used ^1RTD^7!");
}

rtd()
{
	self endon("disconnect");
	self endon("death");
	self endon("joined_spectators");
	self endon("killed_player");
	x = RandomInt(17);
	if(x==1)
	{
		self iprintlnbold("^1Gratz!! ^7You got ^1R700");
		self takeAllWeapons(); self ClearPerks();
		self giveWeapon("remington700_mp");
		self GiveMaxAmmo("remington700_mp");
		self SwitchToWeapon("remington700_mp");
		iprintln("^2"+self.name+" ^7got a ^3R700");
	}
	else if(x==15)
	{
		self iprintlnbold("^1Gratz!! ^1Health ^4Boost");
		self.health = 200;
		iprintln("^1"+self.name+" ^7has ^1extra ^7Health!");
	}
	else if(x==2)
	{
		self iprintlnbold("You are ^1HIGH ^7up in the clouds.");
		self shellshock("damage_mp",15);
		iprintln("^1"+self.name+" ^7is ^1higher than the clouds^7!");
	}
	else if(x==3)
	{
		self iprintlnbold("^1You ^7Just ^3Got ^6A ^5LIFE^7.");
		self braxi\_mod::giveLife();
		iprintln("^2"+self.name+" ^7got a ^2Life^7!");
	}
	else if(x==4)
	{
		self iprintlnbold("^1Better luck ^7Next ^2Time^7.");
		self playSound("wtf");
		wait 0.8;
		if(isDefined(level.fx) && isDefined(level.fx["bombexplosion"]))
			playFx(level.fx["bombexplosion"], self.origin);
		iprintln("^1"+self.name+" ^7spontaneously ^1exploded.");
		self suicide();
	}
	else if(x==5)
	{
		self iprintlnbold("^7You are ^1DRUNK ^7for ^315 ^7Seconds.");
		self shellshock("damage_mp",15);
		iprintln("^1"+self.name+" ^7is ^1DRUNK^7.");
	}
	else if(x==14)
	{
		self iprintlnbold("^1Gratz!! ^7You got a ^3GOLDEN ^7DEAGLE!");
		self takeAllWeapons(); self ClearPerks();
		self giveWeapon("deserteaglegold_mp");
		self GiveMaxAmmo("deserteaglegold_mp");
		self SwitchToWeapon("deserteaglegold_mp");
		iprintln("^2"+self.name+" ^7got a ^3GOLDEN ^7Deagle!");
	}
	else if(x==11 && level.dvar["essentials_menu_points_enabled"] == 1)
	{
		self.points = self getStat(3256);
		if(self.points < 236)
		{
			self.points += 20;
			self setStat(3256,self.points);
			self thread ess_points_hud(self.points);
			self iprintlnbold("^7You got ^220 Points!");
			iprintln("^2"+self.name+" ^7got ^220 Points^7!");
		}
		else
		{
			self iprintlnbold("^1You ^2get ^1nothing^7.");
			iprintln("^1"+self.name+"^7 got ^1nothing.");
		}
	}
	else if(x==8)
	{
		self iprintlnbold("^7You are ^5Frozen ^7for ^313 ^7Seconds.");
		self FreezeControls(1);
		self.frozen = 1;
		iprintln("^1"+self.name+" ^7is ^5Frozen^7!");
		wait 13;
		self FreezeControls(0);
		self.frozen = 0;
	}
	else if(x==9)
	{
		self iprintlnbold("^2Nice!! ^7Got ^1Brick ^4Blaster!!!!");
		self takeAllWeapons();
		self giveWeapon("brick_blaster_mp");
		self SwitchToWeapon("brick_blaster_mp");
		iprintln("^2"+self.name+" ^7got a ^2Brick Blaster^7!");
	}
	else if(x==10)
	{
		self takeAllWeapons();
		self iprintlnbold("^1You ^2get ^1nothing^7.");
		self giveweapon("knife_mp");
		self SwitchToWeapon("knife_mp");
		iprintln("^1"+self.name+"^7 got ^1nothing.");
	}
	else if(x==16)
	{
		self iprintlnbold("^1Boost!!!");
		self SetMoveSpeedScale(1.4);
		self setClientDvar("g_gravity",70);
		iprintln("^1"+self.name+"^7 is ^1Pumped!");
	}
	else if(x==7)
	{
		self iprintlnbold("^7Try ^2this ^7for a ^2challenge!");
		self takeAllWeapons();
		self giveWeapon("m16_mp");
		self SwitchToWeapon("m16_mp");
		self SetWeaponAmmoClip("m16_mp",6);
		self SetWeaponAmmoStock("m16_mp",0);
		iprintln("^1"+self.name+" ^7got a ^1broken ^7M16!");
	}
	else if(x==12)
	{
		self iprintlnbold("^7You are ^1BURNING ^7alive!");
		self thread rtd_flameon();
		self PlayLocalSound("last_alive");
		wait 2;
		self thread rtd_hurttodeath();
		iprintln("^1"+self.name+" ^7is on ^1FIRE^7!");
	}
	else if(x==13)
	{
		self iprintlnbold("^7Sprint ^1Disabled.");
		self AllowSprint(false);
		iprintln("^1"+self.name+"'s ^7sprint has been ^1disabled^7.");
	}
	else if(x==6)
	{
		self iprintlnbold("^7You got ^3NUKE BULLETS^7!");
		self thread rtd_killstreak3();
		iprintln("^2"+self.name+" ^7got ^2NUKE BULLETS^7!");
	}
	else
	{
		self iprintlnbold("^3Lucky one! ^7Enjoy ^2500 XP.");
		self braxi\_rank::giveRankXP("", 500);
		iprintln("^2"+self.name+" ^7got ^3500^2xp^7!!");
	}
}

rtd_killstreak3()
{
	self endon("death");
	while(1)
	{
		self waittill("weapon_fired");
		my = self gettagorigin("j_head");
		trace = bullettrace(my, my + anglestoforward(self getplayerangles())*100000,true,self)["position"];
		self playSound("artillery_impact");
		dis = distance(self.origin, trace);
		if(dis<101) RadiusDamage(trace,dis,200,50,self);
		RadiusDamage(trace,60,250,50,self);
		RadiusDamage(trace,100,800,50,self);
	}
}

rtd_hurttodeath()
{
	self endon("disconnect"); self endon("death");
	self endon("joined_spectators"); self endon("killed_player");
	for(;;)
	{
		self FinishPlayerDamage(self,self,15,0,"MOD_SUICIDE","knife_mp",self.origin,self.angles,"none",0);
		self PlayLocalSound("breathing_hurt");
		wait 1.4;
	}
}

rtd_flameon()
{
	self endon("disconnect"); self endon("death");
	self endon("joined_spectators"); self endon("killed_player");
	while(isAlive(self) && isDefined(self))
	{
		playFx(level.meteorfx, self.origin);
		wait .1;
	}
}

// ANTI WALLBANG
Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(isDefined(eAttacker) && isPlayer(eAttacker))
		if(!SightTracePassed(eAttacker Geteye(), self.origin + (0,0,getHitLocHeight(sHitloc)), false, undefined))
			return;
	self braxi\_mod::PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

// ANTI AFK ACTIVATOR
anti_afk_acti_init()
{
	addDvar("antiafkacti",  "antiafk_enable",              1,  0, 1,   "int");
	if(!level.dvar["antiafkacti"]) return;
	addDvar("aa_traps",     "antiafk_traps",               0,  0, 1,   "int");
	addDvar("aa_warn",      "antiafk_warn",               10,  3, 60,  "int");
	addDvar("aa_time",      "antiafk_time",               15,  5, 120, "int");
	addDvar("aa_team",      "antiafk_team",                0,  0, 1,   "int");
	addDvar("aa_trapdelay", "antiafk_trapdelay",           5,  1, 60,  "int");
	addDvar("aa_teltotraps","antiafk_teleporttotraps",     0,  0, 1,   "int");
	addDvar("aa_wmsg",      "antiafk_wmessage", "Please move your ass!", "","","string");
	while(1)
	{
		level waittill("activator", guy);
		thread finmapcheck();
		guy thread TrapActivation();
	}
}

NoTelMap()
{
	return isSubStr("godfather caelum long bigfall iwillrockyou sewers jurapark factory diehard azteca cherry backlot cosmic dragonball flow highrise disco darmuhv2 watercity sm_v2 ruin2", braxi\_maps::getMapNameString(level.mapName));
}

newacti()
{
	level notify("picking activator");
	level endon("picking activator");
	players = getAllPlayers();
	if(!isDefined(players) || isDefined(players) && !players.size || players.size <= 2) return;
	num = randomInt(players.size);
	guy = players[num];
	if(level.dvar["dont_make_peoples_angry"] == 1 && guy getEntityNumber() == getDvarInt("last_picked_player"))
	{
		if(isDefined(players[num-1]) && isPlayer(players[num-1])) guy = players[num-1];
		else if(isDefined(players[num+1]) && isPlayer(players[num+1])) guy = players[num+1];
	}
	if(!isDefined(guy) && !isPlayer(guy) || level.dvar["dont_pick_spec"] && guy.sessionstate == "spectator" || !guy isReallyAlive())
	{ level thread newacti(); return; }
	bxLogPrint(("A: "+guy.name+" ; guid: "+guy.guid));
	iPrintlnBold(guy.name+"^2 was picked to be the new ^1Activator^2!");
	guy thread braxi\_teams::setTeam("axis");
	guy braxi\_mod::spawnPlayer();
	guy braxi\_rank::giveRankXp("activator");
	setDvar("last_picked_player", guy getEntityNumber());
	level notify("activator", guy);
	level.activ = guy;
	wait 0.1;
}

finmapcheck()
{
	trig = getent("endmap_trig","targetname");
	trig waittill("trigger", player);
	level notify("mapfin");
}

TrapActivation()
{
	level endon("newactivator"); level endon("intermission");
	level endon("game over");    level endon("mapfin");
	level endon("endround");
	self endon("disconnect");    self endon("trapsdone");
	self endon("death");
	if(!isDefined(self) || !isPlayer(self) || !isAlive(self)) return;
	if(level.jumpers <= 2) return;
	self checkAFK();
	if(level.dvar["aa_traps"] == 0)
	{
		if(level.jumpers < 2) return;
		iprintlnbold("^1>> ^2Picking new Activator (AFK)!");
		thread newacti();
		if(isAlive(self)) self suicide();
		level.activators = 0; level.activatorKilled = false; level.activ = undefined;
		team = "allies";
		if(getdvarInt("aa_team") == 1) team = "spectator";
		self.pers["team"] = team; self.team = team; self.sessionteam = team;
		self braxi\_mod::spawnSpectator(level.spawn["spectator"].origin, level.spawn["spectator"].angles);
		level notify("newactivator");
		return;
	}
	else
	{
		if(level.trapsDisabled || !isDefined(level.trapTriggers) || !level.trapTriggers.size)
		{
			if(level.jumpers < 2) return;
			iprintlnbold("^1>> ^2Picking new Activator (AFK)!");
			thread newacti();
			if(isAlive(self)) self suicide();
			level.activators = 0; level.activatorKilled = false; level.activ = undefined;
			team = "allies";
			if(getdvarInt("aa_team") == 1) team = "spectator";
			self.pers["team"] = team; self.team = team; self.sessionteam = team;
			self braxi\_mod::spawnSpectator(level.spawn["spectator"].origin, level.spawn["spectator"].angles);
			level notify("newactivator");
			return;
		}
		if(!isDefined(self) || !isPlayer(self) || !isAlive(self)) return;
		iprintlnbold("^7Server activating for AFK Activator!");
		for(i=0;i<level.trapTriggers.size;i++)
		{
			if(!isDefined(self) || !isAlive(self)) return;
			if(!isDefined(level.trapTriggers[i])) continue;
			origin = level.trapTriggers[i].origin;
			pos = PlayerPhysicsTrace(origin+(0,0,100), origin-(0,0,40));
			level.trapTriggers[i] UseBy(self);
			self iPrintln("Trap #"+(i+1));
			if(getdvarInt("aa_teltotraps") == 0 || NoTelMap())
			{
				oldang = self.angles; oldpos = self.origin;
				wait level.dvar["aa_trapdelay"];
				if(oldpos != self.origin || oldang != self.angles)
				{ iprintlnbold("Activator is back!"); return; }
			}
			else
			{
				self setOrigin(pos); wait 0.25;
				oldang = self.angles; oldpos = self.origin;
				wait level.dvar["aa_trapdelay"];
				if(oldpos != self.origin || oldang != self.angles)
				{ iprintlnbold("Activator is back!"); return; }
			}
		}
		iprintlnbold("End of trap activation!");
	}
}

checkAFK()
{
	self endon("disconnect"); self endon("death");
	wmessage = (level.dvar["aa_wmsg"]);
	oldpos = self.origin; oldang = self.angles; time = 0;
	while(1)
	{
		wait 1;
		if(Distance(self.origin, oldpos) < 10 && self.angles == oldang)
		{
			time++;
			if(time == level.dvar["aa_time"]) return;
			else if(time == level.dvar["aa_warn"]) self iPrintlnBold(wmessage);
		}
		else { oldpos = self.origin; oldang = self.angles; time = 0; }
	}
}
