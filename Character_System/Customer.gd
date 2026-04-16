extends RigidBody3D

# This grabs the folder containing all 5 character models
@onready var mesh_container = $Meshes

func _ready():
	# 1. Get a list of all the character models inside the folder
	var all_characters = mesh_container.get_children()
	
	# 2. Hide everyone first
	for character in all_characters:
		character.hide()
		
	# 3. Roll a random number and pick one character to reveal
	var random_index = randi() % all_characters.size()
	var chosen_character = all_characters[random_index]
	chosen_character.show()
	
	# 4. Find that specific character's animation player and make them walk
	var anim_player = chosen_character.get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.play("Rig_Medium_MovementBasic/Walking_A")
