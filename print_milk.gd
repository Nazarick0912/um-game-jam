extends SceneTree

func _init():
    var scene = load("res://Kitchen Asset/Models/milk.fbx").instantiate()
    print_tree(scene, "")
    quit()

func print_tree(node, indent):
    print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        print_tree(child, indent + "  ")
