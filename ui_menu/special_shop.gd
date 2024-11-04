extends PanelContainer

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var list_scroll_item := %ListScrollItem
@onready var time_refresh_label: Label = %TimeRefreshText
@onready var time_refresh_number: Label = %TimeRefreshNumber
@onready var skip_label: Label = %SkipLabel

signal selected(item: ItemScroll)

#func _input(event: InputEvent) -> void:
	#if event.is_action("Accept"):
		#_on_skip_reward_ads_earned_reward()

func _ready() -> void:
	list_scroll_item.selected.connect(func (item): selected.emit(item))
	if savedgame.special_shop.size() <= 0:
		refresh_special_shop()
		savedgame.time_refresh = 0
	load_special_shop()

	if savedgame.is_buy_special.size() != savedgame.special_shop.size():
		savedgame.is_buy_special.resize(savedgame.special_shop.size())
	for index in range(savedgame.is_buy_special.size()):
		if savedgame.is_buy_special[index]:
			list_scroll_item.list_items[index].set_player_owner()

	skip_label.hide()


func refresh_special_shop():
	var count_dict : Dictionary = {}
	for type in range(GlobalConfig.TypeItem.MONEY_BOX + 1):
		if not GlobalConfig.ItemProp.has(type):
			continue
		for id in GlobalConfig.ItemProp[type]:
			count_dict[Vector2i(type, id)] = count_dict.get(Vector2i(type, id), 0) + 1
		for id in savedgame.get_inventory(type):
			count_dict[Vector2i(type, id)] = count_dict.get(Vector2i(type, id), 0) + 1

	for key in count_dict.keys():
		if count_dict[key] != 1:
			count_dict.erase(key)
	var special_shop : Array[Vector2i] = []
	var sales_percent : Array[int] = []
	var size_shop : int = 0
	while size_shop < 4 and count_dict.size() > 0:
		var key : Vector2i = count_dict.keys().pick_random()
		special_shop.append(key)
		sales_percent.append(random_sale())
		count_dict.erase(key)
		size_shop += 1
	while size_shop < 5:
		special_shop.append(Vector2i(GlobalConfig.TypeItem.MONEY_BOX, 0))
		sales_percent.append(0)
		size_shop += 1

	savedgame.special_shop.clear()
	savedgame.sales_percent.clear()
	savedgame.special_shop.append_array(special_shop)
	savedgame.sales_percent.append_array(sales_percent)
	savedgame.save()

func weighted_random(min, max):
	var rand_value = pow(randf(), 1.6)
	return roundi(lerp(min, max, rand_value))

func random_sale() -> int:
	if randf() < 0.31:
		return weighted_random(1, 15)
	if randf() < 0.72:
		return weighted_random(10, 30)
	return weighted_random(25, 50)


func load_special_shop():
	list_scroll_item.clear()
	savedgame.sales_percent.resize(savedgame.special_shop.size())
	for i in range(savedgame.special_shop.size()):
		var x = savedgame.special_shop[i]
		if x is Vector2i:
			list_scroll_item.add_item(x[1], x[0], savedgame.sales_percent[i])


func _on_timer_timeout() -> void:
	if savedgame.time_refresh <= 0:
		time_refresh_label.text = '_refresh_ready_'
		time_refresh_number.hide()
		skip_label.hide()
	else:
		var time = int(savedgame.time_refresh)
		time_refresh_label.text = '_refresh_in_'
		time_refresh_number.text = '%02d:%02d' % [time / 60, time % 60]
		time_refresh_number.show()
		skip_label.show()


func _on_button_refresh_pressed() -> void:
	if savedgame.time_refresh > 0:
		if not AdsManager.reward_ads_earn_reward.is_connected(_on_skip_reward_ads_earned_reward):
			AdsManager.reward_ads_earn_reward.connect(_on_skip_reward_ads_earned_reward, CONNECT_ONE_SHOT)
		if not AdsManager.show_reward_ads():
			SignalBus.request_popup_nofi.emit(-1, '_ads_load_failed_')
		return
	refresh_special_shop()
	start_load_special_shop()
	savedgame.time_refresh = 600

func _on_skip_reward_ads_earned_reward():
	savedgame.time_refresh = 0
	print('get_skip_reward_ads')

func set_scroll_horizontal(sv: int):
	list_scroll_item.set_scroll_horizontal(sv)

var tween: Tween = null
@onready var margin_items: MarginContainer = %MarginItems

func start_load_special_shop():
	if tween != null:
		return
	SignalBus.request_background_color.emit(Color8(96, 96, 96), 0.5)
	tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(list_scroll_item, 'modulate', Color8(1500, 1540, 1700), 1.5)
	tween.tween_method(shake_items, 0, 10, 1.5)
	await tween.finished
	load_special_shop()
	set_scroll_horizontal(0)
	SignalBus.request_background_color.emit(Color.WHITE, 0.5)
	tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(list_scroll_item, 'modulate', Color.WHITE, 0.25)
	tween.tween_method(shake_items, 10, 0, 0.25)
	tween.tween_callback(shake_items.bind(0))
	await tween.finished
	tween = null
	if randf() > 0.7:
		AdsManager.interstitial_ads.show_ads()

func shake_items(curoffset: float):
	var shake_offset = Vector2i(curoffset * (1 - randi() % 2 * 2), curoffset * (1 - randi() % 2 * 2))
	margin_items.add_theme_constant_override('margin_left', shake_offset.x)
	margin_items.add_theme_constant_override('margin_right', -shake_offset.x)
	margin_items.add_theme_constant_override('margin_top', shake_offset.y)
	margin_items.add_theme_constant_override('margin_bottom', -shake_offset.y)
