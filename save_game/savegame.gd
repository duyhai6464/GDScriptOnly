class_name SavedGame extends Resource

@export var playerName: String = 'Player' + str(sqrt(randi())).replace('.', ''):
	set(pname):
		if pname != playerName:
			playerName = pname
			playerNameChanged.emit()
@export var inputOption: int = 0:
	set(input):
		if input != inputOption:
			inputOption = input
			inputOptionChanged.emit()
@export var soundOn: bool = true
@export var music: int = 1
@export var lang: String = 'en'
@export var privacy_consent: bool = false

const LARGE_PRIME: int = 9999991
const MULTIPLIER: int = 4762117
const INVERSE_MULTIPLIER: int = 3963049

static func randomize_seed() -> int:
	return randi_range(1, 100000)

static func get_coin(_coin: int, _seed: int) -> int:
	return ((_coin - _seed) * INVERSE_MULTIPLIER) % LARGE_PRIME

var g_seed: int = 0
var g_coin: int = 0
@export var gold: int = 0

func get_g_coin() -> int:
	var real_coin := get_coin(g_coin, g_seed)
	if real_coin != gold:
		SignalBus.cheating_detected.emit('gold_cheating_detected')
		gold = real_coin
	return real_coin

func add_g_coin(amount: int):
	var current_coin := get_g_coin()
	g_seed = randomize_seed()
	g_coin = (current_coin + amount) * MULTIPLIER % LARGE_PRIME + g_seed
	gold += amount
	g_coinChanged.emit()

var d_seed: int = 0
var d_coin: int = 0
@export var diamond: int = 0

func get_d_coin() -> int:
	var real_coin := get_coin(d_coin, d_seed)
	if real_coin != diamond:
		SignalBus.cheating_detected.emit('diamond_cheating_detected')
		diamond = real_coin
	return real_coin

func add_d_coin(amount: int):
	var current_coin := get_d_coin()
	d_seed = randomize_seed()
	d_coin = (current_coin + amount) * MULTIPLIER % LARGE_PRIME + d_seed
	diamond += amount
	d_coinChanged.emit()

@export var favourite_color_id: int = 0
var eye_skin_id: int = 0
var square_skin_id: int = 1
var inventory: Dictionary
const default_inventory: Dictionary = {
	0 : {0: true},
	1 : {0: true},
	2 : {1: true},
}
var sales_percent: Array
@export var special_shop: Array[Vector2i] = []
@export var is_buy_special: Array[bool] = []
@export var time_refresh: float = 0
@export var skip_tutorial: bool = false
@export var last_time_saved: int = 0

var play_game_save: String = ''
var diamond_history: Array = []
var consumed_diamond_save: Array = []

signal inputOptionChanged
signal playerNameChanged
signal g_coinChanged
signal d_coinChanged
signal inventory_add(key, id)

func get_inventory(key: int) -> Dictionary:
	var raw = inventory.get_or_add(key, {})
	var id_dict: Dictionary = default_inventory.get_or_add(key, {}).duplicate()
	if typeof(raw) == TYPE_ARRAY:
		for id in raw:
			id_dict[id] = true
	elif typeof(raw) == TYPE_DICTIONARY:
		id_dict.merge(raw)
	inventory[key] = id_dict
	return id_dict

static var save_thread_id : int = -1

func save() -> void:
	if save_thread_id != -1 and not WorkerThreadPool.is_task_completed(save_thread_id):
		WorkerThreadPool.wait_for_task_completion(save_thread_id)
	save_thread_id = WorkerThreadPool.add_task(func ():
		last_time_saved = Time.get_unix_time_from_system()
		update_encode_data()
		ResourceSaver.save(self, 'user://savegamedata.tres')
	)

static func load_or_create() -> SavedGame:
	var savedgame: SavedGame
	if FileAccess.file_exists('user://savegamedata.tres'):
		savedgame = load('user://savegamedata.tres')
		if savedgame.verify():
			savedgame.time_refresh -= (Time.get_unix_time_from_system() - savedgame.last_time_saved) / 6
	else:
		savedgame = SavedGame.new()
		if OS.get_locale_language() == 'vi':
			savedgame.lang = 'vi'
			savedgame.privacy_consent = true
	savedgame.save()
	return savedgame

@export var key: String = '287_175_424_597'
@export var edt: String
var verify_key: int = 932474324567

func xor_to_key(bytes: PackedByteArray, key: int) -> PackedByteArray:
	var encrypted_bytes = PackedByteArray()
	for byte in bytes:
		var encrypted_byte: int = byte ^ key
		encrypted_bytes.append(encrypted_byte)
	return encrypted_bytes


func update_encode_data():
	var bytes := var_to_bytes([Vector2i(g_coin, g_seed), Vector2i(d_coin, d_seed),
	[eye_skin_id, square_skin_id], inventory, sales_percent,
	play_game_save, diamond_history, consumed_diamond_save])
	var xor_bytes := xor_to_key(bytes, verify_key)
	edt = var_to_str(xor_bytes).trim_prefix('PackedByteArray')


func verify():
	var data = str_to_var('PackedByteArray' + edt)
	if data == null or data is not PackedByteArray:
		return false
	var xor_bytes := xor_to_key(data, verify_key)
	if xor_bytes == null or xor_bytes is not PackedByteArray:
		return false
	var save_data = bytes_to_var(xor_bytes)
	if typeof(save_data) == TYPE_ARRAY:
		if save_data.size() > 0:
			if typeof(save_data[0]) == TYPE_VECTOR2I:
				g_coin = save_data[0].x
				g_seed = save_data[0].y
			else:
				g_seed = 0
				g_coin = 0
		if save_data.size() > 1:
			if typeof(save_data[1]) == TYPE_VECTOR2I:
				d_coin = save_data[1].x
				d_seed = save_data[1].y
			else:
				d_seed = 0
				d_coin = 0
		if save_data.size() > 2:
			if typeof(save_data[2]) == TYPE_ARRAY:
				eye_skin_id = save_data[2][0]
				square_skin_id = save_data[2][1]
			else:
				eye_skin_id = 0
				square_skin_id = 1
		if save_data.size() > 3:
			if typeof(save_data[3]) == TYPE_DICTIONARY:
				inventory = save_data[3]
			else:
				inventory = default_inventory.duplicate()
		if save_data.size() > 4:
			if typeof(save_data[4]) == TYPE_ARRAY:
				sales_percent = save_data[4]
			else:
				sales_percent = []
		if save_data.size() > 5:
			if typeof(save_data[5]) == TYPE_STRING:
				play_game_save = save_data[5]
		if save_data.size() > 6:
			if typeof(save_data[6]) == TYPE_ARRAY:
				diamond_history = save_data[6]
		if save_data.size() > 7:
			if typeof(save_data[7]) == TYPE_ARRAY:
				consumed_diamond_save = save_data[7]
		print('_save_data_loaded_',save_data)
		return true
	return false

@export_group('Stat', 'stat_')
@export var stat_kills: int = 0
@export var stat_zones: int = 0
@export var stat_moneys: int = 0
@export var stat_death: int = 0
@export var stat_time: float = 0
@export var stat_best_score: Dictionary = {}
@export var achievements: Dictionary = {}
