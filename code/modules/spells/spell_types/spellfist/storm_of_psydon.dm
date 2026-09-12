/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon
	name = "Storm of Psydon"
	desc = "Dash to a foe and unload a flurry of arcyne blows, finishing with a kick that sends them flying. Requires at least 7 momentum, and spends everything you have. \
	With a full 10 momentum the flurry is three times as long."
	overlay_state = "bloodcrawl"
	releasedrain = 40
	chargedrain = 1
	chargetime = 5
	charging_slowdown = 1
	recharge_time = 45 SECONDS
	range = 7
	spell_tier = 3
	invocations = list("INTAQAM PSYDON!")
	sound = 'sound/magic/charged.ogg'
	momentum_cost = 7
	/// Momentum needed for the longer flurry.
	var/overcharge_cost = 10
	var/punch_damage = 12
	var/kick_damage = 25
	var/base_punches = 3
	var/overcharged_punches = 9
	var/punch_delay = 0.15 SECONDS

/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon/can_cast(mob/user = usr)
	. = ..()
	if(!.)
		return FALSE
	if(get_arcyne_momentum(user) < momentum_cost)
		return FALSE

/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon/cast(list/targets, mob/living/user)
	. = ..()
	var/mob/living/target = targets[1]
	if(!isliving(target) || target == user)
		to_chat(user, span_warning("I must strike a living foe!"))
		revert_cast()
		return FALSE

	var/datum/status_effect/buff/arcyne_momentum/momentum = user.has_status_effect(/datum/status_effect/buff/arcyne_momentum)
	if(!momentum || momentum.stacks < momentum_cost)
		to_chat(user, span_warning("My momentum has slipped away!"))
		revert_cast()
		return FALSE

	var/overcharged = momentum.stacks >= overcharge_cost
	var/punches = overcharged ? overcharged_punches : base_punches

	if(!dash_to(user, target))
		to_chat(user, span_warning("[target] is out of reach!"))
		revert_cast()
		return FALSE

	// Momentum is only spent once the dash actually connects.
	momentum.consume_all_stacks()
	user.visible_message(span_danger("[user] erupts into a storm of arcyne blows against [target]!"))
	flurry(user, target, punches)
	finisher(user, target)
	log_combat(user, target, "used Storm of Psydon[overcharged ? " (overcharged)" : ""]")
	return TRUE

/// Closes the gap, landing next to the target. Returns FALSE when no free tile is adjacent.
/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon/proc/dash_to(mob/living/user, mob/living/target)
	var/turf/destination = get_turf(target)
	if(!destination || destination.z != user.z)
		return FALSE
	if(get_dist(user, target) > range)
		return FALSE

	var/turf/landing
	for(var/turf/candidate in orange(1, destination))
		if(candidate.density || !candidate.Enter(user))
			continue
		if(!landing || get_dist(user, candidate) < get_dist(user, landing))
			landing = candidate
	if(!landing)
		landing = get_turf(user)
	if(!(landing in view(range, user)))
		return FALSE

	playsound(get_turf(user), 'sound/magic/shadowstep.ogg', 60, TRUE)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(user))
	user.forceMove(landing)
	user.setDir(get_dir(user, target))
	playsound(landing, 'sound/magic/shadowstep_destination.ogg', 60, TRUE)
	return TRUE

/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon/proc/flurry(mob/living/user, mob/living/target, punches)
	for(var/i in 1 to punches)
		if(QDELETED(user) || QDELETED(target) || target.stat == DEAD)
			return
		if(user.IsStun() || user.IsParalyzed() || user.stat != CONSCIOUS)
			return
		if(!user.Adjacent(target))
			to_chat(user, span_warning("[target] slips out of my reach!"))
			return
		psydon_strike(user, target, punch_damage, pick(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		playsound(get_turf(target), pick('sound/combat/hits/punch/punch_hard (1).ogg', 'sound/combat/hits/punch/punch_hard (2).ogg', 'sound/combat/hits/punch/punch_hard (3).ogg'), 70, TRUE)
		sleep(punch_delay)

/obj/effect/proc_holder/spell/invoked/spellfist/storm_of_psydon/proc/finisher(mob/living/user, mob/living/target)
	if(QDELETED(user) || QDELETED(target) || target.stat == DEAD || !user.Adjacent(target))
		return
	if(!psydon_strike(user, target, kick_damage, BODY_ZONE_CHEST))
		return
	playsound(get_turf(target), pick('sound/combat/hits/blunt/genblunt (1).ogg', 'sound/combat/hits/blunt/genblunt (2).ogg', 'sound/combat/hits/blunt/genblunt (3).ogg'), 100, TRUE)
	target.visible_message(span_danger("[user] finishes the storm with a devastating kick, sending [target] flying!"))
	new /obj/effect/temp_visual/kinetic_blast(get_turf(target))
	var/atom/throw_target = get_edge_target_turf(target, get_dir(user, target))
	target.safe_throw_at(throw_target, 4, 2, user)
	target.Knockdown(2 SECONDS)
