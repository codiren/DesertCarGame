extends Node2D
var mapas = []
var mapasbounds = 100
var currentplayerid = 1
var Firstname = ["Abdul ", "Mehmed ", "Ali ", "Amir ", "Muhamed ", "Khalif "]
var Middlename = ["al-","adin-","wiyah","bakr-","suley","hash-"]
var Lastname = ["aladin","yadiz II","yabadil","nashneed","wataqik","qahir"]
var players = [1,"noskoper"]
var playerdatasize = 2
var gamestarted = false
var config = ConfigFile.new()
var err = config.load("user://config.cfg")
func _ready():
	randomize()
	$Multiplayer_window.visible = false
	$Main_menu.visible = true
	$Game.visible = false
	$ui/stuff.visible = false
	$ui/inventory.visible = false
	for i in $ui/inventory/GridContainer.get_children():
		i.set_button_icon(null)
	$ui/inventory/GridContainer/slot2.set_button_icon(preload("res://arabCarSolo.png"))
func _on_Exit_pressed():
	get_tree().quit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func generate_map():
	for x in range(0,mapasbounds):
		for y in range(0,mapasbounds):
			mapas.append(0)
			$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),0)
func preparegamestart():
	gamestarted = true
	$Multiplayer_window.visible = false
	$Main_menu.visible = false
	$Game.visible = true
	$Game/players.get_node(str(currentplayerid)).get_node("Camera2D").current = true
	$Game/players.get_node(str(currentplayerid)).visible = true
	$ui/stuff.visible = true
	$Game/players.get_node(str(currentplayerid)).get_node("nametag").text = $Multiplayer_window/currentplayername.text
	players[1] = $Game/players.get_node(str(currentplayerid)).get_node("nametag").text
func _on_Credits_pressed():
	$Main_menu.get_node("Credits2").visible = not $Main_menu.get_node("Credits2").visible
func spawnplayertogame(id,name):
	var copy = $Game/players.get_node(str(currentplayerid)).duplicate()
	copy.get_node("Camera2D").queue_free()#.set_script(null)
	#remove_child(copy.get_node("Camera2D"))
	copy.set_name(str(id))
	copy.get_node("nametag").text = name
	$Game/players.add_child(copy)
	$Game/players.get_node(str(currentplayerid)).get_node("Camera2D").current = true
func _on_Multiplayer_pressed():
	$Multiplayer_window.visible = true
	if err != OK:
		$Multiplayer_window/currentplayername.text = Firstname[randi() % Firstname.size()] + Middlename[randi() % Middlename.size()] + Lastname[randi() % Lastname.size()]
	else:
		for player in config.get_sections():
			$Multiplayer_window/currentplayername.text = config.get_value("man", "name")
			$Multiplayer_window/serverportis.text = config.get_value("man", "port")
			$Multiplayer_window/servername.text = config.get_value("man", "ip")
func _on_Exitm_pressed():
	$Multiplayer_window.visible = false

func _on_Host_pressed():
	config = ConfigFile.new()
	config.set_value("man", "name", $Multiplayer_window/currentplayername.text)
	config.set_value("man", "port", $Multiplayer_window/serverportis.text)
	config.set_value("man", "ip", $Multiplayer_window/servername.text)
	config.save("user://config.cfg")
	preparegamestart()
	generate_map()
	get_tree().connect("network_peer_connected",self,"_player_connected")
	var peer = WebSocketServer.new()
	peer.listen(int($Multiplayer_window/serverportis.text), PoolStringArray(["ludus"]), true)
	get_tree().set_network_peer(peer)
func _on_Join_pressed():
	config = ConfigFile.new()
	config.set_value("man", "name", $Multiplayer_window/currentplayername.text)
	config.set_value("man", "port", $Multiplayer_window/serverportis.text)
	config.set_value("man", "ip", $Multiplayer_window/servername.text)
	config.save("user://config.cfg")
	var peer = WebSocketClient.new()
	peer.connect_to_url("ws://" + $Multiplayer_window/servername.text + ":" + $Multiplayer_window/serverportis.text, PoolStringArray(["ludus"]), true)
	get_tree().connect("connected_to_server", self, "_iconnectedtoserver")
	get_tree().set_network_peer(peer)
func _player_connected(id):
	rpc_id(id, "loadmap",mapasbounds,PoolByteArray(mapas).compress(),playerdatasize,PoolStringArray(players),id)
	players.append(id)
	for _i in range(1,playerdatasize):
		players.append("")
func _iconnectedtoserver():
	rpc_id(1, "setname",$Multiplayer_window/currentplayername.text)
	preparegamestart()
remote func loadmap(mapsize,maparea,playerdatas,playerlist,myid):
	players[0] = myid
	mapasbounds = mapsize
	playerdatasize = playerdatas
	players = Array(playerlist)
	for i in range(0,len(players),playerdatasize):
		players[i] = int(players[i])
#		players[i+2] = int(players[i+2])
#		players[i+3] = int(players[i+3])
#		players[i+4] = int(players[i+4])
	mapas = Array(maparea.decompress(9999999))
	for x in range(0,mapasbounds):
		for y in range(0,mapasbounds):
			$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),mapas[y*mapasbounds+x])
	$Game/players.get_node(str(currentplayerid)).set_name(str(myid))
	currentplayerid = myid
	for i in range(0,len(players),playerdatasize):
		if players[i] != currentplayerid:
			spawnplayertogame(players[i],players[i+1])
remote func setname(name):
	var sender = get_tree().get_rpc_sender_id()
	spawnplayertogame(sender,name)
	players[players.find_last(sender)+1] = name
remote func u(newpos):
	$Game/players.get_node(str(get_tree().get_rpc_sender_id())).position = newpos
remote func uallah():
	var who = str(get_tree().get_rpc_sender_id())
	$Game/players.get_node(who).get_node("Sprite").set_texture(preload("res://pray.png"))
	yield(get_tree().create_timer(1.0), "timeout")
	$Game/players.get_node(who).get_node("Sprite").set_texture(preload("res://arabMan.png"))
var praynotplaying = true
func _process(delta):
	if gamestarted:
		for i in $ui/stuff.get_children():
			i.set_value(i.get_value()-0.1)
	if Input.is_action_pressed("ui_right"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
	if Input.is_action_pressed("ui_left"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
	if Input.is_action_pressed("ui_down"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
	if Input.is_action_pressed("ui_up"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
	if Input.is_action_just_pressed("inventory"):
		$ui/inventory.visible = not $ui/inventory.visible
	if Input.is_action_just_pressed("pray") and praynotplaying and $Game/players.get_node(str(currentplayerid)).get_node("Sprite").get_texture() == preload("res://arabMan.png"):
		rpc("uallah")
		$ui/stuff/pray.set_value($ui/stuff/pray.get_value()+50)
		$Game/players.get_node(str(currentplayerid)).get_node("allah").play()
		$Game/players.get_node(str(currentplayerid)).get_node("Sprite").set_texture(preload("res://pray.png"))
		praynotplaying = false
		yield(get_tree().create_timer(1.0), "timeout")
		praynotplaying = true
		if $Game/players.get_node(str(currentplayerid)).get_node("Sprite").get_texture() == preload("res://pray.png"):
			$Game/players.get_node(str(currentplayerid)).get_node("Sprite").set_texture(preload("res://arabMan.png"))
func _on_generatename_pressed():
	$Multiplayer_window/currentplayername.text = Firstname[randi() % Firstname.size()] + Middlename[randi() % Middlename.size()] + Lastname[randi() % Lastname.size()]
var selectedslot = 2
func _on_slot1_pressed():
	selectedslot = 1
func _on_slot2_pressed():
	selectedslot = 2
func _on_slot3_pressed():
	selectedslot = 3
func _on_slot5_pressed():
	selectedslot = 5
func _on_slot4_pressed():
	selectedslot = 4
func _on_slot6_pressed():
	selectedslot = 6
func _on_slot7_pressed():
	selectedslot = 7
func _on_slot8_pressed():
	selectedslot = 8
func _on_slot9_pressed():
	selectedslot = 9
func _on_x_pressed():
	$ui/inventory.visible = false
func _on_drop_pressed():
	var kas = $ui/inventory/GridContainer.get_node("slot"+str(selectedslot)).get_button_icon()
	if kas != null:
		spawnitem(kas)
		rpc("spawnitem",kas)
		$ui/inventory/GridContainer.get_node("slot"+str(selectedslot)).set_button_icon(null)
remote func spawnitem(who):
	var daigtas = $Game/TileMap/item.duplicate()
	daigtas.set_texture(who)
	$Game/items.add_child(daigtas)
