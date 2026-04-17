extends Node3D

func _ready():
	# Loop through every item in the Market Assets folder
	for item in get_children():
		generate_collision(item)

func generate_collision(node):
	# If this node is a Mesh, give it a collision shape
	if node is MeshInstance3D:
		node.create_convex_collision()
	
	# Check all sub-nodes (in case the mesh is buried deep)
	for child in node.get_children():
		generate_collision(child)
