extends Node

signal request_background_color(color: Color, duration: float)
signal freeze_start
signal freeze_finish

signal request_scene(path: String)
signal wait_load_scene(path: String)
signal cheating_detected(detail: String)
signal request_popup_nofi(imgID: int, message: String)
signal buy_diamond(diamond: int, ojson: String)

signal new_score_record(id: String, score: int)
signal new_achievement_stack(id: String, score: int)

@onready var savedgame = GlobalConfig.savedgame as SavedGame

const CONNECTION_ERROR = preload("res://game/Game_asset/ads_img/connection_error.png")
const MONEY_TYPE_DIAMOND = preload("res://game/Game_asset/ingame/money_type_diamond.png")
const MONEY_TYPE_GOLD = preload("res://game/Game_asset/ingame/money_type_gold.png")
const GOOGLE_PLAY_GAMES = preload("res://Fonts/icon/google-play-games.png")
const STOP = preload("res://Fonts/icon/stop.png")

var isfreeze: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_process(false)
	request_scene.connect(on_request_scene)
	wait_load_scene.connect(on_wait_load_scene)
	cheating_detected.connect(on_cheating_detected)
	freeze_start.connect(on_freeze_start)
	freeze_finish.connect(on_freeze_finish)

	GooglePlayServices.load_failed.connect(on_play_load_failed)
	GooglePlayServices.load_success.connect(on_play_load_success)
	GooglePlayServices.save_failed.connect(on_play_save_failed)
	GooglePlayServices.save_success.connect(on_play_save_success)
	GooglePlayServices.sign_in_success.connect(on_play_sign_in_success)
	GooglePlayServices.sign_out_success.connect(on_play_sign_out_success)
	popup_nofi = preload("res://ui_menu/Component/popup_nofi.tscn").instantiate()
	add_child(popup_nofi)
	request_popup_nofi.connect(on_popup_nofi_show_request)
	buy_diamond.connect(on_buy_diamond)

	BillingControl.purchase_consumed_error.connect(on_billing_purchase_consumed_error)
	BillingControl.purchase_consumed.connect(on_billing_purchase_consumed)

	new_score_record.connect(on_new_score_record)
	new_achievement_stack.connect(on_new_achievement_stack)

var scene_load_status : ResourceLoader.ThreadLoadStatus
var path_to_scene : String
var process: Array = []

func on_request_scene(path: String):
	ResourceLoader.load_threaded_request(path)

func on_wait_load_scene(path: String):
	path_to_scene = path
	set_process(true)

func _process(delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(path_to_scene, process)
	match scene_load_status:
		ResourceLoader.THREAD_LOAD_LOADED:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(path_to_scene))
			set_process(false)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			request_scene.emit(path_to_scene)

func on_freeze_start():
	isfreeze = true
	await get_tree().create_timer(10).timeout
	if isfreeze:
		freeze_finish.emit()

func on_freeze_finish():
	isfreeze = false

var popup_nofi: PopupNofi
func on_popup_nofi_show_request(id: int, text: String):
	if popup_nofi == null:
		return
	match id:
		0:
			popup_nofi.set_nofi_texture(MONEY_TYPE_GOLD)
		1:
			popup_nofi.set_nofi_texture(MONEY_TYPE_DIAMOND)
		-1:
			popup_nofi.set_nofi_texture(CONNECTION_ERROR)
		10:
			popup_nofi.set_nofi_texture(GOOGLE_PLAY_GAMES)
		99:
			popup_nofi.set_nofi_texture(STOP)
		_:
			popup_nofi.set_nofi_texture(null)
	popup_nofi.set_nofi_text(text)
	popup_nofi.popup_enter()

var warning_cheat_gold_caught = 0
func on_cheating_detected(detail: String):
	match detail:
		'diamond_cheating_detected':
			if GooglePlayServices.isSignedIn():
				GooglePlayServices.loadData('ZoneConquest')
		'gold_cheating_detected':
			match warning_cheat_gold_caught:
				1:
					var gold = savedgame.get_g_coin()
					savedgame.add_g_coin(-gold)
				2:
					var gold = savedgame.get_g_coin()
					savedgame.add_g_coin(-gold)
					savedgame.inventory = SavedGame.default_inventory.duplicate()
					savedgame.eye_skin_id = 0
					savedgame.square_skin_id = 1
			warning_cheat_gold_caught += 1
	print('cheating_caught: '+ detail)
	request_popup_nofi.emit(99, 'cheating caught: ' + detail)

var play_load_retry_count: int = 0
var play_game_data: Dictionary = {}
func on_play_load_success(data: Dictionary):
	play_load_retry_count = 0
	play_game_data = data
	var diamond_history = data.get_or_add('diamond_history', [])
	var diamond = data.get_or_add('diamond', [0, 0])
	if typeof(diamond) == TYPE_ARRAY and len(diamond) == 2 and typeof(
		diamond_history) == TYPE_ARRAY and len(diamond_history) > 0:
			var currunt_diamond := savedgame.get_d_coin()
			savedgame.d_seed = diamond[0]
			savedgame.d_coin = diamond[1]
			savedgame.diamond = SavedGame.get_coin(diamond[1], diamond[0])
			if savedgame.diamond != currunt_diamond:
				savedgame.d_coinChanged.emit()
	else:
		savedgame.d_seed = 0
		savedgame.d_coin = 0
		savedgame.diamond = 0
	var gold = data.get_or_add('gold', [0, 0])
	if typeof(gold) == TYPE_ARRAY and len(gold) == 2:
		var game_gold := savedgame.get_g_coin()
		var gold_in_cloud := SavedGame.get_coin(gold[1], gold[0])
		if gold_in_cloud > game_gold:
			savedgame.g_seed = gold[0]
			savedgame.g_coin = gold[1]
			savedgame.gold = gold_in_cloud
			savedgame.g_coinChanged.emit()
		else:
			gold[0] = savedgame.g_seed
			gold[1] = savedgame.g_coin

	var inventory = data.get('inventory')
	if typeof(inventory) == TYPE_ARRAY and len(inventory) > 0:
		for key in inventory:
			if typeof(key) == TYPE_ARRAY and len(key) == 2:
				var inven := savedgame.get_inventory(key[0])
				inven[key[1]] = true
				savedgame.inventory_add.emit(key[0], key[1])

func on_play_load_failed():
	play_load_retry_count += 1
	await get_tree().create_timer(pow(2, play_load_retry_count))
	if play_load_retry_count <= 0:
		return
	if savedgame.diamond_history.size() > 0:
		_buy_diamond_callback()

func _buy_diamond_callback():
	GooglePlayServices.loadData('ZoneConquest')
	print('GooglePlayServices load save when failed ZoneConquest')
	await GooglePlayServices.load_success
	print('GooglePlayServices load_success when failed ZoneConquest')
	var diamond_history := play_game_data.get_or_add('diamond_history', []) as Array
	var diamond := play_game_data.get_or_add('diamond', [0, 0]) as Array
	var diamond_in_cloud := SavedGame.get_coin(diamond[1], diamond[0])
	savedgame.d_seed = diamond[0]
	savedgame.d_coin = diamond[1]
	savedgame.diamond = diamond_in_cloud
	for diamond_history_json in savedgame.diamond_history.duplicate():
		var jsondata = JSON.parse_string(diamond_history_json)
		if typeof(jsondata) == TYPE_DICTIONARY:
			if savedgame.diamond_history.size() <= 0:
				break
			savedgame.diamond_history.pop_front()
			var diamond_payment := jsondata as Dictionary
			if diamond_payment in diamond_history:
				continue
			diamond_history.append(diamond_payment)
			savedgame.add_d_coin(diamond_payment['diamond'])
	diamond[0] = savedgame.d_seed
	diamond[1] = savedgame.d_coin
	savedgame.save()
	GooglePlayServices.saveData('ZoneConquest', play_game_data)

func on_play_save_failed():
	savedgame.play_game_save = JSON.stringify(play_game_data)

func on_play_save_success():
	savedgame.play_game_save = ''

func on_buy_diamond(d: int, ojson: String):
	var oj = JSON.parse_string(ojson)
	if typeof(oj) != TYPE_DICTIONARY:
		return
	var jsondata := oj as Dictionary
	if not jsondata.has_all(['orderId', 'packageName', 'productId', 'purchaseState', 'purchaseToken']):
		return
	savedgame.consumed_diamond_save.append(jsondata['purchaseToken'])
	var new_diamond_payment = {
		'json': ojson,
		'diamond': d
	}
	savedgame.diamond_history.append(JSON.stringify(new_diamond_payment))
	GooglePlayServices.loadData('ZoneConquest')
	print('GooglePlayServices load save ZoneConquest')
	await GooglePlayServices.load_success
	print('GooglePlayServices load_success ZoneConquest')
	freeze_finish.emit()
	var diamond_history := play_game_data.get_or_add('diamond_history', []) as Array
	if new_diamond_payment in diamond_history:
		return
	diamond_history.append(new_diamond_payment)
	if savedgame.diamond_history.size() > 0:
		savedgame.diamond_history.pop_front()
	var diamond := play_game_data.get_or_add('diamond', [0, 0]) as Array
	var diamond_in_cloud := SavedGame.get_coin(diamond[1], diamond[0])
	savedgame.d_seed = diamond[0]
	savedgame.d_coin = diamond[1]
	savedgame.diamond = diamond_in_cloud
	savedgame.add_d_coin(d)
	request_popup_nofi.emit(1, str(d) + tr('_earn_reward_'))
	savedgame.save()
	diamond[0] = savedgame.d_seed
	diamond[1] = savedgame.d_coin
	GooglePlayServices.saveData('ZoneConquest', play_game_data)

func on_play_sign_in_success(data_sign_in: Dictionary):
	if savedgame.play_game_save != '':
		var json = JSON.parse_string(savedgame.play_game_save)
		if json:
			GooglePlayServices.saveData('ZoneConquest', json)
			play_game_data = json
	else:
		GooglePlayServices.loadData('ZoneConquest')
	if savedgame.diamond_history.size() > 0:
		_buy_diamond_callback()
	if savedgame.consumed_diamond_save.size() > 0:
		for purchase_token in savedgame.consumed_diamond_save:
			_purchase_consumed_callback(purchase_token)

func on_play_sign_out_success():
	pass

func _purchase_consumed_callback(purchase_token):
	if BillingControl.billing:
		BillingControl.billing.consumePurchase(purchase_token)

var purchase_consumed_retry_count: int = 0
func on_billing_purchase_consumed_error(result: Dictionary):
	if result["response_code"] >= BillingControl.billingResponseCode.OK and\
	result["response_code"] < BillingControl.billingResponseCode.ERROR:
		savedgame.consumed_diamond_save.erase(result["purchase_token"])
		return
	purchase_consumed_retry_count += 1
	await get_tree().create_timer(pow(2, purchase_consumed_retry_count))
	if purchase_consumed_retry_count <= 0:
		return
	if result["purchase_token"] in savedgame.consumed_diamond_save:
		_purchase_consumed_callback(result["purchase_token"])
func on_billing_purchase_consumed(result: Dictionary):
	purchase_consumed_retry_count = 0
	savedgame.consumed_diamond_save.erase(result["purchase_token"])


signal load_result(success: Dictionary)
func __on_load_success(data: Dictionary):
	load_result.emit({
		'result': true,
		'data': data
	})
func __on_load_failed():
	load_result.emit({
		'result': false,
	})
func check_money(used: int, type: String) -> Dictionary:
	if type not in ['diamond', 'gold']:
		return {
			'err': ERR_INVALID_PARAMETER
		}
	if not GooglePlayServices.isSignedIn():
		return {
			'err': ERR_CANT_CONNECT
		}
	GooglePlayServices.load_failed.connect(__on_load_failed)
	GooglePlayServices.load_success.connect(__on_load_success)
	GooglePlayServices.loadData('ZoneConquest')
	var success: Dictionary = await load_result
	GooglePlayServices.load_failed.disconnect(__on_load_failed)
	GooglePlayServices.load_success.disconnect(__on_load_success)
	if not success.get('result'):
		return {
			'err': FAILED
		}
	var diamond_history = play_game_data.get_or_add('diamond_history', []) as Array
	var coin = play_game_data.get_or_add(type, [0, 0])
	var coin_in_cloud := SavedGame.get_coin(coin[1], coin[0])
	print('coin_in_cloud: ', coin_in_cloud, type)
	if type == 'd' and diamond_history.size() <= 0:
		coin_in_cloud = 0
	return {
		'err': OK,
		'res': coin_in_cloud >= used
	}

func update_buy_to_cloud(update_data: Dictionary):
	if not play_game_data:
		GooglePlayServices.loadData('ZoneConquest')
		await GooglePlayServices.load_success
	if update_data.has('g'):
		play_game_data['gold'][0] = update_data['g'][0]
		play_game_data['gold'][1] = update_data['g'][1]
	if update_data.has('d'):
		if (play_game_data.get_or_add('diamond_history', []) as Array).size() > 0:
			play_game_data['diamond'][0] = update_data['d'][0]
			play_game_data['diamond'][1] = update_data['d'][1]
	if update_data.has('i'):
		var inventory := play_game_data.get_or_add('inventory', []) as Array
		inventory.append(update_data['i'])
	GooglePlayServices.saveData('ZoneConquest', play_game_data)

func on_new_score_record(id: String, score: int):
	var oldscore := savedgame.stat_best_score.get_or_add(id, 0) as int
	if score > oldscore:
		savedgame.stat_best_score[id] = score
		GooglePlayServices.submitLeaderboard(data_achievement.leaderboardId[id], score)

func on_new_achievement_stack(id: String, step: int):
	var achievement_stack := savedgame.achievements.get_or_add(id, 0) as int
	if step <= achievement_stack or achievement_stack >= data_achievement.achievement_goal[id]:
		return
	GooglePlayServices.setAchievementSteps(data_achievement.achievementId[id], step)
	if step < data_achievement.achievement_goal[id]:
		savedgame.achievements[id] = step
	else:
		savedgame.achievements[id] = data_achievement.achievement_goal[id]
		if data_achievement.rewards.has(id):
			savedgame.add_g_coin(data_achievement.rewards[id])
			SignalBus.request_popup_nofi.emit(0, str(data_achievement.rewards[id]) + tr('_earn_reward_'))
			update_buy_to_cloud({'g': [savedgame.g_seed, savedgame.g_coin]})
