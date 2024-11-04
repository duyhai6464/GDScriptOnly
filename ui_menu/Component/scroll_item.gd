class_name ItemScroll extends PanelContainer

const PLAYER_PREVIEW = preload("res://ui_menu/Component/scroll_item_preview/player_preview.tscn")
const ZONE_PREVIEW_2X2 = preload("res://ui_menu/Component/scroll_item_preview/zone_preview_2x_2.tscn")
const MONEY_BOX_PREVIEW = preload("res://ui_menu/Component/scroll_item_preview/money_box_preview.tscn")
const TRADE_BOX_PREVIEW = preload("res://ui_menu/Component/scroll_item_preview/trade_box_preview.tscn")

@export_group('Item', 'item_')
@export var item_type: GlobalConfig.TypeItem
@export var item_ID: int
@export var item_name: String
@export_multiline var item_info: String
@export_range(0, 1 << 31) var item_money_amount: int
@export var item_money_type: GlobalConfig.TypeMoney
@export var infinity: bool


@onready var label_name := %LabelName
@onready var label_type: Label = %LabelType
@onready var aspect_ratio_container: AspectRatioContainer = %AspectRatioContainer
@onready var label_info: Label = %LabelInfo
@onready var texture_type_money: TextureRect = %TextureTypeMoney
@onready var label_money_amount: Label = %LabelMoneyAmount
@onready var event_input: Control = %EventInput

var preview: Control = null

@export_range(-10, 50) var sale_percent: float = 0
@onready var texture_sale: TextureRect = %TextureSale
@onready var label_sale: Label = %LabelSale

@onready var money_box: HBoxContainer = %MoneyBox
@onready var label_owner: Label = %LabelOwner

var player_owner: bool = false

func _ready() -> void:
	label_name.text = item_name
	label_info.text = item_info
	label_money_amount.text = str(item_money_amount)
	match item_money_type:
		GlobalConfig.TypeMoney.GOLD:
			texture_type_money.texture = preload("res://game/Game_asset/ingame/money_type_gold.png")
		GlobalConfig.TypeMoney.DIAMOND:
			texture_type_money.texture = preload("res://game/Game_asset/ingame/money_type_diamond.png")
		GlobalConfig.TypeMoney.ADS:
			texture_type_money.texture = preload("res://game/Game_asset/ingame/money_type_advertising.png")
		GlobalConfig.TypeMoney.CASH:
			texture_type_money.texture = preload("res://game/Game_asset/ingame/money_type_cash.png")

	match item_type:
		GlobalConfig.TypeItem.SKIN_EYE:
			label_type.text = '_body_'
			preview = PLAYER_PREVIEW.instantiate()
			preview.item_ID = item_ID
		GlobalConfig.TypeItem.SKIN_EXPLODE:
			label_type.text = 'Exploding'
		GlobalConfig.TypeItem.SKIN_ZONE:
			label_type.text = '_zone_'
			preview = ZONE_PREVIEW_2X2.instantiate()
			preview.item_ID = item_ID
		GlobalConfig.TypeItem.MONEY_BOX:
			label_type.text = '_treasure_'
			preview = MONEY_BOX_PREVIEW.instantiate()
			preview.item_ID = item_ID
			preview.info = tr(item_info)
		GlobalConfig.TypeItem.TRADE_BOX:
			label_type.text = '_trade_'
			preview = TRADE_BOX_PREVIEW.instantiate()
			preview.item_ID = item_ID
			preview.info = item_name

	if preview != null:
		aspect_ratio_container.add_child(preview)
	set_sale_price()


func set_sale_price(salep: float = -1):
	if salep >= 0 and salep < 100:
		sale_percent = salep
	if sale_percent > 0 and item_money_type < GlobalConfig.TypeMoney.ADS :
		texture_sale.show()
		label_sale.text = '%d%%' % int(sale_percent)
		label_money_amount.text = str(get_price())
	else:
		texture_sale.hide()
		sale_percent = 0
		label_money_amount.text = str(item_money_amount)

func get_price() -> int:
	return abs(roundi(item_money_amount * (1 - sale_percent / 100)))

@onready var panel_money: PanelContainer = %PanelMoney
func set_player_owner(_owner_text: String = ''):
	player_owner = true
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(panel_money, 'modulate', Color8(1000, 1060, 1200), 0.25)
	await tween.finished
	if not infinity:
		money_box.visible = false
		label_owner.visible = true
		if _owner_text.length():
			label_owner.text = _owner_text
		tween = create_tween().set_trans(Tween.TRANS_QUINT)
		tween.tween_property(panel_money, 'modulate', Color.WHITE, 0.1)
	else:
		player_owner = false
		tween = create_tween().set_trans(Tween.TRANS_QUINT)
		tween.tween_property(panel_money, 'modulate', Color.WHITE, 0.1)



var press_down_time : int = 0
var press_down_pos : Vector2 = Vector2()
signal clicked(x: ItemScroll)

func _on_event_input_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_time = Time.get_ticks_msec()
				press_down_pos = event.global_position
			else:
				if Time.get_ticks_msec() - press_down_time < 750:
					if (event.global_position - press_down_pos).length() < 25:
						clicked.emit(self)


func _on_event_input_mouse_entered() -> void:
	self_modulate = Color('3c536f')


func _on_event_input_mouse_exited() -> void:
	self_modulate = Color('3a506b')
