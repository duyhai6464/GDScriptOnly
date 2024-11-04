extends Node

#FUNCTIONS YOU CAN USE FOR:

#ACCOUNT
#signIn(); signOut()

#ACHIEVEMENTS
#unlockAchievement(id); incrementAchievement(id, points)
#showAchievements()

#LEADERBOARD
#submitLeaderboard(id, score); showLeaderboard(id)

#CLOUD
#saveData(namefile, data), loadData(namefile)

#DON'T MODIFY*******************************************
var play_games_services

signal sign_in_success(data: Dictionary)
signal sign_in_failed(error: int)
signal sign_out_success()
signal sign_out_failed()
signal achievement_unlocked(achievement: String)
signal achievement_unlocking_failed(achievement: String)
signal achievement_incremented(achievement: String)
signal achievement_incrementing_failed(achievement: String)
signal achievement_set(achievement: String)
signal achievement_setting_failed(achievement: String)
signal leaderboard_score_submitted(leaderboard_id: String)
signal leaderboard_score_submitting_failed(leaderboard_id: String)
signal save_success()
signal save_failed()
signal load_success(data: Dictionary)
signal load_failed()
signal achievement_info_loaded(data: Array)
signal achievement_info_load_failed()

#SET-UP
func _ready():
	if Engine.has_singleton("GodotPlayGamesServices"):
		play_games_services = Engine.get_singleton("GodotPlayGamesServices")
		play_games_services.initWithSavedGames(true, "ZoneConquest", true, true, "")

		play_games_services._on_sign_in_success.connect(_on_sign_in_success) # account_id: String
		play_games_services._on_sign_in_failed.connect(_on_sign_in_failed) # error_code: int
		play_games_services._on_sign_out_success.connect(_on_sign_out_success) # no params
		play_games_services._on_sign_out_failed.connect(_on_sign_out_failed) # no params
		play_games_services._on_achievement_unlocked.connect(_on_achievement_unlocked) # achievement: String
		play_games_services._on_achievement_unlocking_failed.connect(_on_achievement_unlocking_failed) # achievement: String
		play_games_services._on_achievement_incremented.connect(_on_achievement_incremented) # achievement: String
		play_games_services._on_achievement_incrementing_failed.connect(_on_achievement_incrementing_failed) # achievement: String
		play_games_services._on_leaderboard_score_submitted.connect(_on_leaderboard_score_submitted) # leaderboard_id: String
		play_games_services._on_leaderboard_score_submitting_failed.connect(_on_leaderboard_score_submitting_failed) # leaderboard_id: String
		play_games_services._on_game_saved_success.connect(_on_game_saved_success) # no params
		play_games_services._on_game_saved_fail.connect(_on_game_saved_fail) # no params
		play_games_services._on_game_load_success.connect(_on_game_load_success) # data: String
		play_games_services._on_game_load_fail.connect(_on_game_load_fail) # no params
		#### MY code ####
		play_games_services._on_achievement_info_loaded.connect(_on_achievement_info_loaded)
		play_games_services._on_achievement_info_load_failed.connect(_on_achievement_info_load_failed)
		play_games_services._on_achievement_steps_set.connect(_on_achievement_steps_set)
		play_games_services._on_achievement_steps_setting_failed.connect(_on_achievement_steps_setting_failed)
	else:
		printerr("GodotPlayGamesServices singleton not found")

#ACCOUNT
func signIn():
	if play_games_services:
		play_games_services.signIn()

func signOut():
	if play_games_services:
		play_games_services.signOut()

#ACHIEVEMENTS
func unlockAchievement(id):
	if play_games_services:
		play_games_services.unlockAchievement(id)

func incrementAchievement(id, points):
	if play_games_services:
		play_games_services.incrementAchievement(id, points)

func setAchievementSteps(id, steps):
	if play_games_services:
		play_games_services.setAchievementSteps(id, steps)

func showAchievements():
	if play_games_services:
		play_games_services.showAchievements()

#LEADERBOARD
func submitLeaderboard(id, score):
	if play_games_services:
		play_games_services.submitLeaderBoardScore(id, score)

func showLeaderboard(id):
	if play_games_services:
		play_games_services.showLeaderBoard(id)

func showAllLeaderBoards():
	if play_games_services:
		play_games_services.showAllLeaderBoards()

#CLOUD
func saveData(file_name: String, data: Dictionary, DESCRIPTION:String='DESCRIPTION'):
	if play_games_services:
		play_games_services.saveSnapshot(file_name, JSON.stringify(data), DESCRIPTION)

func loadData(file_name: String):
	if play_games_services:
		play_games_services.loadSnapshot(file_name)

#SIGNALS
func _on_sign_in_success(_account_id: String):
	var datajson = JSON.parse_string(_account_id)
	var data: Dictionary = datajson if typeof(datajson) == TYPE_DICTIONARY else {}
	sign_in_success.emit(data)
	print('sign_in_ok', data)

func _on_sign_in_failed(_error_code: int):
	sign_in_failed.emit(_error_code)
	print('sign_in_not_ok', _error_code)

func _on_sign_out_success():
	sign_out_success.emit()

func _on_sign_out_failed():
	sign_out_failed.emit()

func _on_achievement_unlocked(achievement: String):
	achievement_unlocked.emit(achievement)

func _on_achievement_unlocking_failed(achievement: String):
	achievement_unlocking_failed.emit(achievement)

func _on_achievement_incremented(achievement: String):
	achievement_incremented.emit(achievement)

func _on_achievement_incrementing_failed(achievement: String):
	achievement_incrementing_failed.emit(achievement)

func _on_leaderboard_score_submitted(leaderboard_id: String):
	leaderboard_score_submitted.emit(leaderboard_id)

func _on_leaderboard_score_submitting_failed(leaderboard_id: String):
	leaderboard_score_submitting_failed.emit(leaderboard_id)

func _on_game_saved_success():
	save_success.emit()

func _on_game_saved_fail():
	save_failed.emit()

func _on_game_load_success(data):
	var json_data = JSON.parse_string(data)
	var game_data: Dictionary = json_data if typeof(json_data) == TYPE_DICTIONARY else {}
	load_success.emit(game_data)

func _on_game_load_fail():
	load_failed.emit()


##### MY MODIFY #####

func isSignedIn() -> bool:
	if play_games_services:
		return play_games_services.isSignedIn()
	return false

func loadAchievementInfo(forceReload: bool):
	if play_games_services:
		play_games_services.loadAchievementInfo(forceReload)

func loadPlayerStats(forceReload: bool):
	if play_games_services:
		play_games_services.loadPlayerStats(forceReload)

func _on_achievement_info_loaded(achievementsJsondata):
	print('_on_achievement_info_loaded', achievementsJsondata)
	var json_data = JSON.parse_string(achievementsJsondata)
	var achievements : Array = json_data if typeof(json_data) == TYPE_ARRAY else []
	achievement_info_loaded.emit(achievements)

func _on_achievement_info_load_failed():
	achievement_info_load_failed.emit()

func _on_achievement_steps_set(id: String):
	achievement_set.emit(id)

func _on_achievement_steps_setting_failed(id: String):
	achievement_setting_failed.emit(id)
