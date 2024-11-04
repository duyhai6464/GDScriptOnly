extends PanelContainer

signal go_back

const link_googleplay := "https://play.google.com/store/apps/details?id=com.Domingo7621.ZoneCo"
const link_amazon := "https://www.amazon.com/dp/B0DJ51TQCM"

@onready var tab_container: TabContainer = %TabContainer
@onready var _stat_ := %_stat_
@onready var _achievement_ := %_achievement_

func _ready():
	visibility_changed.connect(func ():
		if visible:
			_on_tab_container_tab_changed(tab_container.current_tab)
	)


func _on_back_button_pressed():
	go_back.emit()


func _on_button_pressed() -> void:
	OS.shell_open(link_googleplay)
	#OS.shell_open(link_amazon)

const path_tutorial_scene := "res://game/tutorial_scene.tscn"
enum Tabcontainer{STAT, ACHIEVEMENT, TUTORIAL}
func _on_tab_container_tab_changed(tab: int) -> void:
	match tab:
		Tabcontainer.STAT:
			if _stat_:
				_stat_.play()
		Tabcontainer.ACHIEVEMENT:
			if _achievement_:
				_achievement_.play()
		Tabcontainer.TUTORIAL:
			SignalBus.request_scene.emit(path_tutorial_scene)
			SignalBus.request_background_color.emit(Color8(96, 96, 96), 0.55)
			await get_tree().create_timer(0.5).timeout
			SignalBus.wait_load_scene.emit(path_tutorial_scene)
