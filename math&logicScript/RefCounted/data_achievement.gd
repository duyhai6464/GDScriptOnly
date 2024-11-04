class_name data_achievement extends RefCounted

const CONFIG := preload("res://game/global_config.gd")

const GOLD: int = CONFIG.TypeMoney.GOLD
const DIAMOND: int = CONFIG.TypeMoney.DIAMOND

const achievement_goal := {
	'_3_game_3_mode_': 3,
	'_god_killer_': 15,
	'_map_owner_': 40,
	'_10K_point_free_': 10000,
	'_old_hunter_': 25,
	'_old_survival_': 25,
	'_old_free_': 100,
	'_mystery_box_': 10
}

const icons := {
	'_3_game_3_mode_': preload("res://game/Game_asset/achievement/medals.png"),
	'_god_killer_': preload("res://game/Game_asset/ingame/killer_3.png"),
	'_map_owner_': preload("res://game/Game_asset/achievement/book.png"),
	'_10K_point_free_': preload("res://game/Game_asset/achievement/muscle.png"),
	'_old_hunter_': preload("res://game/Game_asset/achievement/hunter-target.png"),
	'_old_survival_': preload("res://game/Game_asset/achievement/survival-ekg.png"),
	'_old_free_': preload("res://game/Game_asset/achievement/free-muscles.png"),
	'_mystery_box_': preload("res://game/Game_asset/achievement/treasure-chest.png"),
}

const rewards := {
	'_3_game_3_mode_': 1000,
	'_god_killer_': 2500,
	'_map_owner_': 2500,
	'_10K_point_free_': 2500,
	'_old_hunter_': 5000,
	'_old_survival_': 5000,
	'_old_free_': 5000,
	'_mystery_box_': 1000,
}

const achievementId := {
	'_3_game_3_mode_': 'CgkIyIeguusWEAIQAA',
	'_god_killer_': 'CgklyleguusWEAlQDg',
	'_map_owner_': 'CgklyleguusWEAlQDw',
	'_10K_point_free_': 'CgklyleguusWEAlQEA',
	'_old_hunter_': 'CgkIyIeguusWEAIQCQ',
	'_old_survival_': 'CgkIyIeguusWEAIQCg',
	'_old_free_': 'CgkIyIeguusWEAIQCw',
	'_mystery_box_': 'CgkIyIeguusWEAIQDQ',
}

const aid := {
	'CgkIyIeguusWEAIQAA': '_3_game_3_mode_',
	'CgklyleguusWEAlQDg': '_god_killer_',
	'CgklyleguusWEAlQDw': '_map_owner_',
	'CgklyleguusWEAlQEA': '_10K_point_free_',
	'CgkIyIeguusWEAIQCQ': '_old_hunter_',
	'CgkIyIeguusWEAIQCg': '_old_survival_',
	'CgkIyIeguusWEAIQCw': '_old_free_',
	'CgkIyIeguusWEAIQDQ': '_mystery_box_',
}

const leaderboardId := {
	'b': 'CgkIyIeguusWEAIQBw',
	's': 'CgkIyIeguusWEAIQBg',
	'f': 'CgkIyIeguusWEAIQAQ',
}
