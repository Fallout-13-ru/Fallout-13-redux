//SSticker.current_state values
#define GAME_STATE_STARTUP 0
#define GAME_STATE_PREGAME 1
#define GAME_STATE_SETTING_UP 2
#define GAME_STATE_PLAYING 3
#define GAME_STATE_FINISHED 4


//SD and evac
#define NUKE_EXPLOSION_INACTIVE 0
#define NUKE_EXPLOSION_ACTIVE 1
#define NUKE_EXPLOSION_IN_PROGRESS 2
#define NUKE_EXPLOSION_FINISHED 3

#define SELF_DESTRUCT_ROD_STARTUP_TIME 20 MINUTES

#define SELF_DESTRUCT_MACHINE_INACTIVE 0
#define SELF_DESTRUCT_MACHINE_ACTIVE 1
#define SELF_DESTRUCT_MACHINE_ARMED 2

#define EVACUATION_STATUS_STANDING_BY 0
#define EVACUATION_STATUS_INITIATING 1
#define EVACUATION_STATUS_IN_PROGRESS 2
#define EVACUATION_STATUS_COMPLETE 3

#define EVACUATION_AUTOMATIC_DEPARTURE 3 MINUTES //All pods automatically depart in 10 minutes, unless they are full or unable to launch for some reason.
#define EVACUATION_ESTIMATE_DEPARTURE ((evac_time + EVACUATION_AUTOMATIC_DEPARTURE - world.time) * 0.1)
#define EVACUATION_POD_LAUNCH_COOLDOWN 5 SECONDS

#define FLAGS_EVACUATION_DENY (1<<0)
#define FLAGS_SELF_DESTRUCT_DENY (1<<1)
#define FLAGS_SDEVAC_TIMELOCK (1<<2)


//Mode defines
#define MODE_INFESTATION (1<<0)
#define MODE_NO_LATEJOIN (1<<1)
#define MODE_HAS_FINISHED (1<<2)
#define MODE_FOG_ACTIVATED (1<<3)
#define MODE_INFECTION (1<<4)
#define MODE_HUMAN_ANTAGS (1<<5)
#define MODE_LZ_SHUTTERS (1<<6)
#define MODE_XENO_SPAWN_PROTECT (1<<7)
#define MODE_XENO_RULER (1<<8)
#define MODE_PSY_POINTS (1<<9)
#define MODE_PSY_POINTS_ADVANCED (1<<10)
#define MODE_HIJACK_POSSIBLE (1<<11)
#define MODE_DEAD_GRAB_FORBIDDEN (1<<12)
#define MODE_SILO_RESPAWN (1<<13)
#define MODE_HUMAN_ONLY (1<<14)
#define MODE_TWO_HUMAN_FACTIONS	(1<<15)
#define MODE_SILOABLE_BODIES (1<<16)
#define MODE_WIN_POINTS (1<<17)

#define MODE_LANDMARK_RANDOM_ITEMS (1<<0)
#define MODE_LANDMARK_SPAWN_XENO_TUNNELS (1<<1)
#define MODE_LANDMARK_SPAWN_MAP_ITEM (1<<2)
#define MODE_LANDMARK_SPAWN_XENO_TURRETS (1<<3)
#define MODE_LANDMARK_SPAWN_SPECIFIC_SHUTTLE_CONSOLE (1<<4)

#define MODE_INFESTATION_X_MAJOR "Xenomorph Major Victory"
#define MODE_INFESTATION_M_MAJOR "Marine Major Victory"
#define MODE_INFESTATION_X_MINOR "Xenomorph Minor Victory"
#define MODE_INFESTATION_M_MINOR "Marine Minor Victory"
#define MODE_INFESTATION_DRAW_DEATH "DRAW: Mutual Annihilation"

#define MODE_GENERIC_DRAW_NUKE "DRAW: Nuclear Explosion"

#define MODE_CIVIL_WAR_LOYALIST_MAJOR "Loyalist Major Victory"
#define MODE_CIVIL_WAR_REBEL_MAJOR "Rebel Major Victory"
#define MODE_CIVIL_WAR_DRAW "Civil War Draw"

#define CRASH_EVAC_NONE "CRASH_EVAC_NONE"
#define CRASH_EVAC_INPROGRESS "CRASH_EVAC_INPROGRESS"
#define CRASH_EVAC_COMPLETED "CRASH_EVAC_COMPLETED"
#define CRASH_NUKE_NONE "CRASH_NUKE_NONE"
#define CRASH_NUKE_INPROGRESS "CRASH_NUKE_INPROGRESS"
#define CRASH_NUKE_COMPLETED "CRASH_NUKE_COMPLETED"

#define SURVIVOR_WEAPONS list(\
				list(/obj/item/weapon/gun/smg/mp7, /obj/item/ammo_magazine/smg/mp7),\
				list(/obj/item/weapon/gun/shotgun/double/sawn, /obj/item/ammo_magazine/handful/buckshot),\
				list(/obj/item/weapon/gun/smg/uzi, /obj/item/ammo_magazine/smg/uzi),\
				list(/obj/item/weapon/gun/smg/m25, /obj/item/ammo_magazine/smg/m25),\
				list(/obj/item/weapon/gun/rifle/m16, /obj/item/ammo_magazine/rifle/m16),\
				list(/obj/item/weapon/gun/shotgun/pump/bolt, /obj/item/ammo_magazine/rifle/bolt),\
				list(/obj/item/weapon/gun/shotgun/pump/lever, /obj/item/ammo_magazine/packet/magnum))


#define LATEJOIN_LARVA_DISABLED 0


//Balance defines
#define MARINE_GEAR_SCALING 30

#define MAX_TUNNELS_PER_MAP 10

#define FOG_DELAY_INTERVAL 40 MINUTES

#define EVACUATION_TIME_LOCK 30 MINUTES

#define DISTRESS_TIME_LOCK 10 MINUTES

#define SHUTTLE_HIJACK_LOCK 30 MINUTES

#define COOLDOWN_COMM_REQUEST 5 MINUTES
#define COOLDOWN_COMM_MESSAGE 1 MINUTES
#define COOLDOWN_COMM_CENTRAL 30 SECONDS

#define SUPPLY_POINT_MARINE_SPAWN 2.5

#define XENO_AFK_TIMER 5 MINUTES

#define DEATHTIME_CHECK(M) ((world.time - M.timeofdeath) < SSticker.mode?.respawn_time)
#define DEATHTIME_MESSAGE(M) to_chat(M, span_warning("You have been dead for [(world.time - M.timeofdeath) * 0.1] second\s.</span><br><span class='warning'>You must wait [SSticker.mode?.respawn_time * 0.1] seconds before rejoining the game!"))

#define COUNT_IGNORE_HUMAN_SSD (1<<0)
#define COUNT_IGNORE_XENO_SSD (1<<1)
#define COUNT_IGNORE_XENO_SPECIAL_AREA (1<<2)

#define COUNT_IGNORE_ALIVE_SSD (COUNT_IGNORE_HUMAN_SSD|COUNT_IGNORE_XENO_SSD)

#define SILO_PRICE 800
#define XENO_TURRET_PRICE 100
#define XENO_KING_PRICE 1800
//How many psych point one gen gives per person on the server
#define BASE_PSYCH_POINT_OUTPUT 0.008
//How many psy points are gave for each marine psy drained
#define PSY_DRAIN_REWARD 60
//How many psy points are gave every 5 second by a cocoon
#define COCOON_PSY_POINTS_REWARD 2

#define INVOKE_KING_TIME_LOCK 90 MINUTES

/// How each alive marine contributes to burrower larva output per minute. So with one pool, 15 marines are giving 0.375 points per minute, so it's a new xeno every 22 minutes
#define SILO_BASE_OUTPUT_PER_MARINE 0.035
/// This is used to ponderate the number of silo, so to reduces the diminishing returns of having more and more silos
#define SILO_OUTPUT_PONDERATION 1.75
//Time (after round start) before siloless timer can start
#define MINIMUM_TIME_SILO_LESS_COLLAPSE 45 MINUTES

#define INFESTATION_MARINE_DEPLOYMENT 0
#define INFESTATION_MARINE_CRASHING 1
#define INFESTATION_DROPSHIP_CAPTURED_XENOS 2

#define COCOONED_DEATH "cocoon_death"
#define SILO_DEATH "silo_death"
#define HEADBITE_DEATH "headbite_death"

#define DISTRESS_LARVA_POINTS_NEEDED 8
#define HUNT_LARVA_POINTS_NEEDED 8
#define CRASH_LARVA_POINTS_NEEDED 10

#define FREE_XENO_AT_START 2

#define MAX_UNBALANCED_RATIO_TWO_HUMAN_FACTIONS 1.2
