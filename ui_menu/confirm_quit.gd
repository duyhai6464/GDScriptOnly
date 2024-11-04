class_name QuitConfirm extends Control

signal show_dialog

@onready var popup_confirm := $PopupConfirm

var tree_paused_state_before
var is_show: bool = false

func _ready():
	show_dialog.connect(func ():
		tree_paused_state_before = get_tree().paused
		popup_confirm.popup_enter()
		is_show = true
		get_tree().paused = true
	)


func _on_popup_confirm_cancel() -> void:
	get_tree().paused = tree_paused_state_before
	popup_confirm.popup_exit()
	is_show = false

func _on_popup_confirm_ok() -> void:
	queue_free()
	get_tree().quit()
