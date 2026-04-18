extends DirectionalLight3D

@export var day_speed: float = 0.08

func _process(delta):
	var time = Time.get_ticks_msec() * 0.001
	var pulse = (sin(time * 2.0) + 1.0) * 0.5 # 0.0 to 1.0 pulse
	
	# Surging Rotation (Speeds up and slows down)
	var dynamic_speed = day_speed * (1.0 + pulse * 2.0)
	rotate_x(delta * dynamic_speed * 0.16)
	rotate_y(delta * dynamic_speed * 0.35)
	rotate_z(delta * dynamic_speed * 0.4)
	
	# Hyper-Dramtic Lighting
	light_energy = 1.0 + pulse * 2.0 # Brightness pulses between 1 and 3
	light_color = Color.from_hsv(fmod(time * 0.1, 1.0), 0.6, 1.0) # Slowly shift through rainbow colors
