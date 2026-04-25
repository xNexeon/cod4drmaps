///////////////////////////////////////////////////////////////
////|         |///|        |///|       |/\  \/////  ///|  |////
////|  |////  |///|  |//|  |///|  |/|  |//\  \///  ////|__|////
////|  |////  |///|  |//|  |///|  |/|  |///\  \/  /////////////
////|          |//|  |//|  |///|       |////\    //////|  |////
////|  |////|  |//|         |//|  |/|  |/////    \/////|  |////
////|  |////|  |//|  |///|  |//|  |/|  |////  /\  \////|  |////
////|  |////|  |//|  | //|  |//|  |/|  |///  ///\  \///|  |////
////|__________|//|__|///|__|//|__|/|__|//__/////\__\//|__|////
///////////////////////////////////////////////////////////////
/*
	BraXi's Death Run Mod
	(c) 2010-2020 Paulina Sokolowska

	https://www.moddb.com/mods/braxs-death-run-mod

	Twitter: https://twitter.com/TheBraXi
	GitHub: https://github.com/BraXi/

	E-mail: paulinabraxi somewhere at gmail.com
*/

/*********** MAPVOTING ***********

	Name: DMS
	Author: Bipo
	Design: Mr-X
	Desc: Dynamic Mapvoting Script
	Date: Feb. 2011

All rights reserved iNext Gaming
**********************************/


#include braxi\_common;

init()
{
	level.mapvote = 0;

	precacheString( &"MAPVOTE_PRESSFIRE" );
	precacheString( &"MAPVOTE_WAIT4VOTES" );
}

startMapvote()
{
	if( !level.dvar["mapvote"] )
		return;

	level notify("pre_mapvote");
	mapList = retrieveMaps(1);
	level.maps = getRandomSelection(mapList, 5, getdvar("mapname"));
	level.mapvote = 1;
	level notify("mapvote");
	level.mapitems = 3;
	beginVoting( level.dvar["mapvote_time"] );
	level notify("post_mapvote");
	wait 1;
	delVisuals();
}

changeMap( map )
{
	setDvar( "sv_maprotationcurrent", "gametype deathrun map " + map.mapname );
	exitLevel(false);
}

retrieveMaps(useMaprotation) {
	if (useMaprotation) {
		return getMaprotation();
	}
	return [];
}

getRandomSelection(mapList, no, illegal) {
	if (no>=mapList.size) {
		return mapList;
	}

	randomValues = [];
	for (i=0; i < mapList.size; i++)
	{
		if (isdefined(illegal)) {
			if (isLegal(mapList[i].mapname, illegal))
			randomValues[randomValues.size] = i;
		} else {
			randomValues[randomValues.size] = i;
		}
	}

	size = randomValues.size;
	maps = [];

	if (size <= no) {
		for (i=0; i<randomValues.size; i++)
		maps += mapList[randomValues[i]];
		return maps;
	}

	for (i=0; i<no; i++)
	{
		rI = randomint(size);
		maps[i] = mapList[randomValues[rI]];
		for (ii = rI; ii < size - 1; ii++)
		{
			randomValues[ii] = randomValues[ii + 1];
		}
		size = size - 1;
	}

	return maps;
}

isLegal(name, illegal) {
	if (!isString(illegal)) {
		for (i=0; i<illegal.size; i++) {
			if (illegal[i].mapname == name)
			return false;
		}
	}
	else if (name == illegal)
	return false;

	return true;
}

getMaprotation()
{
	maprotation = [];
	index = 0;
	dissect_sv_rotation = strtok(getdvar("sv_maprotation"), " ");

	gametype = 0;
	map = 0;
	nextgametype = "";
	for (i=0; i<dissect_sv_rotation.size; i++)
	{
		if (!map)
		{
			if (dissect_sv_rotation[i] == "gametype")
			{
				gametype = 1;
				continue;
			}
			if (gametype)
			{
				gametype = 0;
				nextgametype = dissect_sv_rotation[i];
				continue;
			}
			if (dissect_sv_rotation[i] == "map")
			{
				map = 1;
				continue;
			}
		}
		else
		{
			maprotation[index] = addMapItem(dissect_sv_rotation[i], nextgametype);
			index += 1;
			map = 0;
		}
	}
	return maprotation;
}

addMapItem(mapname, gametype) {
	map = spawnstruct();
	if (mapname=="")
	return;
	if (!isdefined(gametype))
	gametype = getdvar("g_gametype");
	if (gametype=="")
	gametype = getdvar("g_gametype");

	map.mapname = mapname;
	map.visname = braxi\_maps::getMapNameString(mapname);

	map.gametype = gametype;
	map.votes = 0;
	return map;
}


beginVoting(time) {
	level.voteswitchtime = .3;
	level.voteavg = int((level.mapitems+1)/2);
	level.votesup = level.mapitems - level.voteavg;

	createVisuals();
	level.votingplayers = getAllPlayers();
	for (i=0; i<level.votingplayers.size; i++) {
		level.votingplayers[i] thread playerVote();
	}

	level thread updateWinningMap();

	wait time;
}

playerVote() {
	level endon("post_mapvote");
	self endon("disconnect");

	self.voteindex = -1;

	// Fix: kick bots cleanly to avoid ghost entries in level.votingplayers
	if ( issubstr(self.name, "bot") )
	{
		self thread braxi\_mod::kickAfterTime( 0.1 );
		return;
	}

	self.changingVote = false;

	self playerVisuals();
	self thread playerUpdateVotes();
	self playerStartVoting();

	self closeMenu();
	self closeInGameMenu();

	abp = false;
	ads = self adsbuttonpressed();
	while(1) {
		if (ads != self adsbuttonpressed()) {
			ads = self adsbuttonpressed();
			// Only dec on press (ads became true), not on release
			if (ads) {
				self.changingVote = true;
				self decVote();
				wait level.voteswitchtime;
				self.changingVote = false;
			}
		}
		if (!abp) {
			if (self attackbuttonpressed()) {
				abp = true;
			}
		} else {
			self.changingVote = true;
			self incVote();
			wait level.voteswitchtime;
			self.changingVote = false;
			if (!self attackbuttonpressed()) {
				abp = false;
			}
		}
		wait 0.05;
	}
}

playerUpdateVotes() {
	level endon("post_mapvote");
	self endon("disconnect");
	while (1) {
		if (!self.changingVote)
		updateVotes();
		wait 0.5;
	}
}

playerStartVoting() {
	level endon("post_mapvote");
	self endon("disconnect");

	// "Press fire to vote" prompt - centered on screen
	self.startvote = newClientHudElem(self);
	self.startvote.x = 0;
	self.startvote.y = -70;
	self.startvote.elemType = "font";
	self.startvote.alignX = "center";
	self.startvote.alignY = "middle";
	self.startvote.horzAlign = "center";
	self.startvote.vertAlign = "middle";
	self.startvote.color = (0.55, 0.55, 0.65);
	self.startvote.alpha = 1;
	self.startvote.sort = 2;
	self.startvote.font = "default";
	self.startvote.fontScale = 1.6;
	self.startvote.foreground = true;
	self.startvote.label = &"MAPVOTE_PRESSFIRE";

	while(!self attackbuttonpressed()) {
		wait 0.05;
	}

	self.voteindex = 0;
	changeVotes(0, 1);
	updateVotes();

	self.startvote FadeOverTime(0.5);
	self.startvote.alpha = 0;

	wait 0.5;

	self.startvote destroy();
}

playerVisuals() {
	self setclientdvar("ui_hud_hardcore", 1);

	// BraX
	self braxi\_mod::spawnSpectator( level.spawn["spectator"].origin, level.spawn["spectator"].angles );

	self allowSpectateTeam( "allies", false );
	self allowSpectateTeam( "axis", false );
	self allowSpectateTeam( "freelook", false );
	self allowSpectateTeam( "none", true );

	// Fixed list - one row per map, no scrolling
	for (i=0; i<level.maps.size; i++ ) {
		self.voteitem[i] = newClientHudElem(self);
		self.voteitem[i].index = i;
		self.voteitem[i].x = getX();
		self.voteitem[i].y = getY(i);
		self.voteitem[i].elemType = "font";
		self.voteitem[i].alignX = "left";
		self.voteitem[i].alignY = "middle";
		self.voteitem[i].horzAlign = "center";
		self.voteitem[i].vertAlign = "middle";
		// Row 0 starts selected
		if (i == 0) {
			self.voteitem[i].color = (1, 1, 1);
			self.voteitem[i].alpha = 1;
		} else {
			self.voteitem[i].color = (0.65, 0.65, 0.75);
			self.voteitem[i].alpha = 0.85;
		}
		self.voteitem[i].sort = 2;
		self.voteitem[i].font = "default";
		self.voteitem[i].fontScale = 1.6;
		self.voteitem[i].foreground = true;
		self.voteitem[i] setText(level.maps[i].visname);

		// Vote count - right side of row
		self.voteitem[i].votes = newClientHudElem(self);
		self.voteitem[i].votes.index = i;
		self.voteitem[i].votes.x = getVotesX();
		self.voteitem[i].votes.y = getY(i);
		self.voteitem[i].votes.elemType = "font";
		self.voteitem[i].votes.alignX = "right";
		self.voteitem[i].votes.alignY = "middle";
		self.voteitem[i].votes.horzAlign = "center";
		self.voteitem[i].votes.vertAlign = "middle";
		if (i == 0) {
			self.voteitem[i].votes.color = (0.35, 0.75, 1.0);
			self.voteitem[i].votes.alpha = 1;
		} else {
			self.voteitem[i].votes.color = (0.35, 0.55, 0.75);
			self.voteitem[i].votes.alpha = 0.75;
		}
		self.voteitem[i].votes.sort = 2;
		self.voteitem[i].votes.font = "default";
		self.voteitem[i].votes.fontScale = 1.6;
		self.voteitem[i].votes.foreground = true;
		self.voteitem[i].votes.value = level.maps[i].votes;
		self.voteitem[i].votes setValue(level.maps[i].votes);
	}

	// Highlight bar - only this moves when player scrolls
	self.selectbar = newClientHudElem(self);
	self.selectbar.x = -110;
	self.selectbar.y = getY(0) - 1;
	self.selectbar.width = 220;
	self.selectbar.height = getRowHeight();
	self.selectbar.alignX = "left";
	self.selectbar.alignY = "middle";
	self.selectbar.horzAlign = "center";
	self.selectbar.vertAlign = "middle";
	self.selectbar.color = (0.2, 0.5, 1.0);
	self.selectbar.alpha = 0.35;
	self.selectbar.sort = 1;
	self.selectbar.foreground = false;
	self.selectbar setShader("white", self.selectbar.width, self.selectbar.height);
}

playerDelVisuals() {
	self endon("disconnect");

	// Guard against players who never had visuals created
	// (bots, late-joiners, disconnected players)
	for (i=0; i<level.maps.size; i++ )
	{
		if (!isdefined(self.voteitem[i]))
			continue;

		self.voteitem[i] FadeOverTime(1);
		self.voteitem[i].alpha = 0;

		if (isdefined(self.voteitem[i].votes))
		{
			self.voteitem[i].votes FadeOverTime(1);
			self.voteitem[i].votes.alpha = 0;
		}
	}

	if (isdefined(self.selectbar)) {
		self.selectbar FadeOverTime(1);
		self.selectbar.alpha = 0;
	}

	if (isdefined(self.startvote))
		self.startvote destroy();

	wait 1;

	for (i=0; i<level.maps.size; i++ ) {
		if (!isdefined(self.voteitem[i]))
			continue;
		if (isdefined(self.voteitem[i].votes))
			self.voteitem[i].votes destroy();
		self.voteitem[i] destroy();
	}

	if (isdefined(self.selectbar))
		self.selectbar destroy();
}


getIndex(i) {
	if (i>=level.maps.size)
	return int(i-level.maps.size);
	if (i<0)
	return int(level.maps.size + i);
	return int(i);
}

updateVotes() {
	for (i=0; i<level.maps.size; i++ ) {
		val = level.maps[i].votes;
		if (val != self.voteitem[i].votes.value) {
			self.voteitem[i].votes.value = val;
			self.voteitem[i].votes setValue(val);
		}
	}
}

incVote() {
	changeVotes(self.voteindex, -1);

	// Dim the old selected row
	self.voteitem[self.voteindex].color = (0.65, 0.65, 0.75);
	self.voteitem[self.voteindex].alpha = 0.85;
	self.voteitem[self.voteindex].votes.color = (0.35, 0.55, 0.75);
	self.voteitem[self.voteindex].votes.alpha = 0.75;

	self.voteindex++;
	if (self.voteindex >= level.maps.size)
		self.voteindex = 0;

	changeVotes(self.voteindex, 1);
	updateVotes();

	// Highlight the new selected row
	self.voteitem[self.voteindex].color = (1, 1, 1);
	self.voteitem[self.voteindex].alpha = 1;
	self.voteitem[self.voteindex].votes.color = (0.35, 0.75, 1.0);
	self.voteitem[self.voteindex].votes.alpha = 1;

	// Slide the selection bar to the new row
	self.selectbar MoveOverTime(level.voteswitchtime);
	self.selectbar.y = getY(self.voteindex) - 1;
}

decVote() {
	changeVotes(self.voteindex, -1);

	// Dim the old selected row
	self.voteitem[self.voteindex].color = (0.65, 0.65, 0.75);
	self.voteitem[self.voteindex].alpha = 0.85;
	self.voteitem[self.voteindex].votes.color = (0.35, 0.55, 0.75);
	self.voteitem[self.voteindex].votes.alpha = 0.75;

	self.voteindex -= 1;
	if (self.voteindex < 0)
		self.voteindex = level.maps.size - 1;

	changeVotes(self.voteindex, 1);
	updateVotes();

	// Highlight the new selected row
	self.voteitem[self.voteindex].color = (1, 1, 1);
	self.voteitem[self.voteindex].alpha = 1;
	self.voteitem[self.voteindex].votes.color = (0.35, 0.75, 1.0);
	self.voteitem[self.voteindex].votes.alpha = 1;

	// Slide the selection bar to the new row
	self.selectbar MoveOverTime(level.voteswitchtime);
	self.selectbar.y = getY(self.voteindex) - 1;
}

changeVotes(index, dif) {
	if (index==-1)
	return;

	level.maps[index].votes += dif;
}



getRowHeight() {
	// Content area: from separator (y=-56) to footer bar (y=82) = 138px
	// Divide evenly among all maps
	return int(138 / level.maps.size);
}

getX() {
	// Left edge of panel is -110 from screen center; 6px inner padding = -104
	return -104;
}

getY(i) {
	// Content area starts at -56, rows spaced evenly
	// Centre text vertically in its row slot
	rh = getRowHeight();
	return -56 + (i * rh) + int(rh / 2);
}

getVotesX() {
	// Right edge of panel is +110 from center; 6px inner padding = +104
	return 104;
}


createVisuals() {
	// -------------------------------------------------------
	// NEX'S DEATHRUN - Jiggy-style Vertical Map Vote Panel
	//
	//  y=0   : panel top
	//  y=0   : title "Nex's Deathrun"  (large, coloured)
	//  y=26  : subtitle "by Nex"  (small, dim)
	//  y=38  : cyan divider line
	//  y=40  : "Vote for next map" section label
	//  y=56  : thin dim separator
	//  y=68+ : map rows (uniform, 18px each)
	//  bot   : thin cyan line + winning map footer
	// -------------------------------------------------------

	// Main panel background
	level.blackbg = newHudElem();
	level.blackbg.x = -110;
	level.blackbg.y = -118;
	level.blackbg.width = 220;
	level.blackbg.height = 200;
	level.blackbg.alignX = "left";
	level.blackbg.alignY = "top";
	level.blackbg.horzAlign = "center";
	level.blackbg.vertAlign = "middle";
	level.blackbg.color = (0.06, 0.06, 0.10);
	level.blackbg.alpha = 0.92;
	level.blackbg.sort = -3;
	level.blackbg.foreground = false;
	level.blackbg setShader("white", level.blackbg.width, level.blackbg.height);

	// Title bar background (slightly lighter strip)
	level.blackbgtop = newHudElem();
	level.blackbgtop.x = -110;
	level.blackbgtop.y = -118;
	level.blackbgtop.width = 220;
	level.blackbgtop.height = 38;
	level.blackbgtop.alignX = "left";
	level.blackbgtop.alignY = "top";
	level.blackbgtop.horzAlign = "center";
	level.blackbgtop.vertAlign = "middle";
	level.blackbgtop.color = (0.08, 0.08, 0.16);
	level.blackbgtop.alpha = 0.97;
	level.blackbgtop.sort = -2;
	level.blackbgtop.foreground = false;
	level.blackbgtop setShader("white", level.blackbgtop.width, level.blackbgtop.height);

	// Title: "Nex's Deathrun"
	level.servertitle = newHudElem();
	level.servertitle.x = 0;
	level.servertitle.y = -105;
	level.servertitle.elemType = "font";
	level.servertitle.alignX = "center";
	level.servertitle.alignY = "middle";
	level.servertitle.horzAlign = "center";
	level.servertitle.vertAlign = "middle";
	level.servertitle.color = (0.35, 0.75, 1.0);
	level.servertitle.alpha = 1;
	level.servertitle.sort = 1;
	level.servertitle.font = "objective";
	level.servertitle.fontScale = 1.7;
	level.servertitle.foreground = true;
	level.servertitle setText("Nex's Deathrun");

	// Subtitle: "by Nex"
	level.serversub = newHudElem();
	level.serversub.x = 0;
	level.serversub.y = -91;
	level.serversub.elemType = "font";
	level.serversub.alignX = "center";
	level.serversub.alignY = "middle";
	level.serversub.horzAlign = "center";
	level.serversub.vertAlign = "middle";
	level.serversub.color = (0.4, 0.4, 0.55);
	level.serversub.alpha = 1;
	level.serversub.sort = 1;
	level.serversub.font = "default";
	level.serversub.fontScale = 1.4;
	level.serversub.foreground = true;
	level.serversub setText("by Nex");

	// Cyan divider below title
	level.blackbartop = newHudElem();
	level.blackbartop.x = -110;
	level.blackbartop.y = -80;
	level.blackbartop.width = 220;
	level.blackbartop.height = 2;
	level.blackbartop.alignX = "left";
	level.blackbartop.alignY = "top";
	level.blackbartop.horzAlign = "center";
	level.blackbartop.vertAlign = "middle";
	level.blackbartop.color = (0.2, 0.6, 1.0);
	level.blackbartop.alpha = 1;
	level.blackbartop.sort = -1;
	level.blackbartop.foreground = false;
	level.blackbartop setShader("white", level.blackbartop.width, level.blackbartop.height);

	// "Vote for next map" section label
	level.sectionlabel = newHudElem();
	level.sectionlabel.x = 0;
	level.sectionlabel.y = -68;
	level.sectionlabel.elemType = "font";
	level.sectionlabel.alignX = "center";
	level.sectionlabel.alignY = "middle";
	level.sectionlabel.horzAlign = "center";
	level.sectionlabel.vertAlign = "middle";
	level.sectionlabel.color = (0.55, 0.55, 0.70);
	level.sectionlabel.alpha = 1;
	level.sectionlabel.sort = 1;
	level.sectionlabel.font = "default";
	level.sectionlabel.fontScale = 1.4;
	level.sectionlabel.foreground = true;
	level.sectionlabel setText("Vote for next map");

	// Thin separator below section label
	level.blackbar = newHudElem();
	level.blackbar.x = -110;
	level.blackbar.y = -56;
	level.blackbar.width = 220;
	level.blackbar.height = 1;
	level.blackbar.alignX = "left";
	level.blackbar.alignY = "top";
	level.blackbar.horzAlign = "center";
	level.blackbar.vertAlign = "middle";
	level.blackbar.color = (0.2, 0.2, 0.3);
	level.blackbar.alpha = 1;
	level.blackbar.sort = -1;
	level.blackbar.foreground = false;
	level.blackbar setShader("white", level.blackbar.width, level.blackbar.height);

	// Footer background (winning map strip at bottom)
	level.footerbg = newHudElem();
	level.footerbg.x = -110;
	level.footerbg.y = 82;
	level.footerbg.width = 220;
	level.footerbg.height = 36;
	level.footerbg.alignX = "left";
	level.footerbg.alignY = "top";
	level.footerbg.horzAlign = "center";
	level.footerbg.vertAlign = "middle";
	level.footerbg.color = (0.08, 0.08, 0.16);
	level.footerbg.alpha = 0.97;
	level.footerbg.sort = -2;
	level.footerbg.foreground = false;
	level.footerbg setShader("white", level.footerbg.width, level.footerbg.height);

	// Cyan line above footer
	level.footerbar = newHudElem();
	level.footerbar.x = -110;
	level.footerbar.y = 82;
	level.footerbar.width = 220;
	level.footerbar.height = 2;
	level.footerbar.alignX = "left";
	level.footerbar.alignY = "top";
	level.footerbar.horzAlign = "center";
	level.footerbar.vertAlign = "middle";
	level.footerbar.color = (0.2, 0.6, 1.0);
	level.footerbar.alpha = 0.9;
	level.footerbar.sort = -1;
	level.footerbar.foreground = false;
	level.footerbar setShader("white", level.footerbar.width, level.footerbar.height);

	// "WINNING MAP:" label
	level.winningtxt = newHudElem();
	level.winningtxt.x = 0;
	level.winningtxt.y = 92;
	level.winningtxt.elemType = "font";
	level.winningtxt.alignX = "center";
	level.winningtxt.alignY = "middle";
	level.winningtxt.horzAlign = "center";
	level.winningtxt.vertAlign = "middle";
	level.winningtxt.color = (0.45, 0.45, 0.6);
	level.winningtxt.alpha = 1;
	level.winningtxt.sort = 1;
	level.winningtxt.font = "default";
	level.winningtxt.fontScale = 1.4;
	level.winningtxt.foreground = true;
	level.winningtxt setText("Winning Map:");

	// Winning map name
	level.winningmap = newHudElem();
	level.winningmap.x = 0;
	level.winningmap.y = 106;
	level.winningmap.elemType = "font";
	level.winningmap.alignX = "center";
	level.winningmap.alignY = "middle";
	level.winningmap.horzAlign = "center";
	level.winningmap.vertAlign = "middle";
	level.winningmap.color = (1, 1, 1);
	level.winningmap.alpha = 1;
	level.winningmap.sort = 1;
	level.winningmap.font = "default";
	level.winningmap.fontScale = 1.6;
	level.winningmap.foreground = true;
	level.winningmap.glowcolor = (0.2, 0.6, 1.0);
	level.winningmap.glowalpha = 0.7;
	level.winningmap.label = &"MAPVOTE_WAIT4VOTES";
	level.winningmap setText("");
}

delVisuals() {
	for (i=0; i<level.votingplayers.size; i++) {
		if (isdefined(level.votingplayers[i])) {
			level.votingplayers[i] thread playerDelVisuals();
		}
	}

	level.blackbg fadeovertime(1);
	level.blackbgtop fadeovertime(1);
	level.blackbar fadeovertime(1);
	level.blackbartop fadeovertime(1);
	level.footerbg fadeovertime(1);
	level.footerbar fadeovertime(1);
	level.servertitle fadeovertime(1);
	level.serversub fadeovertime(1);
	level.sectionlabel fadeovertime(1);
	level.winningtxt fadeovertime(2);
	level.winningmap fadeovertime(2);

	level.blackbg.alpha = 0;
	level.blackbgtop.alpha = 0;
	level.blackbar.alpha = 0;
	level.blackbartop.alpha = 0;
	level.footerbg.alpha = 0;
	level.footerbar.alpha = 0;
	level.servertitle.alpha = 0;
	level.serversub.alpha = 0;
	level.sectionlabel.alpha = 0;
	level.winningtxt.alpha = 0;
	level.winningmap.alpha = 0;

	wait 2;

	level.blackbg destroy();
	level.blackbgtop destroy();
	level.blackbar destroy();
	level.blackbartop destroy();
	level.footerbg destroy();
	level.footerbar destroy();
	level.servertitle destroy();
	level.serversub destroy();
	level.sectionlabel destroy();
	level.winningtxt destroy();
	level.winningmap destroy();
}


updateWinningMap() {
	level endon("post_mapvote");
	while (1) {
		mostvotes = level.maps[0].votes;
		lastindex = 0;
		for (i=1; i<level.maps.size; i++) {
			if (level.maps[i].votes > mostvotes) {
				mostvotes = level.maps[i].votes;
				lastindex = i;
			}
		}

		if (mostvotes != 0) {
			level.winningmap.label = &"";
			level.winningmap setText(level.maps[lastindex].visname);
		}

		wait 0.5;
	}
}

getWinningMap() {
	mostvotes = level.maps[0].votes;
	lastindex = 0;
	for (i=1; i<level.maps.size; i++) {
		if (level.maps[i].votes > mostvotes) {
			mostvotes = level.maps[i].votes;
			lastindex = i;
		}
	}
	return level.maps[lastindex];
}
