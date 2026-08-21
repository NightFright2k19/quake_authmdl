/*
Code fixes:
[monsters.qc] Fish count bug
[monsters.qc] Movetarget correction in monster start functions (missing brackets in "if" clauses added)
[monsters.qc] Monsters sometimes don't move fix
[monsters.qc] [items.qc] [misc.qc] [ogre.qc] [shambler.qc] [zombie.qc] Nextthink fix (monsters may rarely stop or not even stop walking)
[monsters.qc] [boss.qc] [client.qc] [demon.qc] [dog.qc] [misc.qc] [oldone.qc] [tarbaby.qc] Sliding/not-jumping on monsters/boxes/players fix (using new monster touch function on players)
*/

/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// };

// Sliding/not-jumping on monsters/boxes/players fix START
void() monster_touch =
{
	// can cause problems for monsters on top of a player, so only players
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if ((!(other.flags & FL_ONGROUND)) && (other.absmin_z >= self.absmax_z - 2))
		other.flags = other.flags + FL_ONGROUND;
};
// Sliding/not-jumping on monsters/boxes/players fix END

/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void() monster_use =
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;
	if (activator.items & IT_INVISIBILITY)
		return;
	if (activator.flags & FL_NOTARGET)
		return;
	if (activator.classname != "player")
		return;
	
// delay reaction so if the monster is teleported, its sound is still
// heard
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
};

/*
================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
================
*/
void() monster_death_use =
{

// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;

	if (!self.target)
		return;

	activator = self.enemy;
	SUB_UseTargets ();
};


//============================================================================

void() walkmonster_start_go =
{

	self.origin_z = self.origin_z + 1;	// raise off floor a bit
	droptofloor();
	
	if (!walkmove(0,0))
	{
		dprint ("walkmonster in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}
	
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 20;
	self.view_ofs = '0 0 25';
	self.use = monster_use;
	
	self.flags = self.flags | FL_MONSTER;
	
	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
		{ // Movetarget correction in monster start functions
			self.pausetime = 99999999;
			self.th_stand ();
		} // Movetarget correction in monster start functions
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

// spread think times so they don't all happen at same time
	// self.nextthink = self.nextthink + random()*0.5;
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
};

void() walkmonster_start =
{
	self.touch = monster_touch; // Sliding/not-jumping on monsters/boxes/players fix
// delay drop to floor to make sure all doors have been spawned
// spread think times so they don't all happen at same time
	// self.nextthink = self.nextthink + random()*0.5;
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
	self.think = walkmonster_start_go;
	total_monsters = total_monsters + 1;
};

void() flymonster_start_go =
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_FLY;
	self.flags = self.flags | FL_MONSTER;

	if (!walkmove(0,0))
	{
		dprint ("flymonster in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
		{ // Movetarget correction in monster start functions
			self.pausetime = 99999999;
			self.th_stand ();
		} // Movetarget correction in monster start functions
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
};

void() flymonster_start =
{
	self.touch = monster_touch; // Sliding/not-jumping on monsters/boxes/players fix

	self.flags = self.flags | FL_FLY; // Monsters sometimes don't move fix

// spread think times so they don't all happen at same time
	// self.nextthink = self.nextthink + random()*0.5;
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
	self.think = flymonster_start_go;
	total_monsters = total_monsters + 1;
};

void() swimmonster_start_go =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}

	self.takedamage = DAMAGE_AIM;
	// total_monsters = total_monsters + 1; // Fish count bug fix

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 10';
	self.use = monster_use;
	
	self.flags = self.flags | FL_SWIM;
	self.flags = self.flags | FL_MONSTER;

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		self.th_walk ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

// spread think times so they don't all happen at same time
	// self.nextthink = self.nextthink + random()*0.5;
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
};

void() swimmonster_start =
{
	self.touch = monster_touch; // Sliding/not-jumping on monsters/boxes/players fix

	self.flags = self.flags | FL_SWIM; // Monsters sometimes don't move fix

// spread think times so they don't all happen at same time
	// self.nextthink = self.nextthink + random()*0.5;
        self.nextthink = time + 0.1 + random()*0.05; // Nextthink fix
	self.think = swimmonster_start_go;
	total_monsters = total_monsters + 1;
};
