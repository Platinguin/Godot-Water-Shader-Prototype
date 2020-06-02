extends Spatial

export(float) var wind_strength = 0.7 setget set_wind_strength

var time = 0.0
var wind_modified = 1.0

var visual_material
var physical_material

var gerstner_height
var gerstner_normal
var gerstner_stretch
var gerstner_2_height
var gerstner_2_normal
var gerstner_2_stretch
var bubble_amount
var foam_amount
var bubble_gerstner
var foam_gerstner
var detail_normal_intensity

var shift_vector
var curl_strength

func _ready():
	visual_material = $waterplane.material_override
	physical_material = $render_targets/vector_map_buffer/image.material
	
	gerstner_height = visual_material.get_shader_param("gerstner_height")
	gerstner_normal = visual_material.get_shader_param("gerstner_normal")
	gerstner_stretch = visual_material.get_shader_param("gerstner_stretch")
	gerstner_2_height = visual_material.get_shader_param("gerstner_2_height")
	gerstner_2_normal = visual_material.get_shader_param("gerstner_2_normal")
	gerstner_2_stretch = visual_material.get_shader_param("gerstner_2_stretch")
	bubble_amount = visual_material.get_shader_param("bubble_amount")
	foam_amount = visual_material.get_shader_param("foam_amount")
	detail_normal_intensity = visual_material.get_shader_param("detail_normal_intensity")
	bubble_gerstner = visual_material.get_shader_param("bubble_gerstner")
	foam_gerstner = visual_material.get_shader_param("foam_gerstner")
	
	shift_vector = physical_material.get_shader_param("shift_vector")
	curl_strength = physical_material.get_shader_param("curl_strength")

func update_water(wind):
	visual_material.set_shader_param("gerstner_height", gerstner_height * wind)
	visual_material.set_shader_param("gerstner_normal", gerstner_normal * wind)
	visual_material.set_shader_param("gerstner_stretch", gerstner_stretch * wind)
	visual_material.set_shader_param("gerstner_2_height", gerstner_2_height * wind)
	visual_material.set_shader_param("gerstner_2_normal", gerstner_2_normal * wind)
	visual_material.set_shader_param("gerstner_2_stretch", gerstner_2_stretch * wind)
	visual_material.set_shader_param("bubble_amount", bubble_amount * wind)
	visual_material.set_shader_param("foam_amount", foam_amount * wind)
	visual_material.set_shader_param("detail_normal_intensity", detail_normal_intensity * wind)
	visual_material.set_shader_param("bubble_gerstner", bubble_gerstner * wind)
	visual_material.set_shader_param("foam_gerstner", foam_gerstner * wind)
	
	physical_material.set_shader_param("shift_vector", shift_vector * wind)
	physical_material.set_shader_param("curl_strength", curl_strength * clamp(wind, 1.0, 1.2))

func set_wind_strength(value):
	wind_strength = value

func get_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	return files

func set_water_style(value):
	var style_path = "res://textures/water/gradients"
	var style_list = get_files_in_directory(style_path)
	var gradient = GradientTexture.new()
	
	gradient.gradient = load(style_path + "/" + style_list[value])
	visual_material.set_shader_param("water_color", gradient)
	
func set_subsurface_scattering(value):
	visual_material.set_shader_param("sss_strength", value);

func _physics_process(delta):
	time += 0.005
	wind_modified = wind_modified + ((wind_strength + sin(time) * 0.2) - wind_modified) * delta * 0.5
	
	# DEBUG WIND VAR
	#print(wind_modified)
	
	update_water(wind_modified)
