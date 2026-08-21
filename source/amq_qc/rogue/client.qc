/*
Code fixes:

[client.qc] Respawn velocity fix
[client.qc] "NoExit" SP/Coop fix
[client.qc] "NoExit" without dying (recognizing "noexit" 3/4)
[client.qc] Support for new DOPA episode ending text
[client.qc] Swimming up with +jump now as fast as +forward and looking up
[client.qc] New episode fix
[client.qc] Respawning where player died fix
[client.qc] Fraglimit/timelimit fix
[client.qc] Ghost eyes and hovering bodies fix (fixing client disconnect)
[client.qc] Incorrect frag sentence when a player disconnects fix (frag/frags)
[client.qc] Samelevel fix (recognizing "samelevel" only in DM)
[client.qc] Player drops backpack on suicide (using "Killed()" function on suicide)
[client.qc] [defs.qc] Shooting/jumping when respawning fix
[client.qc] [triggers.qc] Pentagram telefrag fix
[client.qc] [world.qc] Fix for losing runes under certain conditions
[client.qc] [defs.qc] [items.qc] Better performance in powerups handling
[client.qc] [combat.qc] [defs.qc] [items.qc] [lava_wpn.qc] [mult_wpn.qc] [weapons.qc] [world.qc] Deathmatch modes 3-5 (set CVAR "savedgamecfg" to "1" for axe-only in DM4)
[client.qc] [boss.qc] [demon.qc] [dog.qc] [misc.qc] [monsters.qc] [oldone.qc] [tarbaby.qc] Sliding/not-jumping on monsters/boxes/players fix
*/

// updated to quake v1.06 10/8/96

// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

void(entity targ, entity attacker) dmatch_score;

// float modelindex_eyes, modelindex_player; // Better performance in powerups handling

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float intermission_running, intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};

// Fix for losing runes when restarting START
float reset_flag;

void() SetChangeParms =
{
	// if (self.health <= 0)
        if (reset_flag)
	{
		// SetNewParms ();
		setspawnparms(self);
                parm14 = self.steam;	// Save the current team of the player
		return;
	}
// Fix for losing runes when restarting END

// remove items
	self.items = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_INVISIBILITY) );							
	self.items2 = self.items2 - (self.items2 & (IT2_ANTIGRAV | IT2_SHIELD | IT2_SUPERHEALTH));
	self.gravity = 1.0;

// Deathmatch modes 3-5 START
	if (!(self.items & IT_AXE))
		self.items = self.items | IT_AXE;
	if (!(self.items & IT_SHOTGUN))
		self.items = self.items | IT_SHOTGUN;
// Deathmatch modes 3-5 END
		
// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;

	teamplay = cvar ( "teamplay" );
	if (teamplay >= TEAM_CTF)	// don't carry items between levels in CTF
		SetNewParms();
	else 
	{
		parm1 = self.items;
		parm2 = self.health;
		parm3 = self.armorvalue;
		if (self.ammo_shells1 < 25)
			parm4 = 25;
		else
			parm4 = self.ammo_shells1;
		parm5 = self.ammo_nails1;
		parm6 = self.ammo_rockets1;
		parm7 = self.ammo_cells1;
// Deathmatch modes 3-5 START
		if (self.weapon == IT_AXE)
			self.weapon = IT_SHOTGUN;
// Deathmatch modes 3-5 END
		parm8 = self.weapon;
		parm9 = self.armortype * 100;
		parm10 = self.items2;
		parm11 = self.ammo_lava_nails;
		parm12 = self.ammo_multi_rockets;
		parm13 = self.ammo_plasma;
	}
	parm14 = self.steam; // save team setting
};

void() SetNewParms =
{
//ZOID--
	if (deathmatch && teamplay >= TEAM_CTF) {
		parm1 = IT_SHOTGUN | IT_AXE | IT_GRAPPLE;
		parm10 = IT2_ARMOR1;
		parm3 = 50;
		parm9 = 30;
	} else {
		parm1 = IT_SHOTGUN | IT_AXE;
		parm3 = 0;
		parm9 = 0;
		parm10 = 0;
	}
//--ZOID
	parm2 = 100;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm11 = 0;
	parm12 = 0;
	parm13 = 0;
//ZOID--
	parm14 = -1; 		// CTF: reset current team selection
//--ZOID
};

void() DecodeLevelParms =
{
	if (!deathmatch)
	{
		if (world.model == "maps/start.bsp")
			SetNewParms ();		// take away all stuff on starting new episode
	}
	if (world.model == "maps/r2m1.bsp" && !deathmatch)
		SetNewParms ();
	// PGM - 01/29 change to have level 8 reset all your stuff.
	
	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells1 = parm4;
	self.ammo_nails1 = parm5;
	self.ammo_rockets1 = parm6;
	self.ammo_cells1 = parm7;
	// cute bug, if grapple was selected, it still will be on level change
	if (parm8 == IT_GRAPPLE && teamplay < TEAM_CTF)
		self.weapon = IT_AXE;
	else
		self.weapon = parm8;
	self.armortype = parm9 * 0.01;
	self.items2 = parm10;
	self.ammo_lava_nails = parm11;
	self.ammo_multi_rockets = parm12;
	self.ammo_plasma = parm13;
//ZOID--
	if (TeamColorIsLegal(parm14)) {
		self.steam = parm14;
		TeamSetSkin();
	}
//--ZOID
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;
	
// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;
	
	objerror ("FindIntermission: no spot");
	return world;	// Avoid warnings with FrikQCC by NightFright
};


string nextmap;
void() GotoNextMap =
{
// Samelevel fix START
	if (deathmatch)
	{
// Samelevel fix END
		if (cvar("samelevel"))	// if samelevel is set, stay on same level
        	{ // Samelevel fix
			changelevel (mapname);
// Samelevel fix START
			return;
		}
	}
	// else
// Samelevel fix END
		changelevel (nextmap);
};

void() ExitIntermission =
{
// skip any text in deathmatch
	if (deathmatch)
	{
		GotoNextMap ();
		return;
	}
	
	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
	if (intermission_running == 2)
	{
		if (world.model == "maps/e1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);
			if (!cvar("registered"))
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!");
			}
			else
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
			}
			return;
		}
		else if (world.model == "maps/e2m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
			return;
		}
		else if (world.model == "maps/e3m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
			return;
		}
		else if (world.model == "maps/e4m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
			return;
		}

		else if (world.model == "maps/r1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Victory! The Overlord's mangled\nremains are the evidence.  His evil\nWrath army?  Cast out to wander\naimlessly throughout time.\n\nAs the Slipgate fog surrounds you,\nthoughts rage into your consciousness:\nHas Quake's oppressive reign ended?\nIs it Salvation, or Damnation, which\nwaits beyond the Vortex?\n\nAnother thought, not quite your own,\nrazors through the haze.  \"Forgiveness\ncan yet be granted; Our Master remains\nto absolve your sins against his Chosen.\nFall down upon your knees-pray for\nQuake's mercy.\"");
			return;
		}
		GotoNextMap();
	}
	
	if (intermission_running == 3)
	{
		if (!cvar("registered"))
		{	// shareware episode has been completed, go to sell screen
			WriteByte (MSG_ALL, SVC_SELLSCREEN);
			return;
		}
		
		if ( (serverflags&15) == 15)
		{
			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
			return;
		}
		
	}

	GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;
	
	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;
	
// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);
	
	pos = FindIntermission ();

	other = find (world, classname, "player");
	while (other != world)
	{
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		setorigin (other, pos.origin);
		other = find (other, classname, "player");
	}	

	WriteByte (MSG_ALL, SVC_INTERMISSION);
};


void() changelevel_touch =
{
	// local entity	pos;

	if (other.classname != "player")
		return;

// NoExit SP/Coop fix START
	if (deathmatch)
	{
// NoExit SP/Coop fix END
		if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
		{
			T_Damage (other, self, self, 50000);
			return;
		}
// Noexit without dying fix START
		if ((cvar("noexit") == 3) || ((cvar("noexit") == 4) && (mapname != "start")))
			return;
// Noexit without dying fix END
	} // NoExit SP/Coop fix

	if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}
	
	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
	{	// NO_INTERMISSION
		GotoNextMap();
		return;
	}
	
	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("changelevel trigger doesn't have map");
	
	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn		
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn		
		PutClientInServer ();
		// set the skin correctly.
		TeamSetSkin();
	}
	else
	{	
		// restart the entire server
// Fix for losing runes when restarting START
		// localcmd ("restart\n");         // no longer used; we use "changelevel" instead
		serverflags = startingserverflags; // put serverflags back to map's initial setting
		reset_flag = TRUE;                 // request a reset to the parms
		localcmd ("changelevel ");         // "change" to the same level
		localcmd(mapname);
		localcmd("\n");
// Fix for losing runes when restarting END
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	local entity	vSphere;

// ZOID--
	if (self.suicide_count > 3)
	{
		sprint(self, "You have suicided too much already.\n");
		return;
	}
    TeamDropFlagOfPlayer(self);
	self.suicide_count = self.suicide_count + 1;
// --ZOID

	if ( tag_token_owner == self)
	{
		self.health = 0;
		self.solid = SOLID_NOT;
		tag_token_drop();
	}

	if ( self.items2 & IT2_V_SPHERE)
	{
		vSphere = find ( world, classname, "Vengeance");
		while (vSphere)
		{
			if ( vSphere.owner == self )
				remove (vSphere);
			vSphere = find(vSphere, classname, "Vengeance");
		}
	}

// Player drops backpack on suicide START
/*
	bprint (self.netname);
	bprint (" suicides\n");
	set_suicide_frame ();
	self.modelindex = modelindex_player;
	self.frags = self.frags - 2;	// extra penalty
	respawn ();
*/
	self.deathtype = "suicide";
	self.health = 0;
	Killed(self,self);
// Player drops backpack on suicide END
};

float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local	entity	spot;
	local	entity 	thing;
	local	float	pcount;
//ZOID--
	local	entity	startspot;
	local	float	t;
//--ZOID
	
// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;
		
// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		startspot = spot = lastspawn;
		t = 0;
		if (!self.ctf_killed && teamplay >= TEAM_CTF)
		{
			if (self.steam == TEAM1)
			{
				startspot = spot = team1_lastspawn;
				t = TEAM1;
			} 
			else if (self.steam == TEAM2)
			{
				startspot = spot = team2_lastspawn;
				t = TEAM2;
			}
		}
		
		while (1)
		{
			if (t == TEAM1)
				spot = find(spot, classname, "info_player_team1");
			else if (t == TEAM2)
				spot = find(spot, classname, "info_player_team2");
			else
				spot = find(spot, classname, "info_player_deathmatch");

			if (spot != world)
			{
				if (spot == startspot)
					return startspot;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					if (t == TEAM1)
						team1_lastspawn = spot;
					else if (t == TEAM2)
						team2_lastspawn = spot;
					else
						lastspawn = spot;
					return spot;
				}
			}
			else				
				t = 0;
			// pgm fix for ctf in levels w/o ctf support
		}
	}

	if (serverflags)
	{	// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}
	
	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");
	
	return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;
void() monster_touch;		// 1998-09-16 Sliding/not-jumping on monsters/boxes/players fix by Maddes/Kryten

void() player_touch;

void() PutClientInServer =
{
	local	entity spot;

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	self.shield_finished = 0;
	self.antigrav_finished = 0;
		
//ZOID--
	self.ctf_lastreturnedflag = -10;
	self.ctf_lastfraggedcarrier = -10;
	self.ctf_flagsince = -10;
	self.ctf_lasthurtcarrier = -10;
//--ZOID

	DecodeLevelParms ();

	// spawn selection must be after DecodeLevelParms because of team stuff
	spot = SelectSpawnPoint ();

// Deathmatch modes 3-5 START
	if (deathmatch == 4)
	{
		self.ammo_shells = 0;
		self.ammo_nails = 0;
		self.ammo_rockets = 0;
		self.ammo_cells = 0;
		self.ammo_lava_nails = 0;
		self.ammo_multi_rockets = 0;
		self.ammo_plasma = 0;
		self.items = self.items - (self.items & (IT_SHOTGUN | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_LIGHTNING));	
		if (axeonly) // axe-only match
			self.weapon = IT_AXE;
		else
		{ 
			self.ammo_shells = 255;
			self.ammo_nails = 255;
			self.ammo_rockets = 255;
			self.ammo_cells = 255;
			self.ammo_lava_nails = 255;
			self.ammo_multi_rockets = 255;
			self.ammo_plasma = 255;
			self.items = self.items | IT_SHOTGUN;
			self.items = self.items | IT_SUPER_SHOTGUN;
			self.items = self.items | IT_NAILGUN;
			self.items = self.items | IT_SUPER_NAILGUN;
			self.items = self.items | IT_GRENADE_LAUNCHER;
			self.items = self.items | IT_ROCKET_LAUNCHER;
			self.items = self.items | IT_LIGHTNING;
		}
		self.items = self.items - (self.items & (IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3)) + IT2_ARMOR3;
		self.armorvalue = 200;
		self.armortype = 0.8;
		self.health = 250;
		self.items = self.items | IT_INVULNERABILITY;
		self.invincible_time = 1;
		self.invincible_finished = time + 3;
	}

	if (deathmatch == 5)
	{
		self.ammo_nails = 80;
		self.ammo_shells = 30;
		self.ammo_rockets = 10;
		self.ammo_cells = 30;
		self.ammo_lava_nails = 80;
		self.ammo_multi_rockets = 10;
		self.ammo_plasma = 30;
		self.items = self.items | IT_SHOTGUN;
		self.items = self.items | IT_SUPER_SHOTGUN;
		self.items = self.items | IT_NAILGUN;
		self.items = self.items | IT_SUPER_NAILGUN;
		self.items = self.items | IT_GRENADE_LAUNCHER;
		self.items = self.items | IT_ROCKET_LAUNCHER;
		self.items = self.items | IT_LIGHTNING;
		self.items = self.items - (self.items & (IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3)) + IT2_ARMOR3;
		self.armorvalue = 200;
		self.armortype = 0.8;
		self.health = 200;
		self.items = self.items | IT_INVULNERABILITY;
		self.invincible_time = 1;
		self.invincible_finished = time + 3;
	}
// Deathmatch modes 3-5 END
	
	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = (void(entity,float)) player_pain;
	self.th_die = PlayerDie;
        self.touch = monster_touch;	// 1998-09-16 Sliding/not-jumping on monsters/boxes/players fix by Maddes/Kryten
	
	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;
	
//	spot = SelectSpawnPoint ();

	self.origin = self.oldorigin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	self.touch = player_touch;

// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	self.view_ofs = '0 0 22';
	self.velocity = '0 0 0';

	player_stand1 ();
	
	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	//Grapple stuff
	self.on_hook = FALSE;
	self.hook_out = FALSE;

	spawn_tdeath (self.origin, self);
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
	SpawnRunes();
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
*/
void() NextLevel =
{
	local entity o;

	if (mapname == "start")
	{
/*
		if (!cvar("registered"))
			mapname = "e1m1";
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
			serverflags = serverflags | 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
			serverflags = serverflags | 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
			serverflags = serverflags | 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
			serverflags = serverflags - 7;
		}
*/
		// PGM 03/02/97 - make it always go to rogue level1 when in our progs
		mapname = "r1m1";
		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;
	gameover = TRUE;
	
	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local float timelimit, fraglimit;
	
	if (gameover)	// someone else quit the game already
		return;
		
	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");
	
	if (deathmatch && timelimit && time >= timelimit)
	{
		NextLevel ();
		return;
	}
	
	if (deathmatch && fraglimit && self.frags >= fraglimit)
	{
		NextLevel ();
		return;
	}	

//ZOID--
	// update team scores? 
	TeamCheckUpdate();
//--ZOID
};

//============================================================================

void() PlayerDeathThink =
{
	// local entity	old_self;
	local float do_respawn; // 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin
	local float forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else	
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
        do_respawn = 0;	// 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin
	if (!self.button2 && !self.button1 && !self.button0)
// 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin  start
	{
		// Player wants to respawn ASAP
		if (self.deadflag == DEAD_WAITING)
		{
			centerprint (self, "");     // Erase button release message
			do_respawn = 1;
		}
		else
		{
// 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin  end
		return;
// 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin  start
		}
	}

	// In netgames, don't respawn as long as a button is held
	if (!do_respawn)
	{
		if (deathmatch || coop)
		{
			// Player wants to respawn ASAP.
			self.deadflag = DEAD_WAITING;

			// Message not necessary, but useful nonetheless.
			if (self.button0)
				centerprint (self, "Release attack to respawn");
			else if (self.button1)
				centerprint (self, "Release use to respawn");
			else if (self.button2)
				centerprint (self, "Release jump to respawn");
			return;
		}
	}
// 2001-08-31 Shooting/jumping when respawning fix by Patrick Martin  end

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};

/*
// Old player jump function
void() PlayerJump =
{
	// local vector start, end;
	
	if (self.flags & FL_WATERJUMP)
		return;
	
	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

// play swiming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	
	self.button2 = 0;
// player jumping sound
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};
*/

// New player jump function (from Copper) START
float(float a, float b) not = { return a - (a & b); }

void() PlayerJump =
{
	float upspeed;

	if (self.flags & FL_WATERJUMP)
		return;
	
	if (self.waterlevel >= 2)
	{
		// fix for +jump not swimming upward as fast as +moveup
		upspeed = cvar("cl_upspeed");
		if (self.waterlevel < 3)
			upspeed = upspeed * 0.5; // match vanilla swim values at surface so we don't launch out of the water any higher
		else
			upspeed = upspeed * 0.7; // match moveup from SV_WaterMove
		
		if (self.watertype == CONTENT_LAVA)
			upspeed = upspeed * 0.5; // originally 50
		else if (self.watertype == CONTENT_SLIME)
			upspeed = upspeed * 0.8; // originally 80
		
		// scale upspeed to match WaterMove since playerjump gets called after it
		self.velocity_z = upspeed - 0.8 * self.waterlevel * frametime * upspeed;
	
		// play swimming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}
		return;
	}

	if (self.movetype != MOVETYPE_NOCLIP)
	{
		if (!(self.flags & FL_ONGROUND)) return;
		if (!(self.flags & FL_JUMPRELEASED)) return; // don't pogo stick
		sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM); // h00rt
	}

	self.flags = not(self.flags, FL_JUMPRELEASED | FL_ONGROUND); // don't stairwalk
	
	self.button2 = 0;
	self.velocity_z = self.velocity_z + 270;
}
// New player jump function (from Copper) END

/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}
	
	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{	
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4*self.waterlevel);
		}
	}
	
	if ( !(self.flags & FL_INWATER) )
	{	

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}
	
	if (! (self.flags & FL_WATERJUMP) )
		self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	// local	float	mspeed, aspeed;
	// local	float	r;

	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}
		
	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	if (earthquake_active)
	{
		if ( self.flags & FL_ONGROUND )
		{
			self.velocity_x = self.velocity_x + 
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
			self.velocity_y = self.velocity_y + 
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
			self.velocity_z = self.velocity_z + 
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
		}
	}

	makevectors (self.v_angle);		// is this still used

//ZOID--
	// TeamCheckLock performs all necessary teamlock checking, and performs all
	// actions needed.
	TeamCheckLock();
//--ZOID

	CheckMOTD();
	CheckRules ();
	WaterMove ();

	if (self.waterlevel == 2)
		CheckWaterJump ();

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}
	
	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
		PlayerJump ();
	else
		self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time	
	if (time < self.pausetime)
		self.velocity = '0 0 0';
	
	if (self.items2 & IT2_ANTIGRAV)
	{
		if ( time > self.AGping )
		{
			sound ( self, CHAN_AUTO, "belt/use.wav", 0.4, ATTN_NORM);
			self. AGping = time + 3;
			if(self. AGping >= (self.antigrav_finished - 3))
				self. AGping = self.antigrav_finished + 3;
		}
	}

	RuneApplyElder(self); // regeneration rune 

	// Track the grapple
	if (self.hook_out)
		GrappleService();
};
	
/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}
			
			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
			self.modelindex = modelindex_player; // Better performance in powerups handling
		}
// Better performance in powerups handling START
/*
	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
*/
// Better performance in powerups handling END
	}
// Better performance in powerups handling START
/*
	else
		self.modelindex = modelindex_player;	// don't use eyes
*/
// Better performance in powerups handling END

// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}
			
			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
// Better performance in powerups handling START
			if (!self.super_damage_finished)
				self.effects = self.effects - (self.effects & EF_DIMLIGHT);
// Better performance in powerups handling END
		}
// Better performance in powerups handling START
/*
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
*/
// Better performance in powerups handling END
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
// Deathmatch modes 3-5 START
				if (deathmatch == 4)
					sprint (self, "OctaPower is wearing off\n");
				else
// Deathmatch modes 3-5 END
					sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}	  
			
			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
// Better performance in powerups handling START
			if (!self.invincible_finished)
				self.effects = self.effects - (self.effects & EF_DIMLIGHT);
// Better performance in powerups handling END
// Deathmatch modes 3-5 START
			if (deathmatch == 4)
			{
				if (!axeonly) // axe-only match
					self.ammo_cells = 255;
				self.armorvalue = 0;
				self.armortype = 0;
				self.items = self.items - (self.items & (IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3));
			}
// Deathmatch modes 3-5 END
		}
// Better performance in powerups handling START
/*
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
*/
// Better performance in powerups handling END
	}	

// suit	
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}
			
			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}	
	
	if(self.shield_finished)
	{
		if ( self.shield_finished < time + 3)
		{
			if (self.shield_time == 1)
			{
				sprint (self, "Shield failing...\n");
				sound (self, CHAN_AUTO, "shield/fadeout.wav", 1, ATTN_NORM);
				self.shield_time = 0;
			}
			if (self.shield_time < time)
			{
				self.shield_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if ( self.shield_finished < time)
		{
			sprint (self, "Shield lost.\n");
			self.shield_finished = 0;
			self.items2 = self.items2 - IT2_SHIELD;
		}
	}

	if(self.antigrav_finished)
	{
		if ( self.antigrav_finished < time + 3)
		{
			if (self.antigrav_time == 1)
			{
				sprint (self, "Antigrav failing...\n");
				self.antigrav_time = 0;
				sound (self, CHAN_AUTO, "belt/fadeout.wav", 1, ATTN_NORM);
			}
			if (self.antigrav_time < time)
			{
				self.antigrav_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if ( self.antigrav_finished < time)
		{
			sprint (self, "Antigrav lost.\n");
			self.antigrav_finished = 0;
			self.items2 = self.items2 - IT2_ANTIGRAV;
			self.gravity = 1.0;
		}
	}
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() xpackEnding;

void() PlayerPostThink =
{
	// local	float	mspeed, aspeed;
	// local	float	r;
	
	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (self.deadflag)
		return;
		
	if (cutscene_running)
		xpackEnding();
	
// do weapon stuff
	W_WeaponFrame ();

// check to see if player landed and play landing sound	
	if ((self.jump_flag < -300) && 
			(self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5); 
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	CheckPowerups ();
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	bprint (self.netname);
	bprint (" entered the game\n");
	
//ZOID--
	self.suicide_count = 0;
	self.ctf_killed = 0;

	SetMOTD();

 	// If this is our first connection, parm14 is < 0
 	// Set lastteam negative.
 	if (parm14 < 0 && teamplay > 0)
	{
		if (cvar("gamecfg") & GAMECFG_USE_COLOR)
			self.steam = self.team; // accept joining players color if legal
		else
			self.steam = -50; // always reassign
		TeamCheckLock();
	}
//--ZOID

// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

	// let everyone else know
	bprint (self.netname);
	bprint (" left the game with ");
	bprint (ftos(self.frags));
// Incorrect frag sentence when a player disconnects fix START
	if (self.frags == 1)
		bprint (" frag\n");
	else
// Incorrect frag sentence when a player disconnects fix END
		bprint (" frags\n");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
// Ghost eyes and hovering bodies fix START
	if (self.modelindex == modelindex_eyes)
		setmodel(self, "progs/player.mdl");
	self.items = self.items - (self.items & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD));
	self.invisible_finished = 0; // don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.effects = 0;
// Ghost eyes and hovering bodies fix END

	sphere_remove(self);
	if ( tag_token_owner == self)
		tag_token_drop();
	
//ZOID--
    TeamDropFlagOfPlayer(self);
	self.steam = -50;
	self.team = 0;
//--ZOID

	set_suicide_frame ();

// Ghost eyes and hovering bodies fix START
	CopyToBodyQue(self); // make a copy of the dead body for appearance sake
	setmodel(self, string_null);
// Ghost eyes and hovering bodies fix END
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{
	local	float rnum;
	local	string deathstring, deathstring2;
	rnum = random();

	if (targ.classname == "player")
	{
// ZOID--
		TeamResetCarrier(targ);
// --ZOID

// Deathmatch modes 3-5 START
		if (targ.deathtype == "selfwater")
		{
			bprint (targ.netname);
			bprint (" electrocutes himself.\n");
			targ.frags = targ.frags - 1;
			return;
		}
// Deathmatch modes 3-5 END
		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("Satan's power deflects ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");

			targ.frags = targ.frags - 1;
			return;
		}

// 1998-07-26 Pentagram telefrag fix by Zoid/Maddes  start
		// double 666 telefrag
		// (can happen often in deathmatch 4 and levels with more than one pentagram)
		if (attacker.classname == "teledeath3")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("'s Satan's power\n");
// 1998-07-26 only telefrag player on spot by Maddes  start
//			targ.frags = targ.frags - 1;
			attacker.owner.frags = attacker.owner.frags + 1;
// 1998-07-26 only telefrag player on spot by Maddes  end
			return;
		}
// 1998-07-26 Pentagram telefrag fix by Zoid/Maddes  end

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				attacker.frags = attacker.frags - 1;
				bprint (targ.netname);

// Player drops backpack on suicide START
				if (targ.deathtype == "suicide")
				{
					attacker.frags = attacker.frags - 1;	// extra penalty
					bprint (" suicides\n");
					return;
				}
// Player drops backpack on suicide END
				
				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					bprint (" discharges into the water.\n");
					return;
				}
				if (targ.weapon == IT_GRENADE_LAUNCHER)
					bprint (" tries to put the pin back in\n");
//ZOID--
//gibbed for changing teams
				else if (teamplay && (targ.team != targ.steam))
				{
					if (cvar("gamecfg") & GAMECFG_ALLOW_CHG)
						bprint(" changed teams\n");
					else
						bprint(" tried to change teams\n");
				}
//--ZOID
				else
					bprint (" becomes bored with life\n");
				return;
			}
			else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				attacker.frags = attacker.frags - 1;
				return;
			}
			else
			{
				if (teamplay == TEAM_DMATCH_TAG)
					dmatch_score (targ, attacker);
				else
				{
					attacker.frags = attacker.frags + 1;
//ZOID--
					TeamAssists(targ, attacker);
//--ZOID
				}

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					deathstring = " was ax-murdered by ";
					deathstring2 = "\n";
				}
//ZOID--
				if (rnum == IT_GRAPPLE)
				{
					deathstring = " was grappled by ";
					deathstring2 = "\n";
				}
//--ZOID
				if (rnum == IT_SHOTGUN)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}
				if (rnum == IT_SUPER_SHOTGUN)
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				if (rnum == IT_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was punctured by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				if (rnum == IT_ROCKET_LAUNCHER)
				{
					deathstring = " rides ";
					deathstring2 = "'s rocket\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s rocket\n" ;
					}
				}
				if (rnum == IT_LIGHTNING)
				{
					deathstring = " accepts ";
					if (attacker.waterlevel > 1)
						deathstring2 = "'s discharge\n";
					else
						deathstring2 = "'s shaft\n";
				}
				
				if (rnum == IT_LAVA_NAILGUN ||
						rnum == IT_LAVA_SUPER_NAILGUN)
				{
					deathstring = " was burned by ";
					deathstring2 = "\n";
				}
				else if (rnum == IT_PLASMA_GUN)
				{
					deathstring = " was fused by ";
					deathstring2 = "\n";
				}
				else if (rnum == IT_MULTI_GRENADE ||
							rnum == IT_MULTI_ROCKET)
				{
					deathstring = " was blasted to bits by ";
					deathstring2 = "\n";
				}
				
				bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;
			bprint (targ.netname);

			// killed by a montser?
			if (attacker.flags & FL_MONSTER)
			{
				if (attacker.classname == "monster_army")
					bprint (" was shot by a Grunt\n");
				if (attacker.classname == "monster_demon1")
					bprint (" was eviscerated by a Fiend\n");
				if (attacker.classname == "monster_dog")
					bprint (" was mauled by a Rottweiler\n");
				if (attacker.classname == "monster_dragon")
					bprint (" was annihilated by the Dragon\n");
				if (attacker.classname == "monster_dragon_dead")
					bprint (" was squashed by the Dragon\n");
				if (attacker.classname == "monster_enforcer")
					bprint (" was blasted by an Enforcer\n");
				if (attacker.classname == "monster_fish")
					bprint (" was fed to the Rotfish\n");
				if (attacker.classname == "monster_hell_knight")
					bprint (" was slain by a Death Knight\n");
				if (attacker.classname == "monster_knight")
					bprint (" was slashed by a Knight\n");
				if (attacker.classname == "monster_ogre")
					bprint (" was destroyed by an Ogre\n");
				if (attacker.classname == "monster_oldone")
					bprint (" became one with Shub-Niggurath\n");
				if (attacker.classname == "monster_shalrath")
					bprint (" was exploded by a Vore\n");
				if (attacker.classname == "monster_shambler")
					bprint (" was smashed by a Shambler\n");
				if (attacker.classname == "monster_tarbaby")
					bprint (" was slimed by a Spawn\n");
				if (attacker.classname == "monster_vomit")
					bprint (" was vomited on by a Vomitus\n");
				if (attacker.classname == "monster_wizard")
					bprint (" was scragged by a Scrag\n");
				if (attacker.classname == "monster_zombie")
					bprint (" joins the Zombies\n");

				if (attacker.classname == "monster_eel")
					bprint (" was electrified by an Eel\n");
				if (attacker.classname == "monster_wrath")
					bprint (" was disintegrated by a Wrath\n");
				if (attacker.classname == "monster_super_wrath")
					bprint (" was obliterated by an Overlord\n");
				if (attacker.classname == "monster_sword")
					bprint (" was slit open by a Phantom Swordsman\n");
				if (attacker.classname == "monster_lava_man")
					bprint (" fries in Hephaestus' fury\n");
				if (attacker.classname == "monster_morph")
					bprint (" was crushed by a Guardian\n");
				if (attacker.classname == "monster_mummy")
					bprint (" was Mummified\n");

				return;
			}

			// tricks and traps
			if (attacker.classname == "explo_box")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{	
				bprint (" was squished\n");
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint (" was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}

			if (attacker.classname == "ltrail_start" || 
				attacker.classname == "ltrail_relay")
			{
				bprint (" rode the lightning\n");
				return;
			}
			if (attacker.classname == "pendulum")
			{
				bprint (" was cleaved in two\n");
				return;
			}
			if (attacker.classname == "buzzsaw")
			{
				bprint (" was sliced to pieces\n");
				return;
			}
			if (attacker.classname == "plasma")
			{
				bprint ( " was turned to plasma\n");
				return;
			}
			if (attacker.classname == "Vengeance")
			{
				// vengeance sphere doesn't count as a negative frag
				targ.frags = targ.frags + 1;
				bprint ( " was purged by the Vengeance Sphere\n");
				return;
			}
			if (attacker.classname == "power_shield")
			{
				// shield attacks should count for frags too..
				// shield death doesn't count as a negative frag
				targ.frags = targ.frags + 1;
				attacker.owner.frags = attacker.owner.frags + 1;
				TeamAssists(targ, attacker.owner);			//PGM

				deathstring = " was smashed by ";
				deathstring2 = "\n";
				bprint (deathstring);
				bprint (attacker.owner.netname);
				bprint (deathstring2);
				return;
			}

			// in-water deaths
			rnum = targ.watertype;
			if (rnum == -3)
			{
				if (random() < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			else if (rnum == -4)
			{
				if (random() < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			else if (rnum == -5)
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			// fell to their death?
			if (targ.deathtype == "falling")
			{
				targ.deathtype = "";
				bprint (" fell to his death\n");
				return;
			}

			// hell if I know; he's just dead!!!
			bprint (" died\n");
		}
	}
};
