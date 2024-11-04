extends Control
const KILL_INFO = preload("res://game/Kill_feed/kill_info.tscn")

const spacing = 15
var kill_info_list: Array[Killfeedinfo] = []

func _on_game_play_player_death(player: Player):
	var kill_info = KILL_INFO.instantiate() as Killfeedinfo
	add_child(kill_info)
	kill_info.set_kill_info(player.was_kill_by, player)
	var index = put(kill_info)
	kill_info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kill_info.position.y = (spacing + kill_info.size.y) * index
	kill_info.play()
	kill_info.tween_exit_finish.connect(func ():
		kill_info_list[index] = null
	, CONNECT_ONE_SHOT)


func put(info : Killfeedinfo) -> int:
	var index = kill_info_list.find(null)
	if index != -1:
		kill_info_list[index] = info
		return index
	kill_info_list.append(info)
	return kill_info_list.size() - 1
