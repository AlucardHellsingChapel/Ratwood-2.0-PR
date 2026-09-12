/obj/effect/proc_holder/spell/invoked/spellfist/fist_of_psydon
	name = "Fist of Psydon"
	desc = "Slam your fist downward, sending arcyne force crashing into a 3x3 area a few paces away after a brief telegraph. \
	Deals blunt damage to the aimed bodypart. At 3 momentum or more, spends 3 to double the damage."
	overlay_state = "hammerfall"
	releasedrain = 25
	chargedrain = 1
	chargetime = 5
	charging_slowdown = 1
	recharge_time = 12 SECONDS
	range = 5
	spell_tier = 2
	invocations = list("Idrib!")
	sound = list('sound/combat/wooshes/punch/punchwoosh (1).ogg','sound/combat/wooshes/punch/punchwoosh (2).ogg','sound/combat/wooshes/punch/punchwoosh (3).ogg')
	var/base_damage = 40
	var/empowered_mult = 2
	var/area_of_effect = 1
	var/telegraph_delay = 0.8 SECONDS

/obj/effect/proc_holder/spell/invoked/spellfist/fist_of_psydon/cast(list/targets, mob/living/user)
	. = ..()
	var/turf/T = get_turf(targets[1])
	if(!T)
		revert_cast()
		return FALSE

	var/empowered = try_empower(user)
	var/damage = empowered ? (base_damage * empowered_mult) : base_damage
	var/def_zone = user.zone_selected || BODY_ZONE_CHEST

	for(var/turf/affected_turf in view(area_of_effect, T))
		new /obj/effect/temp_visual/trap(affected_turf)
	playsound(T, pick('sound/combat/ground_smash1.ogg', 'sound/combat/ground_smash2.ogg', 'sound/combat/ground_smash3.ogg'), 60, TRUE)

	addtimer(CALLBACK(src, PROC_REF(resolve_fist), user, T, damage, def_zone), telegraph_delay)
	return TRUE

/obj/effect/proc_holder/spell/invoked/spellfist/fist_of_psydon/proc/resolve_fist(mob/living/user, turf/center, damage, def_zone)
	if(QDELETED(user) || user.stat == DEAD)
		return

	var/hit_count = 0
	for(var/turf/affected_turf in view(area_of_effect, center))
		new /obj/effect/temp_visual/kinetic_blast(affected_turf)
		for(var/mob/living/victim in affected_turf)
			if(victim == user || victim.stat == DEAD)
				continue
			if(psydon_strike(user, victim, damage, def_zone))
				hit_count++

	playsound(center, pick('sound/combat/ground_smash1.ogg', 'sound/combat/ground_smash2.ogg', 'sound/combat/ground_smash3.ogg'), 100, TRUE)
	if(hit_count)
		user.visible_message(span_danger("[user] slams [user.p_their()] fist down, sending a shockwave of arcyne force crashing into the ground!"))
	else
		user.visible_message(span_notice("[user] slams [user.p_their()] fist down, sending a shockwave into empty ground!"))
	log_combat(user, null, "used Fist of Psydon")
