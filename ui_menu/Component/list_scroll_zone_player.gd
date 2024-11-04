extends PanelContainer

const ZONE_PLAYER_PREVIEW = preload("res://ui_menu/Component/scroll_item_preview/zone_player_preview.tscn")
var preview_list: Array[PreviewZone] = []

@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var label_info: Label = %LabelInfo

signal selected(item_id: int)

func add_item(item_ID: int, color_ID: int = 0):
	var zone_preview := ZONE_PLAYER_PREVIEW.instantiate() as ZonePlayerPreview
	h_box_container.add_child(zone_preview)
	var preview := zone_preview.zone_preview_2x_2 as PreviewZone
	preview.change_ID(item_ID)
	preview.change_color(color_ID)
	preview.clicked.connect(_on_click_item_preview)
	preview_list.append(preview)
	var prop := GlobalConfig.ItemProp[GlobalConfig.TypeItem.SKIN_ZONE].get(item_ID) as data_item
	if prop == null:
		return
	zone_preview.preview_name.text = prop.name
	preview.tooltip_text = prop.info

func _on_click_item_preview(x: PreviewZone):
	selected.emit(x.item_ID)
	label_info.visible_ratio = 0
	label_info.text = x.tooltip_text
	var tween = create_tween()
	tween.tween_property(label_info, 'visible_ratio', 1, 0.5)

func set_all_preview_zone_color(color_ID: int):
	for preview in preview_list:
		preview.change_color(color_ID)

func set_scroll_vertical(sv: int):
	%ScrollContainer.scroll_vertical = sv
