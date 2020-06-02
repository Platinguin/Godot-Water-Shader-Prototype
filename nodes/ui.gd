extends Control

func _ready():
	pass

func _on_wind_speed_value_changed(value):
	get_node("../ocean").set_wind_strength(value)

func _on_water_style_value_changed(value):
	get_node("../ocean").set_water_style(value)

func _on_subsurface_scattering_value_changed(value):
	get_node("../ocean").set_subsurface_scattering(value)

func _on_sun_glare_value_changed(value):
	get_node("../game_camera").set_sun_glare(value)
