class_name data_item_dict_prop extends RefCounted

const CONFIG := preload("res://game/global_config.gd")

const EYE: int = CONFIG.TypeItem.SKIN_EYE
const EXPLODE: int = CONFIG.TypeItem.SKIN_EXPLODE
const ZONE: int = CONFIG.TypeItem.SKIN_ZONE
const MONEYBOX: int = CONFIG.TypeItem.MONEY_BOX
const TRADEBOX: int = CONFIG.TypeItem.TRADE_BOX

const GOLD: int = CONFIG.TypeMoney.GOLD
const DIAMOND: int = CONFIG.TypeMoney.DIAMOND
const ADS: int = CONFIG.TypeMoney.ADS
const CASH: int = CONFIG.TypeMoney.CASH

const dict_prop: Dictionary = {
	# EYE
	Vector2i(EYE, 0): [
		0,
		GOLD,
		'_basic_',
		'_basic_eye_info_'
	],
	Vector2i(EYE, 1): [
		10000,
		GOLD,
		'_blue_eye_',
		'_blue_eye_info_'
	],
	Vector2i(EYE, 2): [
		13500,
		GOLD,
		'_loading_eye_',
		'_loading_eye_info_'
	],
	Vector2i(EYE, 3): [
		11500,
		GOLD,
		'_eyecog_',
		'_eyecog_info_'
	],
	Vector2i(EYE, 4): [
		22,
		DIAMOND,
		'_shiny_eye_',
		'_shiny_eye_info_'
	],
	Vector2i(EYE, 5): [
		20,
		DIAMOND,
		'_sparkle_eye_',
		'_sparkle_eye_info_'
	],
	Vector2i(EYE, 6): [
		20,
		DIAMOND,
		'_bionic_eye_',
		'_bionic_eye_info_'
	],
	Vector2i(EYE, 7): [
		18,
		DIAMOND,
		'_bionic_cyan_eye_',
		'_bionic_cyan_eye_info_'
	],
	Vector2i(EYE, 8): [
		15000,
		GOLD,
		'_decision_eye_',
		'_decision_eye_info_'
	],
	Vector2i(EYE, 9): [
		30,
		DIAMOND,
		'_electric_eye_',
		'_electric_eye_info_'
	],
	Vector2i(EYE, 10): [
		30000,
		GOLD,
		'_illuminati_eye_',
		'_illuminati_eye_info_'
	],
	Vector2i(EYE, 11): [
		12500,
		GOLD,
		'_scan_eye_',
		'_scan_eye_info_'
	],
	Vector2i(EYE, 12): [
		14000,
		GOLD,
		'_scan_eye_2_',
		'_scan_eye_2_info_'
	],
	Vector2i(EYE, 13): [
		11111,
		GOLD,
		'_money_eye_',
		'_money_eye_info_'
	],
	Vector2i(EYE, 14): [
		23000,
		GOLD,
		'_spy_eye_',
		'_spy_eye_info_'
	],
	Vector2i(EYE, 15): [
		24000,
		GOLD,
		'_star_eye_',
		'_star_eye_info_'
	],

	# SKIN_EXPLODE
	Vector2i(EXPLODE, 0): [
		0,
		GOLD,
		'_basic_',
		'_basic_explode_info_'
	],

	# SKIN_ZONE
	Vector2i(ZONE, 1): [
		0,
		GOLD,
		'_basic_',
		'_basic_zone_info_'
	],
	Vector2i(ZONE, 2): [
		30000,
		GOLD,
		'_zone_water_',
		'_zone_water_info_'
	],
	Vector2i(ZONE, 3): [
		22500,
		GOLD,
		'_zone_wood_grain_',
		'_zone_wood_grain_info_'
	],
	Vector2i(ZONE, 4): [
		25000,
		GOLD,
		'_zone_dust_',
		'_zone_dust_info_'
	],

	# MONEY_BOX
	Vector2i(MONEYBOX, 0): [
		1,
		ADS,
		'_gold_box_',
		'_gold_box_info_'
	],
	Vector2i(MONEYBOX, 1): [
		2,
		ADS,
		'_big_gold_box_',
		'_big_gold_box_info_'
	],
	Vector2i(MONEYBOX, 2): [
		1,
		DIAMOND,
		'_big_gold_box_by_diamond_',
		'_big_gold_box_by_diamond_info_'
	],
	Vector2i(MONEYBOX, 3): [
		1000,
		GOLD,
		'_gold_box_by_gold_',
		'_gold_box_by_gold_info_'
	],

	# TRADE_BOX
	Vector2i(TRADEBOX, 0): [
		1,
		DIAMOND,
		'_trade_1000_gold_',
		'_trade_1000_gold_info_'
	],
	Vector2i(TRADEBOX, 1): [
		10,
		DIAMOND,
		'_trade_10000_gold_',
		'_trade_10000_gold_info_'
	],
	Vector2i(TRADEBOX, 2): [
		100,
		DIAMOND,
		'_trade_100000_gold_',
		'_trade_100000_gold_info_'
	],
	Vector2i(TRADEBOX, 10): [
		1,
		CASH,
		'_trade_1_diamond_',
		'_trade_1_diamond_info_'
	],
	Vector2i(TRADEBOX, 11): [
		1,
		CASH,
		'_trade_2_diamond_',
		'_trade_2_diamond_info_'
	],
	Vector2i(TRADEBOX, 12): [
		1,
		CASH,
		'_trade_3_diamond_',
		'_trade_3_diamond_info_'
	],
}

static var rseed := randi_range(1, 100000)
static var dict_money_item: Dictionary = {}

static func get_dict() -> Dictionary:
	var dict: Dictionary = {}
	for key in (dict_prop.keys() as Array[Vector2i]):
		var dict_type := dict.get_or_add(key.x, {}) as Dictionary
		var item := data_item.from_array(dict_prop[key])
		dict_type[key.y] = item
		if item.money > 0 and item.money_type < ADS:
			dict_money_item[item.money + rseed] = item.money_type
	return dict

static func check_valid(amount: int, money_type: int):
	return dict_money_item.get(amount + rseed, -1) == money_type
