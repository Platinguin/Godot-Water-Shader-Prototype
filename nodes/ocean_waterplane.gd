extends MeshInstance

var camera
var value = 0
export(float) var ocean_height = 0.0

func _ready():
	camera = get_node("../../game_camera/camera")

# warning-ignore:unused_argument
func _physics_process(delta):
	value += 1
	
	if value == 20:
		value = 0
		
		# move waterplane to camera
		transform.origin = camera.transform.origin
		
		# snapping the waterplane to world grid to avoid wobbling
		transform.origin.x = round(transform.origin.x / 2.0) * 2.0 # 4.0 = 4 meter grid
		transform.origin.z = round(transform.origin.z / 2.0) * 2.0
		transform.origin.y = ocean_height # waterheight
