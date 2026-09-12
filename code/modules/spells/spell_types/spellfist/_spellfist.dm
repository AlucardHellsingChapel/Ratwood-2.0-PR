/// Delivers a weapon-style blow from a spell without going through the click pipeline.
/// Returns TRUE if the blow landed.
/proc/psydon_strike(mob/living/user, mob/living/target, damage, def_zone, attack_flag = "blunt")
	if(QDELETED(user) || QDELETED(target))
		return FALSE
	if(target.anti_magic_check())
		target.visible_message(span_warning("The arcyne force dissipates against [target]!"))
		playsound(get_turf(target), 'sound/magic/magic_nulled.ogg', 100)
		return FALSE
	if(!def_zone)
		def_zone = user.zone_selected || BODY_ZONE_CHEST
	var/armor_block = target.run_armor_check(def_zone, attack_flag, damage = damage)
	target.apply_damage(damage, BRUTE, def_zone, armor_block)
	return TRUE

/// Spells of the Naledi spellfist discipline, all of which feed on and spend Arcyne Momentum.
/obj/effect/proc_holder/spell/invoked/spellfist
	cost = 0
	xp_gain = TRUE
	human_req = TRUE
	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	chargedloop = /datum/looping_sound/invokegen
	associated_skill = /datum/skill/magic/arcane
	invocation_type = "shout"
	gesture_required = TRUE
	glow_color = GLOW_COLOR_DISPLACEMENT
	glow_intensity = GLOW_INTENSITY_LOW
	/// Momentum spent to empower the spell. Spells work without it, they just hit softer.
	var/momentum_cost = 3

/// Spends momentum if the caster has enough of it, returning TRUE when the cast is empowered.
/obj/effect/proc_holder/spell/invoked/spellfist/proc/try_empower(mob/living/user)
	var/datum/status_effect/buff/arcyne_momentum/momentum = user.has_status_effect(/datum/status_effect/buff/arcyne_momentum)
	if(!momentum || momentum.stacks < momentum_cost)
		return FALSE
	momentum.consume_stacks(momentum_cost)
	to_chat(user, span_notice("[momentum_cost] momentum released - empowered strike!"))
	return TRUE
