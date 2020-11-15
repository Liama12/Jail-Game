extends Node2D

const GrassEffect = preload("res://Effects/GrassEffect.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func create_grass_effect():
	var grassEffect = GrassEffect.instance() #instance that scene and store that in its own variable
	get_parent().add_child(grassEffect) #add the scene as a child of the node you want to add it to
	grassEffect.global_position = global_position #set its position
	queue_free()



func _on_Hurtbox_area_entered(area):
	create_grass_effect()
	queue_free()
