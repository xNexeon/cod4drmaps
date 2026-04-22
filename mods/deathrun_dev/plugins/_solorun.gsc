/*
=============================================================================
  plugins/_solorun.gsc  —  Solo Run Plugin for DeathRun 1.2
  Compatible with: BraXi's CoD4 DeathRun Mod v1.2 (DeathRunVersion >= 12)

  Bot is ALWAYS the activator. Three-layer defence:

  1. watchRoundStart()  [primary]
     Listens for "round_started" on level and immediately forces the bot
     onto axis.  gameLogic() waits 0.2 s before its first poll, so by the
     time pickRandomActivator / NewPickingSystem could be called the bot is
     already counted as an activator and the picking block is skipped.

  2. interceptActivatorPick()  [secondary]
     If a human gets picked anyway (race condition, freerun, etc.) this
     undoes it.  Unlike the previous version this loop lives on the bot
     entity (not level) so it survives across rounds automatically.

  3. watchBotDeath()  [tertiary]
     When the bot dies as activator, onPlayerKilled() sets
     level.activatorKilled = true and switches it to allies.  We catch
     "death" immediately, reset activatorKilled, and respawn the bot as
     axis before the 0.2 s game-loop tick can call endRound().

  4. enforceActivator()  [safety net]
     Last-resort catch on "spawned_player" — corrects the team if anything
     slipped through.
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

	self thread braxi\_teams::setTeam( "axis" );
	self setClientDvar( "name", "^3[BOT] Activator" );

	botSpawnIn( self );

	self thread idleBot();
	self thread watchRoundStart();       // layer 1: pre-empt picking at round start
	self thread interceptActivatorPick(); // layer 2: undo if human picked anyway
	self thread watchBotDeath();         // layer 3: keep bot as activator after death
	self thread enforceActivator();      // layer 4: safety net
}

idleBot()
{
	self endon( "disconnect" );
	for ( ;; )
		wait 1;
}

// ---------------------------------------------------------------------------
// watchRoundStart  [layer 1]
//
// Fires on every "round_started" notify.  gameLogic() has a 0.2 s wait
// before its first activator-count poll, so assigning the bot to axis here
// means the game loop already sees level.activators >= 1 and never calls
// pickRandomActivator() / NewPickingSystem() at all.
// ---------------------------------------------------------------------------

watchRoundStart()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		level waittill( "round_started" );

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		// Force bot onto axis immediately so the picking block is skipped.
		forceBotToAxis();
		botSpawnIn( self );
	}
}

// ---------------------------------------------------------------------------
// interceptActivatorPick  [layer 2]
//
// Listens for "activator" notify (fired by braxi after any pick).
// If a human was picked, undo it and install the bot instead.
// Lives on the bot entity so it persists across rounds automatically.
// ---------------------------------------------------------------------------

interceptActivatorPick()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		level waittill( "activator", guy );

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		// braxi picked the bot itself - all good.
		if ( guy == self )
			continue;

		// A human was picked - undo it immediately.
		// Switch the human back to allies.
		guy.pers["team"] = "spectator";
		guy thread braxi\_teams::setTeam( "allies" );

		// Install bot as activator.
		level.activ = self;
		forceBotToAxis();
		wait 0.05;

		if ( isDefined( self ) && isPlayer( self ) )
		{
			botSpawnIn( self );
			// Re-fire so other mod systems (rank XP, hud, etc.) update correctly.
			level notify( "activator", self );
		}
	}
}

// ---------------------------------------------------------------------------
// watchBotDeath  [layer 3]
//
// When bot dies: onPlayerKilled() sets level.activatorKilled = true and
// switches the bot to allies.  The round-state loop would then call
// endRound("Activator died") within 0.2 s.
// We catch "death" first, undo both side-effects, and respawn as axis.
// ---------------------------------------------------------------------------

watchBotDeath()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "death" );

		if ( !isDefined( self ) || !isPlayer( self ) )
			return;

		// Cancel braxi's queued jumper-respawn thread.
		self notify( "kill logic" );

		// Undo activatorKilled so the round doesn't end.
		level.activatorKilled = false;

		forceBotToAxis();

		wait 0.05;

		if ( isDefined( self ) && isPlayer( self ) )
			botSpawnIn( self );
	}
}

// ---------------------------------------------------------------------------
// enforceActivator  [layer 4 - safety net]
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
			forceBotToAxis();
			wait 0.05;
			if ( isDefined( self ) && isPlayer( self ) )
				botSpawnIn( self );
		}
	}
}

// ---------------------------------------------------------------------------
// forceBotToAxis
//
// Centralised helper that reliably sets all team state to axis/opfor.
// setTeam() has an early-return guard when pers["team"] already matches,
// so we temporarily set "allies" to force its full body to execute.
// ---------------------------------------------------------------------------

forceBotToAxis()
{
	self.pers["team"]   = "allies";   // trick setTeam's early-return guard
	self thread braxi\_teams::setTeam( "axis" );
	self.pers["team"]   = "opfor";    // restore logical opfor identity
	self.pers["weapon"] = "tomahawk_mp";
}

// ---------------------------------------------------------------------------
// botSpawnIn
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
	bot.sessionteam      = "axis";
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
