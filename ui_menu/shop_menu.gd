extends PanelContainer

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var scroll_container: ScrollContainer = %ScrollContainer

@onready var money_texture_diamond := %MoneyTextureDiamond
@onready var money_texture_gold := %MoneyTextureGold

@onready var special_shop := %SpecialShop
@onready var body_shop := %BodyShop
@onready var zone_shop := %ZoneShop
@onready var trade_shop := %TradeShop

@onready var popup_confirm := %PopupConfirm
@onready var go_back_button := %GoBackButton

@onready var MGOLD := GlobalConfig.TypeMoney.GOLD
@onready var MDIAMOND := GlobalConfig.TypeMoney.DIAMOND
@onready var MADS := GlobalConfig.TypeMoney.ADS
@onready var MCASH := GlobalConfig.TypeMoney.CASH

@onready var TEYE := GlobalConfig.TypeItem.SKIN_EYE
@onready var TEXPLODE := GlobalConfig.TypeItem.SKIN_EXPLODE
@onready var TZONE := GlobalConfig.TypeItem.SKIN_ZONE
@onready var TMB := GlobalConfig.TypeItem.MONEY_BOX
@onready var TTB := GlobalConfig.TypeItem.TRADE_BOX

@onready var body_inven := savedgame.get_inventory(TEYE)
@onready var zone_inven := savedgame.get_inventory(TZONE)

signal go_back
signal user_confirm_finished(accept: bool)

var user_confirm: bool = false

#func _input(event: InputEvent) -> void:
	#if event.is_action("Accept"):
		#if item_on_cart != null:
			#buy_item_by_ads(item_on_cart)
		#savedgame.inventory.clear()
		#savedgame.add_g_coin(10000)

func _ready() -> void:
	money_texture_gold.value = savedgame.get_g_coin()
	money_texture_diamond.value = savedgame.get_d_coin()
	savedgame.g_coinChanged.connect(func ():money_texture_gold.value = savedgame.get_g_coin())
	savedgame.d_coinChanged.connect(func ():money_texture_diamond.value = savedgame.get_d_coin())
	SignalBus.request_background_color.connect(_on_special_shop_request_background_color)


	for itemID in GlobalConfig.ItemProp[TEYE].keys():
		var item := body_shop.add_item(itemID, TEYE) as ItemScroll
		if itemID in body_inven:
			item.set_player_owner()
	for itemID in GlobalConfig.ItemProp[TZONE].keys():
		var item := zone_shop.add_item(itemID, TZONE) as ItemScroll
		if itemID in zone_inven:
			item.set_player_owner()
	for itemID in GlobalConfig.ItemProp[TTB].keys():
		var item := trade_shop.add_item(itemID, TTB) as ItemScroll
		item.infinity = true

func add_to_inven(item: ItemScroll):
	if item.item_type == TEYE:
		if not body_inven.get(item.item_ID, false):
			body_inven[item.item_ID] = true
			savedgame.inventory_add.emit(item.item_type, item.item_ID)
	if item.item_type == TZONE:
		if not zone_inven.get(item.item_ID, false):
			zone_inven[item.item_ID] = true
			savedgame.inventory_add.emit(item.item_type, item.item_ID)

func check_money(item: ItemScroll, buying: bool = false) -> Dictionary:
	if not data_item_dict_prop.check_valid(item.item_money_amount, item.item_money_type):
		return {
			'err': ERR_INVALID_DATA
		}
	return await SignalBus.check_money(item.get_price(),
		'gold' if item.item_money_type == MGOLD else 'diamond')

func buy_item_by_gold(item: ItemScroll):
	#do sub money(item)
	savedgame.add_g_coin(-item.get_price())
	buy_for_in_game_item(item)
	var data = {
		'g': [savedgame.g_seed, savedgame.g_coin],
	}
	if item.item_type < TMB:
		data['i'] = [item.item_type, item.item_ID]
	SignalBus.update_buy_to_cloud(data)


func buy_item_by_diamond(item: ItemScroll):
	#do sub money(item)
	savedgame.add_d_coin(-item.get_price())
	buy_for_in_game_item(item)
	var data = {
		'd': [savedgame.d_seed, savedgame.d_coin],
	}
	if item.item_type < TMB:
		data['i'] = [item.item_type, item.item_ID]
	else:
		data['g'] = [savedgame.g_seed, savedgame.g_coin]
	SignalBus.update_buy_to_cloud(data)

func buy_item_by_ads(item: ItemScroll):
	if item.item_type != TMB:
		return
	buy_for_in_game_item(item)
	var data = {
		'd': [savedgame.d_seed, savedgame.d_coin],
	}
	SignalBus.update_buy_to_cloud(data)

func buy_for_in_game_item(item: ItemScroll):
	if item.item_type < TMB:
		add_to_inven(item)
	elif item.item_type == TMB:
		var preview = item.preview as PreviewMoneyBox
		savedgame.add_g_coin(preview.get_reward_amount())
		SignalBus.request_popup_nofi.emit(MGOLD, str(preview.get_reward_amount()) + tr('_earn_reward_'))
		SignalBus.new_achievement_stack.emit('_mystery_box_',
			savedgame.achievements.get_or_add('_mystery_box_', 0) + 1)
	else:
		var preview = item.preview as PreviewTradeBox
		if preview.get_reward_type() == MGOLD:
			savedgame.add_g_coin(preview.get_reward_amount())
			SignalBus.request_popup_nofi.emit(MGOLD, str(preview.get_reward_amount()) + tr('_earn_reward_'))
	savedgame.save()
	item.set_player_owner()
	if item.sale_percent > 0:
		var listit = special_shop.list_scroll_item.list_items as Array[ItemScroll]
		var index = listit.find(item)
		if index >= 0:
			savedgame.is_buy_special[index] = true

func _on_go_back_button_pressed() -> void:
	savedgame.save()
	go_back.emit()

func handled_with_ads_item(item: ItemScroll):
	if not AdsManager.reward_ads_earn_reward.is_connected(_on_get_gold_reward_ads_earn_reward):
		AdsManager.reward_ads_earn_reward.connect(_on_get_gold_reward_ads_earn_reward, CONNECT_ONE_SHOT)
	if not AdsManager.show_reward_ads():
		SignalBus.request_popup_nofi.emit(-1, '_ads_load_failed_')
		item_on_cart = null
	else:
		item_on_cart = item
	#item_on_cart = item

func handled_with_cash_item(item: ItemScroll):
	if not GooglePlayServices.isSignedIn():
		SignalBus.request_popup_nofi.emit(10, '_sign_in_first_')
		GooglePlayServices.signIn()
		return
	var preview = item.preview as PreviewTradeBox
	if preview.get_reward_type() == MDIAMOND:
		var id = BillingControl.ITEM_CONSUMATED[preview.get_reward_amount() - 1]
		SignalBus.freeze_start.emit()
		BillingControl.do_purchase(id)

func _on_shop_selected(item: ItemScroll) -> void:
	if item.player_owner:
		return
	var price_text = item.label_money_amount.text + ' '
	match item.item_money_type:
		MADS:
			return handled_with_ads_item(item)
		MCASH:
			return handled_with_cash_item(item)
		MGOLD:
			price_text += "[img]res://game/Game_asset/ingame/money_type_gold.png[/img]"
		MDIAMOND:
			price_text += "[img]res://game/Game_asset/ingame/money_type_diamond.png[/img]"
		_:
			return
	popup_confirm.set_confirm_text(tr('_buy_item_') % [tr(item.item_name), price_text])
	popup_confirm.popup_enter()
	var user_confirm: bool = await user_confirm_finished
	if user_confirm:
		SignalBus.freeze_start.emit()
		var result = await check_money(item)
		SignalBus.freeze_finish.emit()
		match result.get('err'):
			OK:
				if result.get('res'):
					if item.item_money_type == MGOLD:
						buy_item_by_gold(item)
					else:
						buy_item_by_diamond(item)
				else:
					SignalBus.request_popup_nofi.emit(item.item_money_type, '_not_enough_')
			ERR_CANT_CONNECT:
				SignalBus.request_popup_nofi.emit(10, '_sign_in_first_')
			ERR_INVALID_DATA:
				SignalBus.cheating_detected.emit('_invalid_data_')
	popup_confirm.popup_exit()



func _on_popup_confirm_cancel() -> void:
	user_confirm_finished.emit(false)


func _on_popup_confirm_ok() -> void:
	user_confirm_finished.emit(true)

var item_on_cart: ItemScroll = null
func _on_get_gold_reward_ads_earn_reward():
	print('get_gold_reward_ads_earn_reward ', item_on_cart.name)
	if item_on_cart == null or item_on_cart.item_money_type != MADS:
		return
	if item_on_cart.label_money_amount.text != '1':
		item_on_cart.label_money_amount.text = str(item_on_cart.label_money_amount.text.to_int() - 1)
		return
	buy_item_by_ads(item_on_cart)

func set_scroll_vertical(sv: int):
	scroll_container.scroll_vertical = sv
	special_shop.set_scroll_horizontal(0)
	body_shop.set_scroll_horizontal(0)
	zone_shop.set_scroll_horizontal(0)

func _on_special_shop_request_background_color(color: Color, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
	if color != Color.WHITE:
		tween.tween_property(self, 'modulate', color.lightened(0.5), duration)
		tween.tween_property(go_back_button, 'modulate:a', 0, duration)
	else:
		tween.tween_property(self, 'modulate', color, duration)
		tween.tween_property(go_back_button, 'modulate:a', 1, duration)
