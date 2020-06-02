extends Spatial

var camera
var camera_speed = 2.0
var camera_turn_speed = 2.0
var camera_mouse_turn_speed = 0.5
var camera_start_pos = Vector3(0.0, 1.0, 0.0)

var value = 0
var audio

func set_sun_glare(value):
	$post_fx_1.material.set_shader_param("glare_amount", value)

func _ready():
	camera = $camera
	audio = $audio_waves
	
	# start position and angle
	camera.transform.origin = camera_start_pos

func _input(event):
	if (event is InputEventMouseMotion and event.button_mask & BUTTON_MASK_RIGHT):
		var delta = get_process_delta_time()
		var turn_to = Vector2(event.relative.x * camera_mouse_turn_speed * delta, event.relative.y * camera_mouse_turn_speed * delta)
		camera.look_at(camera.transform.origin - camera.transform.basis[2] + camera.transform.basis[0] * turn_to.x - camera.transform.basis[1] * turn_to.y, Vector3.UP)
		
func _process(delta):
	value += 1
	
	if Input.is_action_just_pressed("hide_menu"):
		var ui = get_node("../ui")
		
		if ui.is_visible():
			ui.hide()
		else:
			ui.show()
	if Input.is_action_pressed("game_left"):
		camera.transform.origin -= camera.transform.basis[0] * Input.get_action_strength("game_left") * camera_speed * delta
	if Input.is_action_pressed("game_right"):
		camera.transform.origin += camera.transform.basis[0] * Input.get_action_strength("game_right") * camera_speed * delta
	if Input.is_action_pressed("game_up"):
		camera.transform.origin -= camera.transform.basis[2] * Input.get_action_strength("game_up") * camera_speed * delta
	if Input.is_action_pressed("game_down"):
		camera.transform.origin += camera.transform.basis[2] * Input.get_action_strength("game_down") * camera_speed * delta
	if Input.is_action_pressed("game_turn_left"):
		camera.look_at(camera.transform.origin - camera.transform.basis[2] - camera.transform.basis[0] * Input.get_action_strength("game_turn_left") * camera_turn_speed * delta, Vector3.UP)
	if Input.is_action_pressed("game_turn_right"):
		camera.look_at(camera.transform.origin - camera.transform.basis[2] + camera.transform.basis[0] * Input.get_action_strength("game_turn_right") * camera_turn_speed * delta, Vector3.UP)
	if Input.is_action_pressed("game_turn_up"):
		camera.look_at(camera.transform.origin - camera.transform.basis[2] + camera.transform.basis[1] * Input.get_action_strength("game_turn_up") * camera_turn_speed * delta, Vector3.UP)	
	if Input.is_action_pressed("game_turn_down"):
		camera.look_at(camera.transform.origin - camera.transform.basis[2] - camera.transform.basis[1] * Input.get_action_strength("game_turn_down") * camera_turn_speed * delta, Vector3.UP)
		
	audio.transform.origin = get_node("../game_camera/camera").transform.origin
	audio.transform.origin.y = 0.0
