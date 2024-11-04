extends AudioStreamPlayer

const music_background_tracks: Array[AudioStream] = [
	preload("res://Audio/Music/Clown(chosic.com).mp3"),
	preload("res://Audio/Music/Lobby-Time(chosic.com).mp3"),
	preload("res://Audio/Music/Pixel-Peeker-Polka-faster(chosic.com).mp3"),
	preload("res://Audio/Music/Sakura-Girl-Daisy-chosic.com_.mp3"),
	preload("res://Audio/Music/music.ogg"),
]

const music_icons: Array[Texture2D] = [
	preload("res://Fonts/icon/mute.png"),
	preload("res://Fonts/icon/num1.png"),
	preload("res://Fonts/icon/num2.png"),
	preload("res://Fonts/icon/num3.png"),
	preload("res://Fonts/icon/num4.png"),
	preload("res://Fonts/icon/num5.png"),
]

@onready var savedgame = GlobalConfig.savedgame as SavedGame

func _ready():
	set_music_background_track(savedgame.music)
	set_sfx_mute(not savedgame.soundOn)
	#if not playing:
		#play()

func next_music_background_track():
	savedgame.music += 1
	savedgame.music %= 6
	set_music_background_track(savedgame.music)

func set_music_background_track(id: int):
	if id < 1 or id > 5:
		AudioServer.set_bus_mute(AudioServer.get_bus_index('Music'), true)
	else:
		if stream == music_background_tracks[id - 1]:
			return
		AudioServer.set_bus_mute(AudioServer.get_bus_index('Music'), false)
		stream = music_background_tracks[id - 1]
		match id:
			2,5:
				volume_db = 2
			_:
				volume_db = -8

func set_sfx_mute(mute: bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index('Sfx'), mute)
