extends Node

const MUSIC_TRACKS: Dictionary = {
	"MainMenu": preload("res://assets/Music/Onward When You Wake - Release.mp3"),
	"UITest": preload("res://assets/Music/Onward When You Wake - Release.mp3"),
	"Tutorial": preload("res://assets/Music/Onward When You Wake - Release.mp3"),
	"Ranking": preload("res://assets/Music/Onward When You Wake - Release.mp3"),
	"LobbyCastle": preload("res://assets/Music/castleLobby.mp3"),
	"BattleCastle": preload("res://assets/Music/castleBattle.mp3"),
	"LobbyForest": preload("res://assets/Music/forestLobby.mp3"),
	"BattleForest": preload("res://assets/Music/forestBattle.mp3"),
	"LobbyCave": preload("res://assets/Music/caveLobby.mp3"),
	"BattleCave": preload("res://assets/Music/caveBattle.mp3")
}

@onready var music: AudioStreamPlayer = $Music

var current_track_key: String = "MainMenu"
var last_scene_instance_id: int = 0


func _ready() -> void:
	for track in MUSIC_TRACKS.values():
		if track is AudioStreamMP3:
			(track as AudioStreamMP3).loop = true

	get_tree().tree_changed.connect(_on_scene_tree_changed)
	call_deferred("_sync_with_current_scene")


func _on_scene_tree_changed() -> void:
	# Godot 4.4 has tree_changed but not SceneTree.scene_changed.
	# Defer the check until the scene switch has finished updating current_scene.
	call_deferred("_sync_with_current_scene")


func _sync_with_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var scene_instance_id: int = scene.get_instance_id()
	if scene_instance_id == last_scene_instance_id:
		return

	last_scene_instance_id = scene_instance_id
	_play_for_scene(scene.name)


func _play_for_scene(scene_name: String) -> void:
	if not MUSIC_TRACKS.has(scene_name):
		return

	var track: AudioStream = MUSIC_TRACKS[scene_name]
	var is_menu_music: bool = (
		scene_name == "MainMenu"
		or scene_name == "UITest"
		or scene_name == "Tutorial"
		or scene_name == "Ranking"
	)

	# The main-menu track continues without restarting across menu-related pages.
	if is_menu_music and current_track_key == "MainMenu" and music.playing:
		return

	music.stop()
	music.stream = track
	music.play()
	current_track_key = "MainMenu" if is_menu_music else scene_name
