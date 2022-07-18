extends Node2D
var mapas = []
var mapasbounds = 100
var currentplayerid = 1
var Firstname = ["Abdul ", "Mehmed ", "Ali ", "Amir ", "Muhamed ", "Khalif "]
var Middlename = ["al-","adin-","wiyah","bakr-","suley","hash-"]
var Lastname = ["aladin","yadiz II","yabadil","nashneed","wataqik","qahir"]
var gamestarted = false
var config = ConfigFile.new()
var err = config.load("user://config.cfg")
var daigoeilas = 1
var speed = 500
func _ready():
	randomize()
	$Multiplayer_window.visible = false
	$Main_menu.visible = true
	$Game.visible = false
	$ui/stuff.visible = false
	$ui/inventory.visible = false
	for i in $ui/inventory/GridContainer.get_children():
		i.set_button_icon(null)
	$ui/inventory/GridContainer/slot1.set_button_icon(preload("res://arabCarSolo.png"))
func _on_Exit_pressed():
	get_tree().quit()
func generate_map():
	var randass = 0.0
	var noise = OpenSimplexNoise.new()
	if $Multiplayer_window/seed.text:
		noise.seed = hash($Multiplayer_window/seed.text)
	else:
		noise.seed = randi()
	noise.octaves = 0.6
	noise.period = 20.0
	noise.persistence = 20
	for x in range(0,mapasbounds):
		for y in range(0,mapasbounds):
			randass = noise.get_noise_2d(x, y)#randi() % 500
			if randass > 0.45:
				$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),4)
				mapas.append(4)
			elif randass < -0.45:
				$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),6)
				mapas.append(6)
			elif randi() % 500 == 1 and randass < 0.45 and randass > -0.45:
				$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),5)
				mapas.append(5)
			elif randi() % 500 == 1 and randass < 0.45 and randass > -0.45:
				$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),7)
				mapas.append(7)
			else:
				$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),0)
				mapas.append(0)
func preparegamestart():
	gamestarted = true
	$Multiplayer_window.visible = false
	$Main_menu.visible = false
	$Game.visible = true
	$Game/players.get_node(str(currentplayerid)).get_node("Camera2D").current = true
	$Game/players.get_node(str(currentplayerid)).visible = true
	$ui/stuff.visible = true
	$Game/players.get_node(str(currentplayerid)).get_node("nametag").text = $Multiplayer_window/currentplayername.text
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
	$Multiplayer_window/Join.visible = true
	$Multiplayer_window/servername.visible = true
	$Multiplayer_window/serverportis.visible = true
	$Multiplayer_window/tagserverip.visible = true
	$Multiplayer_window/tagport.visible = true
	$Multiplayer_window/Host.text = "Host"
func _on_Singleplayer_pressed():
	$Multiplayer_window.visible = true
	if err != OK:
		$Multiplayer_window/currentplayername.text = Firstname[randi() % Firstname.size()] + Middlename[randi() % Middlename.size()] + Lastname[randi() % Lastname.size()]
	else:
		for player in config.get_sections():
			$Multiplayer_window/currentplayername.text = config.get_value("man", "name")
			$Multiplayer_window/serverportis.text = config.get_value("man", "port")
			$Multiplayer_window/servername.text = config.get_value("man", "ip")
	$Multiplayer_window/Join.visible = false
	$Multiplayer_window/servername.visible = false
	$Multiplayer_window/serverportis.visible = false
	$Multiplayer_window/tagserverip.visible = false
	$Multiplayer_window/tagport.visible = false
	$Multiplayer_window/Host.text = "Play singleplayer"
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
	if $Multiplayer_window/Host.text == "Play singleplayer":
		return
	get_tree().connect("network_peer_connected",self,"_player_connected")
	get_tree().connect("network_peer_disconnected",self,"playerdisconekt")
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
	get_tree().connect("server_disconnected", self, "death")
	get_tree().set_network_peer(peer)
func _player_connected(id):
	var listofchilds = []
	var listofchildsnames = []
	var listofitems = []
	var listofitemsposition = []
	for i in $Game/players.get_children():
		listofchilds.append(int(i.name))
		listofchildsnames.append(i.get_node("nametag").text)
	for i in $Game/items.get_children():
		listofitems.append(i.get_texture().resource_path)
		listofitemsposition.append(i.position.x)
		listofitemsposition.append(i.position.y)
	rpc_id(id, "loadmap",mapasbounds,PoolIntArray(mapas),PoolIntArray(listofchilds),PoolStringArray(listofchildsnames),id,PoolStringArray(listofitems),PoolRealArray(listofitemsposition),daigoeilas)
func _iconnectedtoserver():
	rpc("setname",$Multiplayer_window/currentplayername.text)
	preparegamestart()
remote func loadmap(mapsize,maparea,playerlist,playerlistnames,myid,itemnames,itempos,daigoeilasas):
	mapasbounds = mapsize
	daigoeilas = daigoeilasas
	var playerslistas = Array(playerlist)
	var playerlistnamai = Array(playerlistnames)
	var itemnamai = Array(itemnames)
	var itemposai = Array(itempos)
	playerslistas.append(myid)
	playerlistnamai.append($Multiplayer_window/currentplayername.text)
	mapas = Array(maparea)
	for i in range(-1,len(itemnamai)-1):
		spawnitem(itemnamai[i],Vector2(itemposai[i*2],itemposai[i*2+1]))
	for x in range(0,mapasbounds):
		for y in range(0,mapasbounds):
			$Game/TileMap.set_cellv(Vector2(x-(mapasbounds/2),y-(mapasbounds/2)),mapas[y*mapasbounds+x])
	$Game/players.get_node(str(currentplayerid)).set_name(str(myid))
	currentplayerid = myid
	for i in range(0,len(playerslistas)):
		if playerslistas[i] != currentplayerid:
			spawnplayertogame(playerslistas[i],playerlistnamai[i])
remote func setname(name):
	var sender = get_tree().get_rpc_sender_id()
	spawnplayertogame(sender,name)
remote func u(newpos):
	var senderid = get_tree().get_rpc_sender_id()
	var sender = $Game/players.get_node(str(senderid))
	if sender:
		sender.position = newpos
	else:
		rpc_id(senderid,"SAY_MY_NAME")
remote func SAY_MY_NAME():
	var senderid = get_tree().get_rpc_sender_id()
	rpc_id(senderid,"OK_MY_NAME_IS",$Game/players.get_node(str(currentplayerid)).get_node("nametag").text)
remote func OK_MY_NAME_IS(thename):
	var senderid = get_tree().get_rpc_sender_id()
	if not $Game/players.get_node(str(senderid)):
		spawnplayertogame(senderid,thename)
remote func uallah():
	var who = str(get_tree().get_rpc_sender_id())
	$Game/players.get_node(who).get_node("allah").play()
	$Game/players.get_node(who).get_node("Sprite").set_texture(preload("res://pray.png"))
	yield(get_tree().create_timer(1.0), "timeout")
	$Game/players.get_node(who).get_node("Sprite").set_texture(preload("res://arabMan.png"))
var praynotplaying = true
func _process(delta):
	if not gamestarted:
		return
	for i in $ui/stuff.get_children():
		i.set_value(i.get_value()-0.1)
		if i.get_value() <= 0:
			death("you ran out of "+i.get_name())
	var velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		rpc("u",$Game/players.get_node(str(currentplayerid)).position)
		velocity.y -= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		if $Game/players.get_node(str(currentplayerid)).get_node("Sprite").get_texture().resource_path == "res://arabCar.png":
			velocity = velocity * 3
	$Game/players.get_node(str(currentplayerid)).position += velocity * delta
	position.x = clamp(position.x, 0, 100)
	position.y = clamp(position.y, 0, 100)
	if Input.is_action_just_pressed("inventory"):
		$ui/inventory.visible = not $ui/inventory.visible
	if Input.is_action_just_pressed("pickup"):
		var closest = null
		var closestdis = 999999999
		var playeris = $Game/players.get_node(str(currentplayerid)).position
		for i in $Game/items.get_children():
			if playeris.distance_to(i.position) < closestdis:
				closest = i
				closestdis = playeris.distance_to(i.position)
		if closestdis < 100:
			additemtoinventort(closest.get_texture().resource_path)
			deleteitem(closest.get_name())
			rpc("deleteitem",closest.get_name())
	if Input.is_action_just_pressed("entercar"):
		if $Game/players.get_node(str(currentplayerid)).get_node("Sprite").get_texture().resource_path == "res://arabCar.png":
			$Game/players.get_node(str(currentplayerid)).get_node("Sprite").set_texture(load("arabMan.png"))
			rpc("setplayertexture","arabMan.png",currentplayerid)
			spawnitem("res://arabCarSolo.png",$Game/players.get_node(str(currentplayerid)).position)
			rpc("spawnitem","res://arabCarSolo.png",$Game/players.get_node(str(currentplayerid)).position)
			return
		var closest = null
		var closestdis = 999999999
		var playeris = $Game/players.get_node(str(currentplayerid)).position
		for i in $Game/items.get_children():
			if playeris.distance_to(i.position) < closestdis:
				closest = i
				closestdis = playeris.distance_to(i.position)
		if closestdis < 100:
			useitem(closest.get_name(),currentplayerid)
			rpc("useitem",closest.get_name(),currentplayerid)
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
remote func additemtoinventort(what):
	for i in range(1,10):
		if $ui/inventory/GridContainer.get_node("slot"+str(i)).get_button_icon() == null :
			$ui/inventory/GridContainer.get_node("slot"+str(i)).set_button_icon(load(what))
			return
remote func useitem(what,who):
	if $Game/items.get_node(what).get_texture().resource_path == "res://arabCarSolo.png":
		$Game/items.get_node(what).queue_free()
		$Game/players.get_node(str(who)).get_node("Sprite").set_texture(load("arabCar.png"))
remote func deleteitem(whatitem):
	$Game/items.get_node(whatitem).queue_free()
remote func setplayertexture(what,who):
	$Game/players.get_node(str(who)).get_node("Sprite").set_texture(load(what))
func _on_generatename_pressed():
	$Multiplayer_window/currentplayername.text = Firstname[randi() % Firstname.size()] + Middlename[randi() % Middlename.size()] + Lastname[randi() % Lastname.size()]
var selectedslot = 1
func _on_slot_pressed(target):
	setselectedslot(target)
func setselectedslot(slotid):
	var marker = $ui/inventory/GridContainer.get_node("slot"+str(selectedslot))
	var markeris = $ui/inventory/GridContainer.get_node("slot"+str(selectedslot)).get_node("selection")
	marker.remove_child(markeris)
	$ui/inventory/GridContainer.get_node("slot"+str(slotid)).add_child(markeris)
	selectedslot = slotid
func _on_x_pressed():
	$ui/inventory.visible = false
func die():
	rpc("playerdisconekt",currentplayerid)
remote func playerdisconekt(who):
	$Game/players.get_node(str(who)).queue_free()
remote func spawnitem(who,where):
	var daigtas = $Game/TileMap/item.duplicate()
	daigtas.set_texture(load(who))
	$Game/items.add_child(daigtas)
	daigtas.position = where
	daigtas.set_name(str(daigoeilas))
	daigoeilas = daigoeilas+1
func death(reason):
	$ui/died.visible = true
	if reason:
		$ui/died/nametag.text = reason
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().reload_current_scene()
func _on_drop_pressed():
	var kas = $ui/inventory/GridContainer.get_node("slot"+str(selectedslot)).get_button_icon()
	if kas != null:
		var vieta = $Game/players.get_node(str(currentplayerid)).position
		spawnitem(kas.resource_path,vieta)
		rpc("spawnitem",kas.resource_path,vieta)
		$ui/inventory/GridContainer.get_node("slot"+str(selectedslot)).set_button_icon(null)
