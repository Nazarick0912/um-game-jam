extends SceneTree

func _init():
    var scene = load("res://Mart Asset/Models/FBX format/shelf-boxes.fbx").instantiate()
    print_tree(scene, "")
    quit()

func print_tree(node, indent):
    print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        print_tree(child, indent + "  ")
