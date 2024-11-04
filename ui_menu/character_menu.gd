extends PanelContainer

signal go_back
@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var ui_player: UIplayer = %UI_player
@onready var player_preview := %PlayerPreview

@onready var list_scroll_color_player:= %ListScrollColorPlayer
@onready var list_scroll_body_player:= %ListScrollBodyPlayer
@onready var list_scroll_zone_player:= %ListScrollZonePlayer

@onready var text_edit: LineEdit = %TextEdit

func _ready():
	ui_player.player_name = savedgame.playerName
	player_preview.set_eye_skin_by_item_ID(savedgame.eye_skin_id)
	player_preview.set_body_color(savedgame.favourite_color_id)

	for id in savedgame.get_inventory(GlobalConfig.TypeItem.SKIN_EYE):
		list_scroll_body_player.add_item(id, savedgame.favourite_color_id)

	for id in savedgame.get_inventory(GlobalConfig.TypeItem.SKIN_ZONE):
		list_scroll_zone_player.add_item(id, savedgame.favourite_color_id)

	text_edit.text = savedgame.playerName
	text_edit.placeholder_text = savedgame.playerName
	savedgame.inventory_add.connect(func (key, id):
		match key:
			GlobalConfig.TypeItem.SKIN_EYE:
				list_scroll_body_player.add_item(id, savedgame.favourite_color_id)
				_on_list_scroll_color_player_selected(id)
			GlobalConfig.TypeItem.SKIN_ZONE:
				list_scroll_zone_player.add_item(id, savedgame.favourite_color_id)
				_on_list_scroll_zone_player_selected(id)
	)

func _on_back_button_pressed():
	go_back.emit()
	savedgame.save()


func _on_text_edit_text_submitted(new_text: String) -> void:
	var regex = RegEx.new()
	regex.compile("[\\[\\]\\{\\};:'\"\\\\|,<.>/?~`!@#%^&*()_+-=]")
	new_text = regex.sub(new_text, "", true).strip_escapes().strip_edges()
	if new_text:
		savedgame.playerName = new_text
		ui_player.player_name = savedgame.playerName
		text_edit.text = savedgame.playerName


func _on_list_scroll_color_player_selected(Item_ID: int) -> void:
	savedgame.favourite_color_id = Item_ID
	player_preview.auto_change_color = savedgame.favourite_color_id == 0
	player_preview.set_body_color(savedgame.favourite_color_id)
	list_scroll_body_player.set_all_preview_body_color(savedgame.favourite_color_id)
	list_scroll_zone_player.set_all_preview_zone_color(savedgame.favourite_color_id)


func _on_list_scroll_body_player_selected(item_id: int) -> void:
	savedgame.eye_skin_id = item_id
	player_preview.set_eye_skin_by_item_ID(savedgame.eye_skin_id)


func _on_list_scroll_zone_player_selected(item_id: int) -> void:
	savedgame.square_skin_id = item_id

func set_scroll_vertical(sv: int):
	%ScrollContainer.scroll_vertical = sv
	list_scroll_color_player.set_scroll_vertical(0)
	list_scroll_body_player.set_scroll_vertical(0)
	list_scroll_zone_player.set_scroll_vertical(0)

	var prop := GlobalConfig.ItemProp[GlobalConfig.TypeItem.SKIN_EYE].get(savedgame.eye_skin_id) as data_item
	if prop != null:
		list_scroll_body_player.label_info.text = tr(prop.name) + ' ' + tr('_been_chosen_')
	prop = GlobalConfig.ItemProp[GlobalConfig.TypeItem.SKIN_ZONE].get(savedgame.square_skin_id) as data_item
	if prop != null:
		list_scroll_zone_player.label_info.text = tr(prop.name) + ' ' + tr('_been_chosen_')
