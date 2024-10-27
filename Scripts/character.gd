extends KinematicBody
class_name Character

export var manual_control: bool = true # whather the character is a bot or manually controlled

var velocity: Vector3
onready var SPEED: float = WALK_SPEED
export var WALK_SPEED: float = 5.0
export var SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
var GRAVITY: float = ProjectSettings.get("physics/3d/default_gravity")
var GRAVITY_VECTOR = ProjectSettings.get("physics/3d/default_gravity_vector")

var HEALTH: int = 100

onready var head: Spatial = $head

var direction: Vector3
var input_dir: Vector2
export var MOUSE_SENSITIVITY: float = 0.2

var target: Spatial # the character we are targeting

var nav_path: Array # path to follow to target
var closest_point: Vector3 # nearest point on the navigation grid / region
var nav_agent: NavigationAgent
#var next_path_pos: Vector3 # the next point on the navigation path to head to on the way to the final position

var nav_time_slice: int # enhancing the performance of navigation path refreshes
var nav_time_slice_max: int = 15 # the number of frames to wait before refreshing the navigation path
var nav_time_slice_check: int # what frame to do refresh the navigation path at

enum AUTO_STATE{IDLE, APPROACH, ATTACK, WANDER}
var auto_state: int
var last_auto_state: int

var rotation_speed: float = 4.0 # speed by which the mesh rotates round to face the target

# LINE OF SIGHT
var line_of_sight: bool = false # if we can see target
var in_front: bool = false # if target is in front of us
var dist_to_target: float
var los_time_slice: int # enhancing the performance of line of sight checks
var los_time_slice_max: int = 15 # the number of frames to wait before doing a LOS check
var los_time_slice_check: int # what frame to do LOS check at

var idle_time: float = 15 # the time it takes to power down and recover
var idle_time_delta: float

var wander_time: float = 25 # we time it takes to wander before going idle
var wander_time_delta: float

#the actionable distances
var min_attack_distance: float = 10 # 5
var min_approach_distance: float = 25 # 12
var min_wander_distance: float = 80

#var target_moved: bool = false # keeps track of if the target has moved substantially in order to update the navigation path

func _ready() -> void:
	#this part randomizes the time to check for navigation and line of sight
	nav_time_slice_check = randi() % nav_time_slice_max
	los_time_slice_check = randi() % los_time_slice_max
	#print("%s - nav time - %s" % [self, nav_time_slice_check])
	#print("%s - los time - %s" % [self, los_time_slice_check])
	
	#if !manual_control:
		#connect()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * GRAVITY_VECTOR * delta
	
	match manual_control:
		true:
			direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
			
			$infoLabel3D.text 	= "Health: %s" % [HEALTH]
		false:
			process_auto_state(delta)
			
			# this part is to reduce the number of times we calculate line of sight for performance purposes
			los_time_slice = wrapi(los_time_slice + 1, 0, los_time_slice_max)
			if los_time_slice == los_time_slice_check:
				CharacterLineOfSightQueueManager.calc_line_of_sight(self)
			
			# the idea is that when we get to the attack distance we start facing the player instead of the next position of the path
			if line_of_sight and dist_to_target <= min_attack_distance: # 16: # and in_front
				direction = (target.global_position - global_position).normalized()
				auto_mesh_rotation(direction, delta)
			
			$infoLabel3D.text = "LOS: %s\nIn Front: %s\nDist To Target: %.2f\nAuto State: %s - Path Size: %s" % [line_of_sight, in_front, dist_to_target, auto_state, nav_path.size()]
			
	move_and_slide(velocity, Vector3.UP, true, 4, PI * 0.25, false)


func _input(event: InputEvent) -> void:
	if manual_control:
		process_manual_movement_input()
		process_mouse_movement(event)
		process_sprint()
		process_jump()


func process_auto_state(delta):
	match auto_state:
		AUTO_STATE.IDLE:
			auto_state_change_notify()
			
			idle_time_delta += delta
			if idle_time_delta >= idle_time:
				auto_state = AUTO_STATE.APPROACH
				idle_time_delta = 0
			
			#if dist_to_target <= min_approach_distance and line_of_sight:
				#auto_state = AUTO_STATE.APPROACH
		
		AUTO_STATE.APPROACH:
			auto_state_change_notify()
			
			# this part is to reduce the number of times we calculate the navigation path for performance purposes
			nav_time_slice = wrapi(nav_time_slice + 1, 0, nav_time_slice_max)
			if nav_time_slice == nav_time_slice_check:
				CharacterNavigationQueueManager.calc_path(self, nav_agent)
				
			if nav_path.size() >= 2:
				var current_path_pos = nav_path[0]
				var next_path_pos = nav_path[1] # necessary to ensure the character faces the right direction as it moves along the navigation path
				#print("%s Current Pos: %s - Current path Pos: %s - next_spot: %s" % [self, global_position, current_path_pos, next_path_pos])
				direction = (next_path_pos - global_position).normalized()
				
				auto_mesh_rotation(direction, delta)
				
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				
				if closest_point.distance_to(current_path_pos) <= 2.0:
					nav_path.erase(current_path_pos)
			
			# we check for distance and line of sight to attack
			if dist_to_target <= min_attack_distance and line_of_sight:
				auto_state = AUTO_STATE.ATTACK
			#if we get too far away we start wandering
			if dist_to_target >= min_wander_distance:
				auto_state = AUTO_STATE.WANDER
				
		AUTO_STATE.ATTACK:
			auto_state_change_notify()
			
			#we stop moving when attacking
			velocity = Vector3.ZERO
			
			#we check for distance or lack of line of sight to approach
			if (dist_to_target >= min_attack_distance and dist_to_target <= min_approach_distance) or !line_of_sight:
				auto_state = AUTO_STATE.APPROACH
		
		AUTO_STATE.WANDER:
			auto_state_change_notify()
			
			wander_time_delta += delta
			if wander_time_delta >= wander_time:
				auto_state = AUTO_STATE.IDLE
				wander_time_delta = 0
			
			
			#while wandering around should we come within approach distance of the target and see it
			if dist_to_target <= min_approach_distance and line_of_sight:
				auto_state = AUTO_STATE.APPROACH


func process_manual_movement_input():
	input_dir = Input.get_vector("move_left", "move_right","move_forward","move_back")


func process_mouse_movement(event):
	var _mouse_movement = event as InputEventMouseMotion
	if _mouse_movement:
		rotation_degrees.y -= _mouse_movement.relative.x * MOUSE_SENSITIVITY
		head.rotation_degrees.x -= _mouse_movement.relative.y * MOUSE_SENSITIVITY
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -60, 45)


func process_sprint():
	if Input.is_action_pressed("sprint"):
		SPEED = SPRINT_SPEED
	else:
		SPEED = WALK_SPEED


func process_jump():
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func auto_mesh_rotation(dir: Vector3, delta: float):
	var _left_axis: Vector3 = Vector3.UP.cross(-dir)
	var _rotation_basis: Basis = Basis(_left_axis, Vector3.UP, -dir)
	global_transform.basis = global_transform.basis.slerp(_rotation_basis.orthonormalized(), rotation_speed * delta)


func auto_state_change_notify():
	if auto_state != last_auto_state:
		var a_str: String
		var b_str: String
		match auto_state:
			AUTO_STATE.IDLE:
				a_str = "IDLE"
			AUTO_STATE.APPROACH:
				a_str = "APPROACH"
			AUTO_STATE.ATTACK:
				a_str = "ATTACK"
			AUTO_STATE.WANDER:
				a_str = "WANDER"
		
		match last_auto_state:
			AUTO_STATE.IDLE:
				b_str = "IDLE"
			AUTO_STATE.APPROACH:
				b_str = "APPROACH"
			AUTO_STATE.ATTACK:
				b_str = "ATTACK"
			AUTO_STATE.WANDER:
				b_str = "WANDER"
			
		print("%s auto_state has changed from %s to %s - Dist to target: %d" % [name, b_str, a_str, dist_to_target])
	
	last_auto_state = auto_state
