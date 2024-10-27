extends Spatial

onready var nav_map: RID = get_world().get_navigation_map()

var queue: Array
var cache: Dictionary

var paths_calc_per_turn: int = 1

func _physics_process(_delta):
	for turn in range(paths_calc_per_turn):
		dequeue_path_request()


func dequeue_path_request():
	if queue.size() == 0:
		return
	var calc_path_info = queue.pop_front()
	var agent: KinematicBody = calc_path_info.agent
	
	var start_pos: Vector3 = agent.global_position
	var end_pos: Vector3 = agent.target.global_position
	
	var new_path = NavigationServer.map_get_path(nav_map, start_pos, end_pos, true)
	var closest_point = NavigationServer.map_get_closest_point(nav_map, start_pos)
	
	agent.nav_path = new_path
	agent.closest_point = closest_point
	
	cache.erase(str(agent))


func calc_path(agent: KinematicBody, nav_agent: NavigationAgent):
	var key = str(agent)
	if key in cache:
		return
	cache[key] = ""
	queue.append({
		"agent": agent, 
		"nav_agent":nav_agent
		})
