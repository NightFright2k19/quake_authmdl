/*
Code fixes:

[combat.qc] God cheat preserves armor and prevents underwater gagging (Pentagram still won't)
[combat.qc] Teamplay 1 fix
[combat.qc] Doors no Quad power fix (recognizing doors)
[combat.qc] CanDamage fix (checking half-sized bounding box)
[combat.qc] [misc.qc] T_RadiusDamage workaround
[combat.qc] [client.qc] [defs.qc] [hipitems.qc] [items.qc] [weapons.qc] [world.qc] Deathmatch modes 3-5
*/


void() T_MissileTouch;
void() info_player_start;
void(entity targ, entity attacker) ClientObituary;

void() monster_death_use;

//============================================================================

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}

	traceline(inflictor.origin, targ.origin, TRUE, self);

	if (trace_fraction == 1)
		return TRUE;

// CanDamage fix START
	local vector	dif;

	// testing middle of half-size bounding box
	dif_z = 0;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;

	// traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
// CanDamage fix END

	if (trace_fraction == 1)
		return TRUE;

// CanDamage fix START
	// ...front left
	dif_x = targ.mins_x * 0.5;
	// traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
// CanDamage fix END

	if (trace_fraction == 1)
		return TRUE;

// CanDamage fix START
	// ...back left
	dif_y = targ.mins_y * 0.5;
	// traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
        traceline(inflictor.origin, targ.origin + dif, TRUE, self);
// CanDamage fix END

	if (trace_fraction == 1)
		return TRUE;

// CanDamage fix START
	// ...back right
	dif_x = targ.maxs_x * 0.5;
	// traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
// CanDamage fix END

	if (trace_fraction == 1)
		return TRUE;

// CanDamage fix START
	// testing top of half-sized bounding box
	dif_z = targ.maxs_z * 0.5;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...front left
	dif_x = targ.mins_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...back left
	dif_y = targ.mins_y * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...back right
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// testing bottom of half-sized bounding box
	dif_z = targ.mins_z * 0.5;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...front left
	dif_x = targ.mins_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...back left
	dif_y = targ.mins_y * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	// ...back right
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
// CanDamage fix END

	return FALSE;
};


/*
============
Killed
============
*/
void(entity targ, entity attacker) Killed =
{
	local entity oself;

	oself = self;
	self = targ;

	if (self.health < -99)
		self.health = -99;		// don't let sbar look bad if a player
//MED
	if (self.charmed)
      		self.effects = self.effects - (self.effects & EF_DIMLIGHT);
//      self.effects = self.effects - EF_BRIGHTFIELD;

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{	// doors, triggers, etc
		self.th_die ();
		self = oself;
		return;
	}

	self.enemy = attacker;

// bump the monster counter
   	if (self.flags & FL_MONSTER)
	{
      		killed_monsters = killed_monsters + 1;
		WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
	}

	ClientObituary(self, attacker);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	monster_death_use();
	self.th_die ();

	self = oself;
};


/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
//MED 01/10/97 added empathyused variable
float empathyused;
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage=
{
	local	vector	dir;
	local	entity	oldself;
	local	float	save, take;

	if (!targ.takedamage)
		return;

   	if (discharged && targ.wetsuit_finished )
      		return;
//MED moved damage_attacker down a bit
/*
   	dprint("netname = ");
   	dprint(attacker.netname);
   	dprint(" classname = ");
   	dprint(attacker.classname);
   	dprint(" classname = ");
   	dprint(inflictor.classname);
   	dprint("\n");
*/
// check for quad damage powerup on the attacker
	// if (attacker.super_damage_finished > time)
	if (attacker.super_damage_finished > time && inflictor.classname != "door") // Doors no Quad power fix
// Deathmatch modes 3-5 START
	{
		if (deathmatch == 4)
			damage = damage * 8;
		else
// Deathmatch modes 3-5 END
			damage = damage * 4;
	} // Deathmatch modes 3-5

// God cheat preserves armor START
	if ( (inflictor != world) && (targ.movetype == MOVETYPE_WALK) )
	{
		dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		targ.velocity = targ.velocity + dir*damage*8;
	}

	if (targ.flags & FL_GODMODE)
		return;
// God cheat preserves armor END

//MED
//check for empathy shields
	if ((targ.items2 & HIP_IT_EMPATHY_SHIELDS) && !(inflictor.items2 & HIP_IT_EMPATHY_SHIELDS) && (targ != attacker))
      	{
      		empathyused = 1;
      		damage = damage/2;
      		T_Damage (attacker,targ,targ,damage);
      		empathyused = 0;
      	}
//MED
// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

//MED
// used to keep track of what hit us
   	damage_inflictor = inflictor;

// save damage based on the target's armor level

	save = ceil(targ.armortype*damage);
	if (save >= targ.armorvalue)
	{
		save = targ.armorvalue;
		targ.armortype = 0;	// lost all armor
      		targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
   	}
	targ.armorvalue = targ.armorvalue - save;
	take = ceil(damage-save);

// add to the damage total for clients, which will be sent as a single
// message at the end of the frame
// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take = targ.dmg_take + take;
		targ.dmg_save = targ.dmg_save + save;
		targ.dmg_inflictor = inflictor;
	}

// God cheat preserves armor START
/*
// figure momentum add
	if ( (inflictor != world) && (targ.movetype == MOVETYPE_WALK) )
	{
		dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		targ.velocity = targ.velocity + dir*damage*8;
	}

// check for godmode
	if (targ.flags & FL_GODMODE)
		return;
*/
// God cheat preserves armor END

// check for invincibility
	if (targ.invincible_finished >= time)
	{
		if (self.invincible_sound < time)
		{
			sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
			self.invincible_sound = time + 2;
		}
		return;
	}

//MED
   	if (targ.items2 & HIP_IT_EMPATHY_SHIELDS)
	{
      		if (self.empathy_sound < time)
		{
         		sound (targ, CHAN_ITEM, "hipitems/empathy2.wav", 1, ATTN_NORM);
         		self.empathy_sound = time + 0.5;
		}
	}

// team play damage avoidance
	// 1998-07-29 Teamplay 1 fix by Maddes  start
	if ( (teamplay == 1) && (targ.team > 0) && (targ.team == attacker.team)
	&& (targ != attacker) && (attacker.classname == "player") && (inflictor.classname != "door") )	// because squishing a teammate is still possible
// 1998-07-29 Teamplay 1 fix by Maddes  end
		return;

// do the damage
	targ.health = targ.health - take;

	if (targ.health <= 0)
	{
		Killed (targ, attacker);
		return;
	}

// react to the damage
	oldself = self;
	self = targ;

//MED 10/17/96 added charmed stuff
	if ( (self.flags & FL_MONSTER) && attacker != world)
	{
	// get mad unless of the same class (except for soldiers)
      		if (self != attacker && attacker != self.enemy && (self.charmer!=attacker))
		{
			if ( (self.classname != attacker.classname)
         || (self.classname == "monster_army" ) || (self.classname == "monster_armagon" ) )
			{
				if (self.enemy.classname == "player")
					self.oldenemy = self.enemy;
				self.enemy = attacker;
				FoundTarget ();
			}
		}
	}

	if (self.th_pain)
	{
		self.th_pain (attacker, take);
	// nightmare mode monsters don't go into pain frames often
		if (skill == 3)
			self.pain_finished = time + 5;
	}

	self = oldself;
};

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage =
{
	local	float 	points;
	local	entity	head;
	local	vector	org;
	local	float	attacker_damaged, attacker_points; // T_RadiusDamage workaround

	head = findradius(inflictor.origin, damage+40);

	while (head)
	{
		if (head != ignore)
		{
			if (head.takedamage)
			{
				org = head.origin + (head.mins + head.maxs)*0.5;
				points = 0.5*vlen (inflictor.origin - org);
				if (points < 0)
					points = 0;
				points = damage - points;
// T_RadiusDamage workaround START
/*
				if (head == attacker)
					points = points * 0.5;
*/
// T_RadiusDamage workaround END
				if (points > 0)
				{
					if (CanDamage (head, inflictor))
					{
// T_RadiusDamage workaround START
						if (head != attacker)
						{
// T_RadiusDamage workaround END
                                                // shambler takes half damage from all explosions
						if (head.classname == "monster_shambler")
							T_Damage (head, inflictor, attacker, points*0.5);
						else
							T_Damage (head, inflictor, attacker, points);
// T_RadiusDamage workaround START
						}
						else
						{
							attacker_damaged = TRUE;
							attacker_points = points * 0.5;
						}
// T_RadiusDamage workaround END
					}
				}
			}
		}
		head = head.chain;
	}
// T_RadiusDamage workaround START
	if (attacker_damaged)
		T_Damage (attacker, inflictor, attacker, attacker_points);
// T_RadiusDamage workaround END
};

/*
============
T_BeamDamage
============
*/
void(entity attacker, float damage) T_BeamDamage =
{
	local	float 	points;
	local	entity	head;

	head = findradius(attacker.origin, damage+40);

	while (head)
	{
		if (head.takedamage)
		{
			points = 0.5*vlen (attacker.origin - head.origin);
			if (points < 0)
				points = 0;
			points = damage - points;
			if (head == attacker)
				points = points * 0.5;
			if (points > 0)
			{
				if (CanDamage (head, attacker))
				{
					if (head.classname == "monster_shambler")
						T_Damage (head, attacker, attacker, points*0.5);
					else
						T_Damage (head, attacker, attacker, points);
				}
			}
		}
		head = head.chain;
	}
};
