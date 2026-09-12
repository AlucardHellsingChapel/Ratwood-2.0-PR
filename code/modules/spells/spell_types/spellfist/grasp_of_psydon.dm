/obj/effect/proc_holder/spell/invoked/spellfist/grasp_of_psydon
	name = "Grasp of Psydon"
	desc = "Thrust your open palm forward, sending tendrils of arcyne force into a small area. After a brief telegraph everything caught in it is yanked toward you. \
	At 3 momentum or more, spends 3 to batter each victim as they are dragged in."
	overlay_state = "unholy_grasp"
	releasedrain = 20
	chargedrain = 1
	chargetime = 5
	charging_slowdown = 2
	recharge_time = 20 SECONDS
	range = 5
	spell_tier = 2
	invocations = list("Iqbid!")
	sound = list('sound/combat/wooshes/punch/punchwoosh (1).ogg','sound/combat/wooshes/punch/punchwoosh (2).ogg','sound/combat/wooshes/punch/punchwoosh (3).ogg')
	var/area_of_effect = 1
	var/pull_distance = 7
	var/telegraph_delay = 0.8 SECONDS
	var/base_damage = 15
	var/empowered_damage = 40

/obj/effect/proc_holder/spell/invoked/spellfist/grasp_of_psydon/cast(list/targets, mob/living/user)
	. = ..()
	var/turf/T = get_turf(targets[1])
	var/turf/caster_turf = get_turf(user)
	if(!T || !caster_turf)
		revert_cast()
		return FALSE
	if(T.z != caster_turf.z)
		to_chat(user, span_warning("The tendrils can't reach across planes!"))
		revert_cast()
		return FALSE

	var/empowered = try_empower(user)

	for(var/turf/affected_turf in view(area_of_effect, T))
		if(affected_turf.density)
			continue
		new /obj/effect/temp_visual/ensnare(affected_turf)
	playsound(T, 'sound/magic/webspin.ogg', 50, TRUE)

	addtimer(CALLBACK(src, PROC_REF(resolve_grasp), user, T, empowered), telegraph_delay)
	return TRUE

/obj/effect/proc_holder/spell/invoked/spellfist/grasp_of_psydon/proc/resolve_grasp(mob/living/user, turf/center, empowered = FALSE)
	if(QDELETED(user) || user.stat == DEAD)
		return

	var/turf/caster_turf = get_turf(user)
	playsound(center, 'sound/combat/grabbreak.ogg', 80, TRUE)

	var/hit_count = 0
	for(var/mob/living/victim in range(area_of_effect, center))
		if(victim == user || victim.stat == DEAD)
			continue
		var/def_zone = user.zone_selected || BODY_ZONE_CHEST
		if(!psydon_strike(user, victim, empowered ? empowered_damage : base_damage, def_zone))
			continue
		victim.throw_at(caster_turf, pull_distance, 4)
		victim.visible_message(span_warning("[victim] is yanked toward [user] by tendrils of arcyne force!"))
		new /obj/effect/temp_visual/ensnare/long(get_turf(victim))
		hit_count++

	if(hit_count)
		user.visible_message(span_danger("[user] clenches [user.p_their()] fist, pulling [hit_count > 1 ? "enemies" : "an enemy"] toward [user.p_them()]!"))
	log_combat(user, null, "used Grasp of Psydon[empowered ? " (empowered)" : ""]")
