/*
=============================================================================
  plugins/_solorun.gsc  —  Solo Run Plugin for DeathRun 1.2
  Compatible with: BraXi's CoD4 DeathRun Mod v1.2 (DeathRunVersion >= 12)

  Bot is ALWAYS the activator:
  - On death, watchBotDeath() fires before the 0.2 s game loop can see
    zero activators.  It cancels any pending respawn, resets
    level.activatorKilled, forces the bot back onto axis, and respawns it
    immediately so the round never ends due to "Activator died".
  - interceptActivatorPick() listens for the level "activator" notify that
    braxi fires when it picks a human as activator (round start / free-run).
    If the bot is still active we silently undo that pick, switch the human
    back to allies, and make the bot the activator instead.
  - enforceActivator() is kept as a last-resort safety net that catches any
    remaining case where the bot ends up on the wrong team after spawning.
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

// ---------------------------------------------------------------------------
// Player monitoring - spawn / remove the bot as headcount changes
// ---------------------------------------------------------------------------

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
		if ( isDefined( player.solorun_isBot ) && player.solorun_isBot )
			continue;
		if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "spectator" )
			continue;

		count++;
	}
	return count;
}

// ---------------------------------------------------------------------------
// Bot spawning / setup
// ---------------------------------------------------------------------------

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

	// Give playerConnect() time to finish initialising the bot's pers[] block.
	wait 1;

	if ( !isDefined( bot ) || !isPlayer( bot ) )
	{
		level.solorun_botActive = false;
		level.solorun_bot = undefined;
		return;
	}

	bot thread setupBotAsActivator();
	iPrintLn( "^2[SoloRun] ^3Bot activator ^2spawned. Have fun practising!" );
}

setupBotAsActivator()
{
	self endon( "disconnect" );

	while ( !isDefined( self.pers ) )
		wait 0.1;

	self.pers["team"]   = "opfor";
	self.pers["isBot"]  = true;
	self.pers["weapon"] = "tomahawk_mp";

	// setTeam() must receive "axis" - that is braxi's internal key for the
	// activator team and the key used in level.spawn[].
	self thread braxi\_teams::setTeam( "axis" );

	self setClientDvar( "name", "^3[BOT] Activator" );

	botSpawnIn( self );

	self thread idleBot();
	self thread watchBotDeath();            // primary death guard
	self thread enforceActivator();         // safety net after unexpected respawn
	level thread interceptActivatorPick();  // prevent human being picked instead
}

idleBot()
{
	self endon( "disconnect" );
	for ( ;; )
		wait 1;
}

// ---------------------------------------------------------------------------
// watchBotDeath - the core "always activator" guard
//
// When the bot dies as activator, braxi's onPlayerKilled() does two things:
//   1. Calls setTeam("allies") on the bot, switching it to jumper.
//   2. Sets level.activatorKilled = true.
// The round-state loop polls every 0.2 s and would call
// endRound("Activator died", ...).
//
// We catch "death" immediately, undo both side-effects, and respawn the bot
// as axis before the game loop's next tick.
// ---------------------------------------------------------------------------

watchBotDeath()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "death" );

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		// Cancel any respawn thread braxi queued for us as a jumper.
		self notify( "kill logic" );

		// Undo activatorKilled so the round-state loop doesn't end the round.
		level.activatorKilled = false;

		// Reassert activator identity.
		// setTeam() early-returns if pers["team"] already matches, so we must
		// briefly set a different value to force the full body to run.
		self.pers["team"] = "allies";
		self thread braxi\_teams::setTeam( "axis" );
		self.pers["team"] = "opfor";
		self.pers["weapon"] = "tomahawk_mp";

		// Let setTeam's suicide() clear the old body, then respawn.
		wait 0.05;

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		botSpawnIn( self );
	}
}

// ---------------------------------------------------------------------------
// enforceActivator - safety net
//
// Catches any case where the bot ends up spawned on the wrong team after
// a round restart or other unexpected path through the spawn logic.
// ---------------------------------------------------------------------------

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
			self.pers["team"] = "allies";
			self thread braxi\_teams::setTeam( "axis" );
			self.pers["team"] = "opfor";
			self.pers["weapon"] = "tomahawk_mp";
			wait 0.05;
			if ( isDefined( self ) && isPlayer( self ) )
				botSpawnIn( self );
		}
	}
}

// ---------------------------------------------------------------------------
// interceptActivatorPick - prevent a human from being chosen as activator
//
// braxi fires  level notify("activator", guy)  after picking someone.
// If that someone isn't the bot, we undo it: switch the human back to allies
// and make the bot the activator instead.
// ---------------------------------------------------------------------------

interceptActivatorPick()
{
	level endon( "endround" );
	level endon( "endmap" );

	for ( ;; )
	{
		level waittill( "activator", guy );

		if ( !isDefined( level.solorun_bot ) || !isPlayer( level.solorun_bot ) )
			continue;

		bot = level.solorun_bot;

		// braxi picked the bot itself - nothing to do.
		if ( guy == bot )
			continue;

		// A human was picked - undo it.
		guy.pers["team"] = "spectator";
		guy thread braxi\_teams::setTeam( "allies" );

		// Install the bot as the official activator.
		level.activ = bot;
		bot.pers["team"] = "allies";
		bot thread braxi\_teams::setTeam( "axis" );
		bot.pers["team"] = "opfor";

		wait 0.05;

		if ( isDefined( bot ) && isPlayer( bot ) )
		{
			botSpawnIn( bot );
			level notify( "activator", bot );
		}
	}
}

// ---------------------------------------------------------------------------
// botSpawnIn - spawns the bot at an activator (axis) spawn point
// ---------------------------------------------------------------------------

botSpawnIn( bot )
{
	if ( !isDefined( level.spawn["axis"] ) || level.spawn["axis"].size == 0 )
	{
		iPrintLn( "^1[SoloRun] ^7No activator spawn points found!" );
		return;
	}

	spawnPoint = level.spawn["axis"][ randomInt( level.spawn["axis"].size ) ];

	bot.team             = "opfor";
	bot.sessionteam      = "axis";   // "opfor" is not a valid CoD4 sessionteam
	bot.sessionstate     = "playing";
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

// ---------------------------------------------------------------------------
// removeSoloBot
// ---------------------------------------------------------------------------

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
