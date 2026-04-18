extends Label3D

# InstructionSign.gd
# A pulsing instruction board attached to the starting wall (CSGBox3D9).
# Gently bobs its modulate so the sign feels alive.

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	# Subtle brightness pulse between 85% and 100% white
	var brightness = 0.92 + 0.08 * sin(_time * 1.5)
	modulate = Color(brightness, brightness, brightness, 1.0)
