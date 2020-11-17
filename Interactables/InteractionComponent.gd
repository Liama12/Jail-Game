extends Area2D

export var interaction_parent : NodePath

signal on_interactable_changed(newInteractable)

var interaction_target : Node

func _process(delta):
	if interaction_target != null and Input.is_action_just_pressed("interact"):
		if interaction_target.has_method("interaction_interact"):
			interaction_target.interaction_interact(self) 
