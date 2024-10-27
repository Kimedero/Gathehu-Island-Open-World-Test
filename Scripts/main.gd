extends Spatial

var CAMERA_RIG: PackedScene = preload("res://Scenes/camera_rig.tscn")

var CHARACTER: PackedScene = preload("res://Scenes/Characters/character.tscn")

var CHARACTER_MESH: Array

onready var player_spawn_point: Spatial = $CharactersSpawnPoints/PlayerSpawnPoint

onready var enemy_spawn_point: Spatial = $CharactersSpawnPoints/EnemySpawnPoint
onready var enemy_spawn_point_2: Spatial = $CharactersSpawnPoints/EnemySpawnPoint2
onready var enemy_spawn_point_3: Spatial = $CharactersSpawnPoints/EnemySpawnPoint3
onready var enemy_spawn_point_4: Spatial = $CharactersSpawnPoints/EnemySpawnPoint4
onready var enemy_spawn_point_5: Spatial = $CharactersSpawnPoints/EnemySpawnPoint5
onready var enemy_spawn_point_6: Spatial = $CharactersSpawnPoints/EnemySpawnPoint6

var player_character: KinematicBody = null

onready var touch_screen_controls: Control = $TouchScreenControls

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# show touch screen controls when running on an android device
	touch_screen_controls.visible = OS.has_feature("Android")
	
	# spawning the player_character
	add_player_character(player_spawn_point)
	
	# spawning the enmy characters
	add_enemy_character(enemy_spawn_point)
	add_enemy_character(enemy_spawn_point_2)
	add_enemy_character(enemy_spawn_point_3)
	add_enemy_character(enemy_spawn_point_4)
	add_enemy_character(enemy_spawn_point_5)
	add_enemy_character(enemy_spawn_point_6)


func add_character(spawn_point: Spatial):
	var character = CHARACTER.instance()
	character.global_transform = spawn_point.global_transform
	spawn_point.add_child(character)
#	character.reparent(spawn_point.get_parent()) # to have all characters in one node
	reparent_node(character, spawn_point.get_parent())
	return character
	

func add_player_character(spawn_point: Spatial):
	player_character = add_character(spawn_point)
	player_character.name = "PLAYER"
	attach_camera(player_character)


func add_enemy_character(spawn_point: Spatial):
	var enemy_character = add_character(spawn_point)
	enemy_character.name = "ENEMY"
	enemy_character.target = player_character
	enemy_character.manual_control = false
	
	#var nav_agent = NavigationAgent3D.new()
	#nav_agent.avoidance_enabled = true
	#nav_agent.radius = 3.0 # 0.8
	#nav_agent.connect("velocity_computed", Callable(enemy_character, "_on_velocity_computed"))
	#enemy_character.nav_agent = nav_agent
	#enemy_character.add_child(nav_agent)


func attach_camera(node: Spatial):
	var camera_rig = CAMERA_RIG.instance()
	if node.head:
		node.head.add_child(camera_rig)


func reparent_node(current_node: Spatial, parent_node: Spatial):
	current_node.get_parent().remove_child(current_node)
	parent_node.add_child(current_node)
