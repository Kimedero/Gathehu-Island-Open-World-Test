tool
extends VBoxContainer

const DebugGraph := preload("./monitor_overlay_debug_graph.gd")

# Monitors
#export_group("Active Monitors")
#export_subgroup("Time")
export var fps := true setget set_fps
func set_fps(value):
		fps = value
		rebuild_ui()
export var process := false setget  set_process
func set_process(value):
		process = value
		rebuild_ui()
export var physics_process := false setget  set_physics_process
func set_physics_process(value):
		physics_process = value
		rebuild_ui()
#export_subgroup("Memory")
export var static_memory := false setget  set_static_memory
func set_static_memory(value):
		static_memory = value
		rebuild_ui()
export var max_static_memory := false setget  set_max_static_memory
func set_max_static_memory(value):
		max_static_memory = value
		rebuild_ui()
export var max_message_buffer := false setget  set_max_message_buffer
func set_max_message_buffer(value):
		max_message_buffer = value
		rebuild_ui()
#export_subgroup("Objects")
export var objects := false setget  set_objects
func set_objects(value):
		objects = value
		rebuild_ui()
export var resources := false setget  set_resources
func set_resources(value):
		resources = value
		rebuild_ui()
export var nodes := false setget  set_nodes
func set_nodes(value):
		nodes = value
		rebuild_ui()
export var orphan_nodes := false setget  set_orphan_nodes
func set_orphan_nodes(value):
		orphan_nodes = value
		rebuild_ui()
#export_subgroup("Raster")
export var objects_drawn := false setget  set_objects_drawn
func set_objects_drawn(value):
		objects_drawn = value
		rebuild_ui()
export var primitives_drawn := false setget  set_primitives_drawn
func set_primitives_drawn(value):
		primitives_drawn = value
		rebuild_ui()
export var total_draw_calls := false setget  set_total_draw_calls
func set_total_draw_calls(value):
		total_draw_calls = value
		rebuild_ui()
#export_subgroup("Video")
export var video_memory := false setget  set_video_memory
func set_video_memory(value):
		video_memory = value
		rebuild_ui()
export var texture_memory := false setget  set_texture_memory
func set_texture_memory(value):
		texture_memory = value
		rebuild_ui()
export var buffer_memory := false setget  set_buffer_memory
func set_buffer_memory(value):
		buffer_memory = value
		rebuild_ui()
#export_subgroup("Physics 2D")
export var active_objects_2d := false setget  set_active_objects_2d
func set_active_objects_2d(value):
		active_objects_2d = value
		rebuild_ui()
export var collision_pairs_2d := false setget  set_collision_pairs_2d
func set_collision_pairs_2d(value):
		collision_pairs_2d = value
		rebuild_ui()
export var islands_2d := false setget  set_islands_2d
func set_islands_2d(value):
		islands_2d = value
		rebuild_ui()
#export_subgroup("Physics 3D")
export var active_objects_3d := false setget  set_active_objects_3d
func set_active_objects_3d(value):
		active_objects_3d = value
		rebuild_ui()
export var collision_pairs_3d := false setget  set_collision_pairs_3d
func set_collision_pairs_3d(value):
		collision_pairs_3d = value
		rebuild_ui()
export var islands_3d := false setget  set_islands_3d
func set_islands_3d(value):
		islands_3d = value
		rebuild_ui()
#export_subgroup("Audio")
export var audio_output_latency := false setget  set_audio_output_latency
func set_audio_output_latency(value):
		audio_output_latency = value
		rebuild_ui()

# Graph options
#export_group("Options")
## Sampling rate in samples per second
export (float, 0.0, 1000.0) var sampling_rate := 60.0 setget  set_sampling_rate
func set_sampling_rate(value):
		sampling_rate = value
		# if sampling rate is 0, _t_limit is infinity
		_t_limit = 1 / sampling_rate
export var normalize_units := true setget  set_normalize_units
func set_normalize_units(value):
		normalize_units = value
		rebuild_ui()
export var plot_graphs := true setget  set_plot_graphs
func set_plot_graphs(value):
		plot_graphs = value
		rebuild_ui()
export var history := 100 setget  set_history
func set_history(value):
		history = value
		rebuild_ui()
export var background_color := Color(0.0, 0.0, 0.0, 0.5) setget  set_background_color
func set_background_color(value):
		background_color = value
		rebuild_ui()
export var graph_color := Color.orange setget  set_graph_color
func set_graph_color(value):
		graph_color = value
		rebuild_ui()
export var graph_height := 50 setget  set_graph_height
func set_graph_height(value):
		graph_height = value
		rebuild_ui()
export var graph_thickness := 1.0 setget  set_graph_thickness
func set_graph_thickness(value):
		graph_thickness = value
		rebuild_ui()
export var graph_antialiased := false setget  set_graph_antialiased
func set_graph_antialiased(value):
		graph_antialiased = value
		rebuild_ui()

var _graphs := []
var _t := 0.0
var _t_limit := 0.0


func _ready():
#	if custom_minimum_size.x == 0:
	if rect_min_size.x == 0:
		rect_min_size.x = 300
	rebuild_ui()


func clear() -> void:
	for graph in _graphs:
		graph.queue_free()
	_graphs = []


func rebuild_ui() -> void:
	clear()
	if fps:
		_create_graph_for(Performance.TIME_FPS, "FPS")

	if process:
		_create_graph_for(Performance.TIME_PROCESS, "Process", "s")

	if physics_process:
		_create_graph_for(Performance.TIME_PHYSICS_PROCESS, "Physics Process", "s")

	if static_memory:
		_create_graph_for(Performance.MEMORY_STATIC, "Static Memory", "B")

	if max_static_memory:
		_create_graph_for(Performance.MEMORY_STATIC_MAX, "Max Static Memory", "B")

	if max_message_buffer:
		_create_graph_for(Performance.MEMORY_MESSAGE_BUFFER_MAX, "Message Buffer Max")

	if objects:
		_create_graph_for(Performance.OBJECT_COUNT, "Objects")

	if resources:
		_create_graph_for(Performance.OBJECT_RESOURCE_COUNT, "Resources")

	if nodes:
		_create_graph_for(Performance.OBJECT_NODE_COUNT, "Nodes")

	if orphan_nodes:
		_create_graph_for(Performance.OBJECT_ORPHAN_NODE_COUNT, "Orphan Nodes")

	if objects_drawn:
		_create_graph_for(Performance.RENDER_OBJECTS_IN_FRAME, "Objects Drawn") # RENDER_TOTAL_OBJECTS_IN_FRAME

	if primitives_drawn:
		_create_graph_for(Performance.RENDER_VERTICES_IN_FRAME, "Primitives Drawn") # RENDER_TOTAL_PRIMITIVES_IN_FRAME

	if total_draw_calls:
		_create_graph_for(Performance.RENDER_DRAW_CALLS_IN_FRAME, "3D Draw Calls") # RENDER_TOTAL_DRAW_CALLS_IN_FRAME

	if video_memory:
		_create_graph_for(Performance.RENDER_VIDEO_MEM_USED, "Video Memory", "B")

	if texture_memory:
		_create_graph_for(Performance.RENDER_TEXTURE_MEM_USED, "Texture Memory", "B")

	if buffer_memory:
		_create_graph_for(Performance.RENDER_BUFFER_MEM_USED, "Vertex Memory", "B")

	if active_objects_2d:
		_create_graph_for(Performance.PHYSICS_2D_ACTIVE_OBJECTS, "2D Active Objects")

	if collision_pairs_2d:
		_create_graph_for(Performance.PHYSICS_2D_COLLISION_PAIRS, " 2D Collision Pairs")

	if islands_2d:
		_create_graph_for(Performance.PHYSICS_2D_ISLAND_COUNT, "2D Islands")

	if active_objects_3d:
		_create_graph_for(Performance.PHYSICS_3D_ACTIVE_OBJECTS, " 3D Active Objects")

	if collision_pairs_3d:
		_create_graph_for(Performance.PHYSICS_3D_COLLISION_PAIRS, "3D Collision Pairs")

	if islands_3d:
		_create_graph_for(Performance.PHYSICS_3D_ISLAND_COUNT, "3D Islands")

	if audio_output_latency:
		_create_graph_for(Performance.AUDIO_OUTPUT_LATENCY, "Audio Latency", "s")


func _process(delta: float) -> void:
	_t += delta
	if _t >= _t_limit:
		_t = 0
		for item in _graphs:
			item.update() # queue_redraw()


func _create_graph_for(monitor: int, monitor_name: String, unit: String = "") -> void:
	var graph = DebugGraph.new()
	graph.monitor = monitor
	graph.monitor_name = monitor_name
	graph.font = get_theme_default_font()
	graph.rect_min_size.y = graph_height
	graph.max_points = history
	graph.background_color = background_color
	graph.graph_color = graph_color
	graph.plot_graph = plot_graphs
	graph.unit = unit
	graph.normalize_units = normalize_units
	graph.thickness = graph_thickness
	graph.antialiased = graph_antialiased
	
	add_child(graph)
	_graphs.push_back(graph)
