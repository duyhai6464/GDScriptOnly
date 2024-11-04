extends PanelContainer

const BODY_PLAYER_PREVIEW = preload("res://ui_menu/Component/scroll_item_preview/body_player_preview.tscn")
var preview_list: Array[PreviewPlayer] = []

@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var label_info: Label = %LabelInfo

signal selected(item_id: int)

func add_item(item_ID: int, body_color: int = 0):
	var body_preview := BODY_PLAYER_PREVIEW.instantiate() as BodyPlayerPreview
	h_box_container.add_child(body_preview)
	var preview = body_preview.player_preview as PreviewPlayer
	preview.set_eye_skin_by_item_ID(item_ID)
	preview.set_body_color(body_color)
	preview.clicked.connect(_on_click_item_preview)
	preview_list.append(preview)
	var prop := GlobalConfig.ItemProp[GlobalConfig.TypeItem.SKIN_EYE].get(item_ID) as data_item
	if prop == null:
		return
	body_preview.name_preview.text = prop.name
	preview.tooltip_text = prop.info

func _on_click_item_preview(x: PreviewPlayer):
	selected.emit(x.item_ID)
	label_info.visible_ratio = 0
	label_info.text = x.tooltip_text
	var tween = create_tween()
	tween.tween_property(label_info, 'visible_ratio', 1, 0.5)

func set_all_preview_body_color(body_color: int):
	for preview in preview_list:
		preview.set_body_color(body_color)

func set_scroll_vertical(sv: int):
	%ScrollContainer.scroll_vertical = sv
