extends MarginContainer

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var v_box: VBoxContainer = %VBox
@onready var list_achievement_items: Array[AchievementItem] = [%Achievement1]
const ACHIEVEMENT_ITEM = preload("res://ui_menu/Component/achievement_item.tscn")
var number_achievement: int = 0
var dict_achievement_items: Dictionary = {}

func _ready() -> void:
	for a in data_achievement.achievement_goal:
		if a in savedgame.achievements and savedgame.achievements[a] >= 0:
			add_achievement(a)
	GooglePlayServices.achievement_info_loaded.connect(on_achievement_info_loaded)


func add_achievement(name: String):
	var ach := list_achievement_items[number_achievement]
	ach.name_achievement = name
	ach.info_achievement = name + 'info_'
	ach.reward = data_achievement.rewards[name]
	set_achievement_process(ach, name, savedgame.achievements[name])
	dict_achievement_items[ach.name_achievement] = ach

	number_achievement += 1
	var new_ach = ACHIEVEMENT_ITEM.instantiate()
	v_box.add_child(new_ach)
	list_achievement_items.append(new_ach)
	new_ach.clicked.connect(showAchievements)

func set_achievement_process(ach: AchievementItem, name: String, process: int):
	if process >= data_achievement.achievement_goal[name]:
		process = data_achievement.achievement_goal[name]
		ach.icon_texture.texture = data_achievement.icons[name]
		ach.set_state_achievement(2)
	else:
		ach.set_state_achievement(1)
	ach.process_label.text = '%d/%d' % [process, data_achievement.achievement_goal[name]]

func play():
	if GooglePlayServices.isSignedIn():
		GooglePlayServices.loadAchievementInfo(true)
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_method(func (v):
		v_box.add_theme_constant_override('separation', v)
	, -150, 25, 1.5)
	for x: AchievementItem in v_box.get_children():
		tween.tween_property(x, 'modulate:a', 1, 0.5).from(0)
		tween.tween_interval(0.15)

func showAchievements():
	GooglePlayServices.showAchievements()
	print('showAchievements was click')

func on_achievement_info_loaded(data: Array):
	for achievement in data:
		if achievement["id"] not in data_achievement.aid:
			continue
		var name := data_achievement.aid[achievement["id"]] as String
		if achievement['state'] == 0:
			var current_steps: int = savedgame.achievements.get_or_add(name, data_achievement.achievement_goal[name])
			if name in dict_achievement_items:
				set_achievement_process(dict_achievement_items[name], name, current_steps)
			else:
				add_achievement(name)
		elif achievement['state'] == 1:
			if achievement['type'] == 1:
				var current_steps: int = savedgame.achievements.get_or_add(name, 0)
				if achievement['current_steps'] > current_steps:
					if name in dict_achievement_items:
						set_achievement_process(dict_achievement_items[name], name, current_steps)
					else:
						add_achievement(name)
