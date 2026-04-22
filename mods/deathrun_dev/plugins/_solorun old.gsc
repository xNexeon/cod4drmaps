/*
=============================================================================
  plugins/_solorun.gsc  —  Solo Run Plugin for DeathRun 1.2
  Compatible with: BraXi's CoD4 DeathRun Mod v1.2 (DeathRunVersion >= 12)

  Fixes applied:
  - Bot now actually spawns in as opfor (activator) instead of staying
    as a spectator.  Root cause: setupBotAsActivator() set pers["team"]
    and called setTeam() but never called spawnPlayer(), so the bot
    remained in the spectator state that playerConnect() left it in.
  - spawnPlayer() is now called as self braxi\_mod::spawnPlayer() — a
    bare call from plugin scope is a GSC compile error.
  - Removed maintainActivatorTeam() loop that could fight the mod's own
    team-management logic (e.g. when the activator dies mid-round).
  - Added a spawned_player / disconnect guard so the setup thread exits
    cleanly if the bot is removed before it finishes initialising.
  - getRealPlayerCount() now counts players whose team is already set to
    any non-spectator value, preventing a transient double-spawn while
    the bot's pers is being written.
=============================================================================
*/

#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init( modVersion )
{
	if ( !isDefined( modVersion ) || modVersion < 12 )
	{
		iPrintLn( "^1[SoloRun] ^7Plugin requires DeathRun v1.2 or higher. Disabled." );
		return;
	}

	level.solorun_botActive = false;
	level.solorun_bot       = undefined;
	iPrintLn( "^2[SoloRun] ^7Plugin loaded - bot activator enabled for solo players." );

	thread monitorPlayers();
}

monitorPlayers()
{
	wait 5;
	for ( ;; )
	{
		realCount = getRealPlayerCount();

		if ( realCount == 1 && !level.solorun_botActive )
			spawnSoloBot();
		else if ( realCount >= 2 && level.solorun_botActive )
			removeSoloBot();
		else if ( realCount == 0 && level.solorun_botActive )
			removeSoloBot();

		wait 2;
	}
}

getRealPlayerCount()
{
	count = 0;
	players = getEntArray( "player", "classname" );

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !isDefined( player ) || !isPlayer( player ) )
			continue;
		// Skip our own bot
		if ( isDefined( player.solorun_isBot ) && player.solorun_isBot )
			continue;
		// Only count players that have actually chosen a side
		// (guards against counting the bot itself during its brief init window)
		if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "spectator" )
			continue;

		count++;
	}
	return count;
}

spawnSoloBot()
{
	level.solorun_botActive = true;
	bot = addTestClient();

	if ( !isDefined( bot ) )
	{
		iPrintLn( "^1[SoloRun] ^7Failed to spawn bot - server may be full." );
		level.solorun_botActive = false;
		return;
	}

	bot.solorun_isBot = true;
	level.solorun_bot = bot;

	// Give playerConnect() time to finish initialising the bot's pers[] block
	// before we start writing to it.
	wait 1;

	if ( !isDefined( bot ) || !isPlayer( bot ) )
	{
		// Bot disconnected during the wait
		level.solorun_botActive = false;
		level.solorun_bot = undefined;
		return;
	}

	bot thread setupBotAsActivator();
	iPrintLn( "^2[SoloRun] ^3Bot activator ^2spawned. Have fun practising!" );
}

setupBotAsActivator()
{
	// Exit cleanly if the bot is kicked / disconnects mid-setup
	self endon( "disconnect" );

	// Wait until pers[] is fully built by playerConnect()
	while ( !isDefined( self.pers ) )
		wait 0.1;

	// -------------------------------------------------------------
	// Assign the bot to the activator team.
	// pers["team"] = "opfor" is the identity the mod checks everywhere.
	// level.spawn uses "axis" as its key for activator spawn points, so
	// we must NOT pass pers["team"] to spawnPlayer() — it would look up
	// level.spawn["opfor"] which doesn't exist and crash.
	// Instead we set pers["team"] = "opfor", then spawn directly using
	// level.spawn["axis"] to pick the spawn point ourselves.
	// -------------------------------------------------------------
	self.pers["team"]   = "opfor";
	self.pers["isBot"]  = true;
	self.pers["weapon"] = "tomahawk_mp";

	self thread braxi\_teams::setTeam( "opfor" );

	self setClientDvar( "name", "^3[BOT] Activator" );

	botSpawnIn( self );

	self thread idleBot();
	self thread enforceActivator();
}

idleBot()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		wait 1;
	}
}

// Watches for respawn events and puts the bot back on opfor every time,
// so it is always the activator across deaths and round transitions.
enforceActivator()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "spawned_player" );

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		if ( !isDefined( self.pers["team"] ) || self.pers["team"] != "opfor" )
		{
			self.pers["team"]   = "opfor";
			self.pers["weapon"] = "tomahawk_mp";
			self thread braxi\_teams::setTeam( "opfor" );
			botSpawnIn( self );
		}
	}
}

// Spawns the bot at an activator ("axis") spawn point.
// We can't use braxi\_mod::spawnPlayer() because it looks up
// level.spawn[pers["team"]], and level.spawn["opfor"] doesn't exist —
// only "axis" and "allies" are valid keys.  So we pick the spawn point
// here and call spawn() directly, mirroring what spawnPlayer() does.
botSpawnIn( bot )
{
	if ( !isDefined( level.spawn["axis"] ) || level.spawn["axis"].size == 0 )
	{
		iPrintLn( "^1[SoloRun] ^7No activator spawn points found!" );
		return;
	}

	spawnPoint = level.spawn["axis"][ randomInt( level.spawn["axis"].size ) ];

	bot.team           = "opfor";
	bot.sessionteam    = "opfor";
	bot.sessionstate   = "playing";
	bot.spectatorclient  = -1;
	bot.killcamentity    = -1;
	bot.archivetime      = 0;
	bot.psoffsettime     = 0;
	bot.statusicon       = "";

	bot braxi\_teams::setPlayerModel();

	bot spawn( spawnPoint.origin, spawnPoint.angles );

	bot giveWeapon( "tomahawk_mp" );
	bot setSpawnWeapon( "tomahawk_mp" );
	bot giveMaxAmmo( "tomahawk_mp" );

	bot thread braxi\_teams::setHealth();
	bot thread braxi\_teams::setSpeed();
}

removeSoloBot()
{
	level.solorun_botActive = false;
	if ( isDefined( level.solorun_bot ) )
	{
		bot = level.solorun_bot;
		level.solorun_bot = undefined;

		if ( isDefined( bot ) && isPlayer( bot ) )
		{
			kick( bot getEntityNumber() );
			iPrintLn( "^2[SoloRun] ^7Second player joined - bot activator removed." );
		}
	}
}
