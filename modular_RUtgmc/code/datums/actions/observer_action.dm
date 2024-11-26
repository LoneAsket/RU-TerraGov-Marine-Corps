/datum/action/observer_action/find_facehugger_spawn
	name = "Spawn as Facehugger"
	action_icon = 'modular_RUtgmc/icons/Xeno/actions.dmi'
	action_icon_state = "hugger_set"

/datum/action/observer_action/find_facehugger_spawn/action_activate()
	var/mob/dead/observer/dead_owner = owner
	if(GLOB.key_to_time_of_death[owner.key] + TIME_BEFORE_TAKING_BODY > world.time && !dead_owner.started_as_observer)
		to_chat(owner, span_warning("You died too recently to be able to take a new mob."))
		return

	var/list/spawn_point = list()
	var/list/area_names = list()
	var/list/area_namecounts = list()
	var/name

	for(var/mob/living/carbon/xenomorph/potential_xeno AS in GLOB.alive_xeno_list)
		if(dead_owner.z != potential_xeno.z)
			continue
		if(!isxenocarrier(potential_xeno))
			continue

		var/mob/living/carbon/xenomorph/carrier/selected_carrier = potential_xeno
		if(selected_carrier.huggers_reserved >= selected_carrier.huggers)
			continue

		name = selected_carrier.name
		spawn_point[name] = potential_xeno

	for(var/obj/alien/egg/hugger/potential_egg AS in GLOB.xeno_egg_hugger)
		if(dead_owner.z != potential_egg.z)
			continue
		if(potential_egg.maturity_stage != potential_egg.stage_ready_to_burst)
			continue
		if(!potential_egg.hugger_type)
			continue
		if(istype(potential_egg, /obj/alien/egg/hugger/forsaken))
			continue

		var/area_egg = get_area(potential_egg)
		if(area_egg in area_names)
			area_namecounts[area_egg]++
			name = "[potential_egg.name] at [area_egg] ([area_namecounts[area_egg]])"
		else
			area_names.Add(area_egg)
			area_namecounts[area_egg] = 1
			name = "[potential_egg.name] at [get_area(potential_egg)]"

		spawn_point[name] = potential_egg

	if(!length_char(spawn_point))
		to_chat(owner, span_warning("There are no spawn points for facehugger on your Z-level."))
		return

	var/selected = tgui_input_list(usr, "Please select a spawn point:", "Spawn as Facehugger", spawn_point)
	if(!selected)
		return

	var/target = spawn_point[selected]
	dead_owner.abstract_move(get_turf(target))

/datum/action/observer_action/join_predator
	name = "Join the Hunt"
	action_icon_state = "pred_ghost"

/datum/action/observer_action/join_predator/give_action(mob/M)
	var/owner_ckey = M.client?.ckey
	if(!owner_ckey)
		return

	if(!(GLOB.roles_whitelist[owner_ckey] & WHITELIST_PREDATOR))
		return

	if(!SSticker.mode || !(SSticker.mode.flags_round_type & MODE_PREDATOR))
		RegisterSignal(SSdcs, COMSIG_GLOB_PREDATOR_ROUND_TOGGLED, PROC_REF(handle_button_status_visuals))

	. = ..()

/datum/action/observer_action/join_predator/can_use_action()
	if(!SSticker.mode || !(SSticker.mode.flags_round_type & MODE_PREDATOR))
		return FALSE
	return TRUE

/datum/action/observer_action/join_predator/action_activate()
	var/mob/dead/observer/activator = owner
	if(SSticker.current_state < GAME_STATE_PLAYING || !SSticker.mode)
		to_chat(activator, span_warning("The game hasn't started yet!"))
		return

	if(SSticker.mode.check_predator_late_join(activator))
		SSticker.mode.join_predator(activator)
