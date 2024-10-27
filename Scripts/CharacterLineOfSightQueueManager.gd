extends Spatial

onready var nav_map: RID = get_world().get_navigation_map()

var queue: Array
var cache: Dictionary

var paths_calc_per_turn: int = 1

export var vision_cone_arc: float = 60

var target_last_position: Vector3

func _physics_process(_delta):
	for turn in range(paths_calc_per_turn):
		dequeue_path_request()


func dequeue_path_request():
	if queue.size() == 0:
		return
	var calc_los_info = queue.pop_front()
	var agent: KinematicBody = calc_los_info.agent
	
	var line_of_sight_check = line_of_sight_test(agent)
	var in_front_check = in_front_test(agent)
	var dist_to_target = distance_to_target(agent)
	
	agent.line_of_sight = line_of_sight_check
	agent.in_front = in_front_check
	agent.dist_to_target = dist_to_target
	
	## we check if the target has moved substantially
	#agent.target_moved = agent.target.global_position.distance_to(target_last_position) >= 1.0
	#
	#target_last_position = agent.target.global_position
	
	cache.erase(str(agent))


func calc_line_of_sight(agent: KinematicBody):
	var key = str(agent)
	if key in cache:
		return
	cache[key] = ""
	queue.append({"agent": agent, })


func in_front_test(current_node: Spatial):
	var fwd = current_node.global_transform.basis.z
	var curr_pos = current_node.global_position
	var target_dir = (curr_pos - current_node.target.global_position).normalized()
	return rad2deg(target_dir.angle_to(fwd)) <= vision_cone_arc * 0.5


func line_of_sight_test(current_node: Spatial):
	var space_state: PhysicsDirectSpaceState = get_world().direct_space_state
	var from: Vector3 = current_node.head.global_position
	var to: Vector3 = current_node.target.head.global_position # we assume the node's target has a node called 'head'.
#	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
#	var ray_result: Dictionary = space_state.intersect_ray(ray_query)
	var ray_result: Dictionary = space_state.intersect_ray(from, to)
	if ray_result:
		if ray_result.collider is KinematicBody: # Character
			return true
			#print("%s. collided with: %s - ray_result: %s" % [name, ray_result.collider.name, ray_result])
	return false


func distance_to_target(current_node: Spatial):
	return current_node.head.global_position.distance_to(current_node.target.global_position)
