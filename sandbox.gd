extends Node3D

class_name world

static var instance

var port := 0

@export var ip := "127.0.0.1"
@export var player_scene := preload("res://Player/player.tscn")

var game_api := MultiplayerAPI.create_default_interface()
var game_peer := ENetMultiplayerPeer.new()


func _ready():

	instance = self

	get_tree().set_multiplayer(
		game_api,
		get_path()
	)

	game_api.peer_connected.connect(_player_connected)
	game_api.peer_disconnected.connect(_player_disconnected)


func _input(event):

	if event.is_action_pressed("ui_cancel"):

		LobbyHandler.leave_current_room()

		await get_tree().create_timer(0.2).timeout

		game_peer.close()

		await get_tree().create_timer(0.2).timeout

		get_tree().quit()


func _on_play_pressed():

	LobbyHandler.quick_play()

	$CanvasLayer/MarginContainer.hide()


# =========================
# HOST GAME
# =========================

func start_hosting():

	game_peer = ENetMultiplayerPeer.new()

	var err = game_peer.create_server(port)

	if err != OK:
		print("FAILED TO HOST ", err)
		return

	game_api.multiplayer_peer = game_peer

	print("HOSTING GAME ", port)

	spawn_player(game_api.get_unique_id())


# =========================
# JOIN GAME
# =========================

func join_game(new_port):

	port = new_port

	game_peer = ENetMultiplayerPeer.new()

	var err = game_peer.create_client(ip, port)

	if err != OK:
		print("FAILED TO JOIN ", err)
		return

	game_api.multiplayer_peer = game_peer

	print("JOINED GAME")


# =========================
# PLAYER CONNECTIONS
# =========================

func _player_connected(id):

	print("PLAYER CONNECTED ", id)

	if not game_api.is_server():
		return

	# spawn new player on everyone
	spawn_player.rpc(id)

	# send existing players to new client
	for child in get_children():

		if child is CharacterBody3D:

			var existing_id = int(child.name)

			spawn_player.rpc_id(id, existing_id)

func _player_disconnected(id):

	if has_node(str(id)):
		get_node(str(id)).queue_free()


# =========================
# SPAWNING
# =========================

@rpc("authority", "call_local")
func spawn_player(id):

	if has_node(str(id)):
		return

	var player = player_scene.instantiate()

	player.name = str(id)

	player.position = get_random_spawn_point().position

	player.set_multiplayer_authority(id)
	
	add_child(player)

	print("SPAWNED PLAYER ", id)


# =========================
# SPAWN POINTS
# =========================

func get_random_spawn_point():

	var points = [
		$map/spawnpoint1,
		$map/spawnpoint2
	]

	return points.pick_random()
