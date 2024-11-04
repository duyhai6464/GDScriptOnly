extends MarginContainer

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var v_box: VBoxContainer = %VBox
@onready var score_b_hunter: OverInfoline = %ScoreBHunter
@onready var score_survival: OverInfoline = %ScoreSurvival
@onready var score_free: OverInfoline = %ScoreFree

@onready var total_money_earn: OverInfoline = %TotalMoneyEarn
@onready var total_kill: OverInfoline = %TotalKill
@onready var total_arena_clamp: OverInfoline = %TotalArenaClamp
@onready var total_death: OverInfoline = %TotalDeath
@onready var total_time: OverInfoline = %TotalTime


func _ready() -> void:
	score_b_hunter.set_info_value(savedgame.stat_best_score.get('b', 0))
	score_survival.set_info_value(savedgame.stat_best_score.get('s', 0))
	score_free.set_info_value(savedgame.stat_best_score.get('f', 0))

	total_money_earn.set_info_value(savedgame.stat_moneys)
	total_kill.set_info_value(savedgame.stat_kills)
	total_arena_clamp.set_info_value(savedgame.stat_zones)

	total_death.set_info_value(savedgame.stat_death)
	total_time.label_value.type = 'Timer'
	total_time.set_info_value(savedgame.stat_time)

	score_b_hunter.clicked.connect(showLeaderboard.bind(data_achievement.leaderboardId['b']))
	score_survival.clicked.connect(showLeaderboard.bind(data_achievement.leaderboardId['s']))
	score_free.clicked.connect(showLeaderboard.bind(data_achievement.leaderboardId['f']))
	total_money_earn.clicked.connect(showLeaderboard)
	total_kill.clicked.connect(showLeaderboard)
	total_arena_clamp.clicked.connect(showLeaderboard)
	total_death.clicked.connect(showLeaderboard)
	total_time.clicked.connect(showLeaderboard)

func play():
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_method(func (v):
		v_box.add_theme_constant_override('separation', v)
	, -70, 20, 1.5)
	for x:OverInfoline in v_box.get_children():
		x.play()
		tween.tween_property(x, 'modulate:a', 1, 0.5).from(0)
		tween.tween_interval(0.15)
	tween.tween_callback(timer.start)

@onready var timer: Timer = %Timer
func _on_timer_timeout() -> void:
	total_time.label_value.set_text_time(savedgame.stat_time)

func showLeaderboard(LeaderboardID: String = ''):
	if LeaderboardID != '':
		GooglePlayServices.showLeaderboard(LeaderboardID)
		print('showLeaderboard id ', LeaderboardID, ' was click')
	else:
		GooglePlayServices.showAllLeaderBoards()
