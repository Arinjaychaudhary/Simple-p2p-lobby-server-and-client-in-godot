extends Node

var lobby_peer := ENetMultiplayerPeer.new()

var ip := "127.0.0.1"
var lobby_port := 1999


func _ready():

	multiplayer.connected_to_server.connect(_connected_to_server)


func quick_play():

	var err = lobby_peer.create_client(ip, lobby_port)

	if err != OK:
		print("FAILED TO CONNECT")
		return

	multiplayer.multiplayer_peer = lobby_peer

	print("CONNECTING TO LOBBY")


func _connected_to_server():

	print("CONNECTED TO LOBBY")


# =========================
# ROOM RPCS
# =========================

@rpc("authority")
func host_room(port):

	print("BECAME HOST ", port)

	world.instance.port = port

	world.instance.start_hosting()


@rpc("authority")
func join_room(port):

	print("JOINING HOST ", port)

	world.instance.join_game(port)


# checksum match
@rpc("any_peer")
func leave_room():
	pass


# =========================
# LOCAL LEAVE
# =========================

func leave_current_room():

	leave_room.rpc_id(1)

	print("LEFT ROOM")
