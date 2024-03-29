extends Camera2D



export var zoom_minas: = 0.8

export var zoom_maxas: = 5

export var zoom_speedas: = 0.1

export var lerp_speed: = 0.2
export var speed = 500
var zoom_min: = Vector2(zoom_minas, zoom_minas)
var zoom_max: = Vector2(zoom_maxas, zoom_maxas)
var zoom_speed: = Vector2(zoom_speedas, zoom_speedas)
var des_zoom: = zoom





func _process(delta: float) -> void:
	
	
	#other
	zoom = lerp(zoom, des_zoom, lerp_speed)





func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.button_index == BUTTON_WHEEL_DOWN:

			change_des_zoom(1)

		elif event.button_index == BUTTON_WHEEL_UP:

			change_des_zoom(-1)





func change_des_zoom(dir: int) -> void:

	des_zoom.x = clamp(des_zoom.x + (zoom_speed.x * dir), zoom_min.x, zoom_max.x)

	des_zoom.y = clamp(des_zoom.y + (zoom_speed.y * dir), zoom_min.y, zoom_max.y)
