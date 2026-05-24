extends Node

var peer := ENetMultiplayerPeer.new()

var rooms := []


func _ready():
	start_server()


func start_server():

	var err = peer.create_server(1999)

	if err != OK:
		print("SERVER FAILED ", err)
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("LOBBY SERVER STARTED")


func _on_peer_connected(id):

	print("PLAYER CONNECTED ", id)

	for room in rooms:

		if room["players"].size() < 5:

			room["players"].append(id)

			print("JOINING ROOM ", room["port"])

			join_room.rpc_id(id, room["port"])

			return

	create_room(id)


func _on_peer_disconnected(id):

	print("PLAYER DISCONNECTED ", id)

	_remove_player_from_rooms(id)


func create_room(id):

	var room = {
		"name": "room_" + str(rooms.size()),
		"port": 2000 + rooms.size(),
		"players": [id]
	}

	rooms.append(room)

	print("CREATED ROOM")

	host_room.rpc_id(id, room["port"])


func _remove_player_from_rooms(id):

	var room_to_delete = null

	for room in rooms:

		if id in room["players"]:

			room["players"].erase(id)

			print("REMOVED FROM ", room["name"])

			if room["players"].is_empty():
				room_to_delete = room

			break

	if room_to_delete != null:

		print("DELETING EMPTY ROOM ", room_to_delete["name"])

		rooms.erase(room_to_delete)


# =========================
# LEAVE ROOM
# =========================

@rpc("any_peer")
func leave_room():

	var id = multiplayer.get_remote_sender_id()

	print("PLAYER LEFT ROOM ", id)

	_remove_player_from_rooms(id)


# =========================
# RPC DECLARATIONS
# =========================

@rpc("authority")
func host_room(port):
	pass


@rpc("authority")
func join_room(port):
	pass
