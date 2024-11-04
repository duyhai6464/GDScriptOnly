extends PanelContainer

const SCROLL_ITEM = preload("res://ui_menu/Component/scroll_item.tscn")

@onready var h_box_container: HBoxContainer = %HBoxContainer
var list_items: Array[ItemScroll] = []

signal selected(item: ItemScroll)

func add_item(item_ID: int, item_type: GlobalConfig.TypeItem, sale_percent: float = 0) -> ItemScroll:
	var item = SCROLL_ITEM.instantiate() as ItemScroll
	item.item_ID = item_ID
	item.item_type = item_type
	var prop := GlobalConfig.ItemProp[item_type].get(item_ID) as data_item
	if prop == null:
		return null
	#print('_shop_item_load_', prop)
	item.item_name = prop.name
	item.item_info = prop.info
	item.item_money_amount = prop.money
	item.item_money_type = prop.money_type
	item.sale_percent = sale_percent
	item.clicked.connect(_on_scroll_item_click)
	list_items.append(item)
	h_box_container.add_child(item)
	return item


func _on_scroll_item_click(item: ItemScroll):
	selected.emit(item)

func clear():
	for item in list_items:
		item.queue_free()
	list_items.clear()

func set_scroll_horizontal(sv: int):
	%ScrollContainer.scroll_horizontal = sv
