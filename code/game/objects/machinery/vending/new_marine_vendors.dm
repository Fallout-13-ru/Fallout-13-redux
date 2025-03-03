/obj/machinery/marine_selector
	name = "\improper Theoretical Marine selector"
	desc = ""
	icon = 'icons/obj/machines/vending.dmi'
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	req_access = null
	req_one_access = null
	interaction_flags = INTERACT_MACHINE_TGUI

	idle_power_usage = 60
	active_power_usage = 3000

	var/gives_webbing = FALSE
	var/vendor_role //to be compared with job.type to only allow those to use that machine.
	var/squad_tag = ""
	var/use_points = FALSE
	var/lock_flags = SQUAD_LOCK|JOB_LOCK

	var/icon_vend
	var/icon_deny

	var/list/categories
	var/list/listed_products
	///The faction of that vendor, can be null
	var/faction

/obj/machinery/marine_selector/update_icon()
	if(is_operational())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"



/obj/machinery/marine_selector/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!allowed(H))
			to_chat(user, span_warning("Access denied. Your assigned role doesn't have access to this machinery."))
			return FALSE

		var/obj/item/card/id/I = H.get_idcard()
		if(!istype(I)) //not wearing an ID
			return FALSE

		if(I.registered_name != H.real_name)
			return FALSE

		if(lock_flags & JOB_LOCK && vendor_role && !istype(H.job, vendor_role))
			to_chat(user, span_warning("Access denied. This vendor is heavily restricted."))
			return FALSE

		if(lock_flags & SQUAD_LOCK && (!H.assigned_squad || (squad_tag && H.assigned_squad.name != squad_tag)))
			to_chat(user, span_warning("Access denied. Your assigned squad isn't allowed to access this machinery."))
			return FALSE

	return TRUE

/obj/machinery/marine_selector/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "MarineSelector", name)
		ui.open()

/obj/machinery/marine_selector/ui_static_data(mob/user)
	. = list()
	.["displayed_records"] = list()
	for(var/c in categories)
		.["displayed_records"][c] = list()

	.["vendor_name"] = name
	.["show_points"] = use_points
	var/obj/item/card/id/ID = user.get_idcard()
	.["total_marine_points"] = ID ? initial(ID.marine_points) : 0


	for(var/i in listed_products)
		var/list/myprod = listed_products[i]
		var/category = myprod[1]
		var/p_name = myprod[2]
		var/p_cost = myprod[3]
		var/atom/productpath = i

		LAZYADD(.["displayed_records"][category], list(list("prod_index" = i, "prod_name" = p_name, "prod_color" = myprod[4], "prod_cost" = p_cost, "prod_desc" = initial(productpath.desc))))

/obj/machinery/marine_selector/ui_data(mob/user)
	. = list()

	var/obj/item/card/id/I = user.get_idcard()
	.["current_m_points"] = I?.marine_points || 0
	var/buy_flags = I?.marine_buy_flags || NONE


	.["cats"] = list()
	for(var/i in GLOB.marine_selector_cats)
		.["cats"][i] = list("remaining" = 0, "total" = 0)
		for(var/flag in GLOB.marine_selector_cats[i])
			.["cats"][i]["total"]++
			if(buy_flags & flag)
				.["cats"][i]["remaining"]++

/obj/machinery/marine_selector/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("vend")
			if(!allowed(usr))
				to_chat(usr, span_warning("Access denied."))
				if(icon_deny)
					flick(icon_deny, src)
				return

			var/idx = text2path(params["vend"])
			var/obj/item/card/id/I = usr.get_idcard()

			var/list/L = listed_products[idx]
			var/cost = L[3]

			if(SSticker.mode?.flags_round_type & MODE_HUMAN_ONLY && is_type_in_typecache(idx, GLOB.hvh_restricted_items_list))
				to_chat(usr, span_warning("This item is banned by the Space Geneva Convention."))
				if(icon_deny)
					flick(icon_deny, src)
				return

			if(use_points && I.marine_points < cost)
				to_chat(usr, span_warning("Not enough points."))
				if(icon_deny)
					flick(icon_deny, src)
				return

			var/turf/T = loc
			if(length(T.contents) > 25)
				to_chat(usr, span_warning("The floor is too cluttered, make some space."))
				if(icon_deny)
					flick(icon_deny, src)
				return
			var/bitf = NONE
			var/list/C = GLOB.marine_selector_cats[L[1]]
			for(var/i in C)
				bitf |= i
			if(bitf)
				if(I.marine_buy_flags & bitf)
					if(bitf == (MARINE_CAN_BUY_R_POUCH|MARINE_CAN_BUY_L_POUCH))
						if(I.marine_buy_flags & MARINE_CAN_BUY_R_POUCH)
							I.marine_buy_flags &= ~MARINE_CAN_BUY_R_POUCH
						else
							I.marine_buy_flags &= ~MARINE_CAN_BUY_L_POUCH
					else if(bitf == (MARINE_CAN_BUY_ATTACHMENT|MARINE_CAN_BUY_ATTACHMENT2))
						if(I.marine_buy_flags & MARINE_CAN_BUY_ATTACHMENT)
							I.marine_buy_flags &= ~MARINE_CAN_BUY_ATTACHMENT
						else
							I.marine_buy_flags &= ~MARINE_CAN_BUY_ATTACHMENT2
					else
						I.marine_buy_flags &= ~bitf
				else
					to_chat(usr, span_warning("You can't buy things from this category anymore."))
					return

			var/obj/item/vended_item

			if(faction && ispath(idx, /obj/effect/modular_set))
				vended_item = new idx(loc, faction)
			else
				vended_item = new idx(loc)

			if(istype(vended_item)) // in case of spawning /obj
				usr.put_in_any_hand_if_possible(vended_item, warning = FALSE)

			if(icon_vend)
				flick(icon_vend, src)

			use_power(active_power_usage)

			if(bitf == MARINE_CAN_BUY_UNIFORM && ishumanbasic(usr))
				var/mob/living/carbon/human/H = usr
				var/headset_type = H.faction == FACTION_TERRAGOV ? /obj/item/radio/headset/mainship/marine : /obj/item/radio/headset/mainship/marine/rebel
				new headset_type(loc, H.assigned_squad, vendor_role)
				if(!istype(H.job, /datum/job/terragov/squad/engineer))
					new /obj/item/clothing/gloves/marine(loc, H.assigned_squad, vendor_role)
				if(istype(H.job, /datum/job/terragov/squad/leader))
					new /obj/item/hud_tablet(loc, vendor_role, H.assigned_squad)
				if(SSmapping.configs[GROUND_MAP].environment_traits[MAP_COLD])
					new /obj/item/clothing/mask/rebreather/scarf(loc)

			if(use_points)
				I.marine_points -= cost
			. = TRUE

	updateUsrDialog()

/obj/machinery/marine_selector/clothes
	name = "GHMME Automated Closet"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	vendor_role = /datum/job/terragov/squad/standard
	categories = list(
		CAT_STD = list(MARINE_CAN_BUY_UNIFORM),
		CAT_HEL = list(MARINE_CAN_BUY_HELMET),
		CAT_AMR = list(MARINE_CAN_BUY_ARMOR),
		CAT_BAK = list(MARINE_CAN_BUY_BACKPACK),
		CAT_WEB = list(MARINE_CAN_BUY_WEBBING),
		CAT_BEL = list(MARINE_CAN_BUY_BELT),
		CAT_POU = list(MARINE_CAN_BUY_R_POUCH,MARINE_CAN_BUY_L_POUCH),
		CAT_ATT = list(MARINE_CAN_BUY_ATTACHMENT,MARINE_CAN_BUY_ATTACHMENT2),
		CAT_MOD = list(MARINE_CAN_BUY_MODULE),
		CAT_ARMMOD = list(MARINE_CAN_BUY_ARMORMOD),
		CAT_MAS = list(MARINE_CAN_BUY_MASK),
	)

/obj/machinery/marine_selector/clothes/Initialize()
	. = ..()
	listed_products = GLOB.marine_clothes_listed_products

/obj/machinery/marine_selector/clothes/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/rebel
	faction = FACTION_TERRAGOV_REBEL

/obj/machinery/marine_selector/clothes/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_DELTA)


/obj/machinery/marine_selector/clothes/engi
	name = "GHMME Automated Engineer Closet"
	req_access = list(ACCESS_MARINE_ENGPREP)
	vendor_role = /datum/job/terragov/squad/engineer
	gives_webbing = FALSE

/obj/machinery/marine_selector/clothes/engi/Initialize()
	. = ..()
	listed_products = GLOB.engineer_clothes_listed_products

/obj/machinery/marine_selector/clothes/engi/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/engi/rebel
	req_access = list(ACCESS_MARINE_ENGPREP_REBEL)
	vendor_role = /datum/job/terragov/squad/engineer/rebel
	faction = FACTION_TERRAGOV_REBEL

/obj/machinery/marine_selector/clothes/engi/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/engi/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/engi/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/engi/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_DELTA)


/obj/machinery/marine_selector/clothes/medic
	name = "GHMME Automated Corpsman Closet"
	req_access = list(ACCESS_MARINE_MEDPREP)
	vendor_role = /datum/job/terragov/squad/corpsman
	gives_webbing = FALSE


/obj/machinery/marine_selector/clothes/medic/Initialize()
	. = ..()
	listed_products = GLOB.medic_clothes_listed_products

/obj/machinery/marine_selector/clothes/medic/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/medic/rebel
	req_access = list(ACCESS_MARINE_MEDPREP_REBEL)
	vendor_role = /datum/job/terragov/squad/corpsman/rebel
	faction = FACTION_TERRAGOV_REBEL

/obj/machinery/marine_selector/clothes/medic/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/medic/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/medic/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/medic/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_DELTA)


/obj/machinery/marine_selector/clothes/smartgun
	name = "GHMME Automated Smartgunner Closet"
	req_access = list(ACCESS_MARINE_SMARTPREP)
	vendor_role = /datum/job/terragov/squad/smartgunner
	gives_webbing = FALSE

/obj/machinery/marine_selector/clothes/smartgun/Initialize()
	. = ..()
	listed_products = GLOB.smartgunner_clothes_listed_products

/obj/machinery/marine_selector/clothes/smartgun/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/smartgun/rebel
	req_access = list(ACCESS_MARINE_SMARTPREP_REBEL)
	vendor_role = /datum/job/terragov/squad/smartgunner/rebel
	faction = FACTION_TERRAGOV_REBEL


/obj/machinery/marine_selector/clothes/smartgun/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/smartgun/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/smartgun/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/smartgun/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_DELTA)

/obj/machinery/marine_selector/clothes/leader
	name = "GHMME Automated Leader Closet"
	req_access = list(ACCESS_MARINE_LEADER)
	vendor_role = /datum/job/terragov/squad/leader
	gives_webbing = FALSE

/obj/machinery/marine_selector/clothes/leader/Initialize()
	. = ..()
	listed_products = GLOB.leader_clothes_listed_products

/obj/machinery/marine_selector/clothes/leader/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/leader/rebel
	req_access = list(ACCESS_MARINE_LEADER_REBEL)
	vendor_role = /datum/job/terragov/squad/leader/rebel
	faction = FACTION_TERRAGOV_REBEL


/obj/machinery/marine_selector/clothes/leader/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/leader/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/leader/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/leader/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_DELTA)

/obj/machinery/marine_selector/clothes/commander
	name = "GHMME Automated Commander Closet"
	req_access = list(ACCESS_MARINE_COMMANDER)
	vendor_role = /datum/job/terragov/command/fieldcommander
	lock_flags = JOB_LOCK
	gives_webbing = FALSE

/obj/machinery/marine_selector/clothes/commander/Initialize()
	. = ..()
	listed_products = list(
		/obj/effect/essentials_set/commander = list(CAT_STD, "Standard Commander kit ", 0, "white"),
		/obj/effect/modular_set/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "black"),
		/obj/effect/modular_set/scout = list(CAT_AMR, "Light Scout Jaeger kit", 0, "orange"),
		/obj/effect/modular_set/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "black"),
		/obj/effect/modular_set/eva = list(CAT_AMR, "Medium EVA Jaeger kit", 0, "black"),
		/obj/effect/modular_set/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "black"),
		/obj/effect/modular_set/eod = list(CAT_AMR, "Heavy EOD Jaeger kit", 0, "black"),
		/obj/item/clothing/suit/modular/pas11x = list(CAT_AMR, "PAS-11X pattern armor", 0, "orange"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "black"),
		/obj/item/storage/backpack/marine/standard = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/storage/large_holster/blade/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/storage/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "black"),
		/obj/item/belt_harness/marine = list(CAT_BEL, "Belt Harness", 0, "black"),
		/obj/item/armor_module/module/welding = list(CAT_HEL, "Jaeger welding module", 0, "orange"),
		/obj/item/armor_module/module/binoculars =  list(CAT_HEL, "Jaeger binoculars module", 0, "orange"),
		/obj/item/armor_module/module/antenna = list(CAT_HEL, "Jaeger Antenna module", 0, "orange"),
		/obj/item/clothing/head/headband/red = list(CAT_HEL, "FC Headband", 0, "black"),
		/obj/item/clothing/head/tgmcberet/fc = list(CAT_HEL, "FC Beret", 0, "black"),
		/obj/item/clothing/head/modular/marine/m10x/leader = list(CAT_HEL, "FC Helmet", 0, "black"),
		/obj/item/armor_module/storage/medical = list(CAT_MOD, "Medical Storage Module", 0, "black"),
		/obj/item/armor_module/storage/general = list(CAT_MOD, "General Purpose Storage Module", 0, "black"),
		/obj/item/armor_module/storage/engineering = list(CAT_MOD, "Engineering Storage Module", 0, "black"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/general/large = list(CAT_POU, "General pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Magazine pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Combat injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/effect/essentials_set/mimir = list(CAT_ARMMOD, "Mark 1 Mimir Resistance set", 0,"black"),
		/obj/item/armor_module/module/ballistic_armor = list(CAT_ARMMOD, "Ballistic armor module", 0,"black"),
		/obj/effect/essentials_set/tyr = list(CAT_ARMMOD, "Mark 1 Tyr extra armor set", 0,"black"),
		/obj/item/armor_module/module/better_shoulder_lamp = list(CAT_ARMMOD, "Baldur light armor module", 0,"black"),
		/obj/effect/essentials_set/vali = list(CAT_ARMMOD, "Vali chemical enhancement set", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Transparent gas mask", 0,"black"),
		/obj/item/clothing/mask/gas/tactical = list(CAT_MAS, "Tactical gas mask", 0,"black"),
		/obj/item/clothing/mask/gas/tactical/coif = list(CAT_MAS, "Tactical coifed gas mask", 0,"black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)

/obj/machinery/marine_selector/clothes/commander/loyalist
	faction = FACTION_TERRAGOV

/obj/machinery/marine_selector/clothes/commander/rebel
	req_access = list(ACCESS_MARINE_COMMANDER_REBEL)
	vendor_role = /datum/job/terragov/command/fieldcommander/rebel
	faction = FACTION_TERRAGOV_REBEL

/obj/machinery/marine_selector/clothes/synth
	name = "M57 Synthetic Equipment Vendor"
	desc = "An automated synthetic equipment vendor hooked up to a modest storage unit."
	icon_state = "synth"
	icon_vend = "synth-vend"
	icon_deny = "synth-deny"
	vendor_role = /datum/job/terragov/silicon/synthetic
	lock_flags = JOB_LOCK

/obj/machinery/marine_selector/clothes/synth/Initialize()
	. = ..()
	listed_products = GLOB.synthetic_clothes_listed_products

////////////////////// Gear ////////////////////////////////////////////////////////



/obj/machinery/marine_selector/gear
	name = "NEXUS Automated Equipment Rack"
	desc = "An automated equipment rack hooked up to a colossal storage unit."
	icon_state = "marinearmory"
	use_points = TRUE
	listed_products = list(
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical Grip", 0, "black"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red-dot sight", 0, "black"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil Compensator", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser Sight", 0, "black")
	)

/obj/machinery/marine_selector/gear/medic
	name = "NEXUS Automated Medical Equipment Rack"
	desc = "An automated medic equipment rack hooked up to a colossal storage unit."
	icon_state = "medic"
	vendor_role = /datum/job/terragov/squad/corpsman
	req_access = list(ACCESS_MARINE_MEDPREP)

/obj/machinery/marine_selector/gear/medic/Initialize()
	. = ..()
	listed_products = GLOB.medic_gear_listed_products

/obj/machinery/marine_selector/gear/medic/rebel
	req_access = list(ACCESS_MARINE_MEDPREP_REBEL)

/obj/machinery/marine_selector/gear/engi
	name = "NEXUS Automated Engineer Equipment Rack"
	desc = "An automated engineer equipment rack hooked up to a colossal storage unit."
	icon_state = "engineer"
	vendor_role = /datum/job/terragov/squad/engineer
	req_access = list(ACCESS_MARINE_ENGPREP)

/obj/machinery/marine_selector/gear/engi/Initialize()
	. = ..()
	listed_products = GLOB.engineer_gear_listed_products

/obj/machinery/marine_selector/gear/engi/rebel
	req_access = list(ACCESS_MARINE_ENGPREP_REBEL)


/obj/machinery/marine_selector/gear/smartgun
	name = "NEXUS Automated Smartgunner Equipment Rack"
	desc = "An automated smartgunner equipment rack hooked up to a colossal storage unit."
	icon_state = "smartgunner"
	vendor_role = /datum/job/terragov/squad/smartgunner
	req_access = list(ACCESS_MARINE_SMARTPREP)

/obj/machinery/marine_selector/gear/smartgun/Initialize()
	. = ..()
	listed_products = GLOB.smartgunner_gear_listed_products

/obj/machinery/marine_selector/gear/smartgun/rebel
	req_access = list(ACCESS_MARINE_SMARTPREP_REBEL)

/obj/machinery/marine_selector/gear/leader
	name = "NEXUS Automated Squad Leader Equipment Rack"
	desc = "An automated squad leader equipment rack hooked up to a colossal storage unit."
	icon_state = "squadleader"
	vendor_role = /datum/job/terragov/squad/leader
	req_access = list(ACCESS_MARINE_LEADER)

/obj/machinery/marine_selector/gear/leader/Initialize()
	. = ..()
	listed_products = GLOB.leader_gear_listed_products

/obj/machinery/marine_selector/gear/leader/rebel
	req_access = list(ACCESS_MARINE_LEADER_REBEL)


/obj/effect/essentials_set
	var/list/spawned_gear_list

/obj/effect/essentials_set/Initialize()
	. = ..()
	for(var/typepath in spawned_gear_list)
		if(spawned_gear_list[typepath])
			new typepath(loc, spawned_gear_list[typepath])
		else
			new typepath(loc)
	qdel(src)


/obj/effect/essentials_set/basic
	spawned_gear_list = list(
		/obj/item/clothing/under/marine,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
	)

/obj/effect/essentials_set/basicmodular
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/jaeger,
		/obj/item/clothing/suit/modular,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/basic_smartgunner
	spawned_gear_list = list(
		/obj/item/clothing/under/marine,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
	)

/obj/effect/essentials_set/basic_smartgunnermodular
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/jaeger,
		/obj/item/clothing/suit/modular,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/basic_squadleader
	spawned_gear_list = list(
		/obj/item/clothing/under/marine,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
	)

/obj/effect/essentials_set/basic_squadleadermodular
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/jaeger,
		/obj/item/clothing/suit/modular,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/basic_medic
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/corpsman,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
	)

/obj/effect/essentials_set/basic_medicmodular
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/jaeger,
		/obj/item/clothing/suit/modular,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/basic_engineer
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/engineer,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
	)

/obj/effect/essentials_set/basic_engineermodular
	spawned_gear_list = list(
		/obj/item/clothing/under/marine/jaeger,
		/obj/item/clothing/suit/modular,
		/obj/item/clothing/shoes/marine/full,
		/obj/item/storage/box/MRE,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/medic
	spawned_gear_list = list(
		/obj/item/bodybag/cryobag,
		/obj/item/defibrillator,
		/obj/item/healthanalyzer,
		/obj/item/roller/medevac,
		/obj/item/medevac_beacon,
		/obj/item/roller,
		/obj/item/tweezers,
		/obj/item/reagent_containers/hypospray/advanced/oxycodone,
		/obj/item/storage/firstaid/adv,
		/obj/item/clothing/glasses/hud/health,
	)

/obj/effect/essentials_set/engi
	spawned_gear_list = list(
		/obj/item/explosive/plastique,
		/obj/item/explosive/grenade/chem_grenade/razorburn_smol,
		/obj/item/clothing/glasses/welding,
		/obj/item/clothing/gloves/marine/insulated,
		/obj/item/cell/high,
		/obj/item/tool/shovel/etool,
		/obj/item/lightreplacer,
		/obj/item/circuitboard/general,
	)

/obj/effect/essentials_set/leader
	spawned_gear_list = list(
		/obj/item/explosive/plastique,
		/obj/item/beacon/supply_beacon,
		/obj/item/beacon/supply_beacon,
		/obj/item/beacon/orbital_bombardment_beacon,
		/obj/item/whistle,
		/obj/item/radio,
		/obj/item/binoculars/tactical,
		/obj/item/attachable/motiondetector,
		/obj/item/pinpointer/pool,
		/obj/item/clothing/glasses/hud/health,
	)

/obj/effect/essentials_set/commander
	spawned_gear_list = list(
		/obj/item/beacon/supply_beacon,
		/obj/item/beacon/orbital_bombardment_beacon,
		/obj/item/healthanalyzer,
		/obj/item/roller/medevac,
		/obj/item/medevac_beacon,
		/obj/item/whistle,
		/obj/item/attachable/motiondetector,
		/obj/item/clothing/suit/modular,
		/obj/item/facepaint/green,
	)

/obj/effect/essentials_set/synth
	spawned_gear_list = list(
		/obj/item/stack/sheet/plasteel/medium_stack,
		/obj/item/stack/sheet/metal/large_stack,
		/obj/item/lightreplacer,
		/obj/item/healthanalyzer,
		/obj/item/tool/handheld_charger,
		/obj/item/defibrillator,
		/obj/item/medevac_beacon,
		/obj/item/roller/medevac,
		/obj/item/bodybag/cryobag,
		/obj/item/reagent_containers/hypospray/advanced/oxycodone,
		/obj/item/tweezers,
	)

/obj/effect/modular_set
	///List of all gear to spawn
	var/list/spawned_gear_list = list()

/obj/effect/modular_set/Initialize(mapload, faction)
	. = ..()
	for(var/typepath in spawned_gear_list)
		var/item = new typepath(loc)
		if(!faction)
			continue
		if(ismodulararmorarmorpiece(item))
			var/obj/item/armor_module/armor/armorpiece = item
			armorpiece.limit_colorable_colors(faction)
			continue
		if(ismodularhelmet(item))
			var/obj/item/clothing/head/modular/helmet = item
			helmet.limit_colorable_colors(faction)
	qdel(src)


/obj/effect/modular_set/infantry
	desc = "A set of medium Infantry pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine,
		/obj/item/clothing/head/modular/marine/infantry,
		/obj/item/armor_module/armor/chest/marine,
		/obj/item/armor_module/armor/arms/marine,
		/obj/item/armor_module/armor/legs/marine,
	)

/obj/effect/modular_set/eva
	desc = "A set of medium EVA pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine/eva,
		/obj/item/armor_module/armor/chest/marine/eva,
		/obj/item/armor_module/armor/arms/marine/eva,
		/obj/item/armor_module/armor/legs/marine/eva,
	)

/obj/effect/modular_set/skirmisher
	desc = "A set of light Skirmisher pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine/skirmisher,
		/obj/item/armor_module/armor/chest/marine/skirmisher,
		/obj/item/armor_module/armor/arms/marine/skirmisher,
		/obj/item/armor_module/armor/legs/marine/skirmisher,
	)

/obj/effect/modular_set/scout
	desc = "A set of light Scout pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine/scout,
		/obj/item/armor_module/armor/chest/marine/skirmisher/scout,
		/obj/item/armor_module/armor/arms/marine/scout,
		/obj/item/armor_module/armor/legs/marine/scout,
	)

/obj/effect/modular_set/assault
	desc = "A set of heavy Assault pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine/assault,
		/obj/item/armor_module/armor/chest/marine/assault,
		/obj/item/armor_module/armor/arms/marine/assault,
		/obj/item/armor_module/armor/legs/marine/assault,
	)

/obj/effect/modular_set/eod
	desc = "A set of heavy EOD pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
		/obj/item/clothing/head/modular/marine/eod,
		/obj/item/armor_module/armor/chest/marine/assault/eod,
		/obj/item/armor_module/armor/arms/marine/eod,
		/obj/item/armor_module/armor/legs/marine/eod,
	)

/obj/effect/essentials_set/mimir
	desc = "A set of anti-gas gear setup to protect one from gas threats."
	spawned_gear_list = list(
		/obj/item/armor_module/module/mimir_environment_protection/mimir_helmet/mark1,
		/obj/item/clothing/mask/gas/tactical,
		/obj/item/armor_module/module/mimir_environment_protection/mark1,
	)

/obj/effect/essentials_set/vali
	desc = "A set of specialized gear for close-quarters combat and enhanced chemical effectiveness."
	spawned_gear_list = list(
		/obj/item/armor_module/module/chemsystem,
		/obj/item/storage/large_holster/blade/machete/full_harvester,
		/obj/item/paper/chemsystem,
	)

/obj/effect/essentials_set/tyr
	desc = "A set of specialized gear for improved close-quarters combat longevitiy."
	spawned_gear_list = list(
		/obj/item/armor_module/module/tyr_head,
		/obj/item/armor_module/module/tyr_extra_armor/mark1,
	)

#undef MARINE_CAN_BUY_UNIFORM
#undef MARINE_CAN_BUY_SHOES
#undef MARINE_CAN_BUY_HELMET
#undef MARINE_CAN_BUY_ARMOR
#undef MARINE_CAN_BUY_GLOVES
#undef MARINE_CAN_BUY_EAR
#undef MARINE_CAN_BUY_BACKPACK
#undef MARINE_CAN_BUY_R_POUCH
#undef MARINE_CAN_BUY_L_POUCH
#undef MARINE_CAN_BUY_BELT
#undef MARINE_CAN_BUY_GLASSES
#undef MARINE_CAN_BUY_MASK
#undef MARINE_CAN_BUY_ESSENTIALS

#undef MARINE_CAN_BUY_ALL
#undef MARINE_TOTAL_BUY_POINTS
#undef SQUAD_LOCK
#undef JOB_LOCK
