extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE,
	GO_TO_ASSIGNMENT
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
#var path = PoolVector2Array()
var state = IDLE
onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var spawnLocation = null
onready var triggerOnce = 0
onready var nav_2d : Navigation2D = $"../../../Navigation2D"
onready var line_2d : Line2D = $"../../../Line2D"



func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)
	while triggerOnce == 0:
		trigger_once()
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
			seek_player()
			
			if wanderController.get_time_left() == 0:
				state = pick_new_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
			
		WANDER: 
			seek_player()
			if wanderController.get_time_left() == 0:
				state = pick_new_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
			
			var direction = global_position.direction_to(wanderController.target_position)
			velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
			sprite.flip_h = velocity.x < 0
			if global_position.distance_to(wanderController.target_position) <= WANDER_RANGE:
				state = pick_new_state([IDLE, WANDER]) 
				wanderController.start_wander_timer(rand_range(1, 3))
			
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
			else:
				state = IDLE
			sprite.flip_h = velocity.x < 0
		
		GO_TO_ASSIGNMENT:
			#if get_parent().global_position != spawnLocation:
				# Calculate the movement distance for this frame
			var speed = 50
			var path : = PoolVector2Array()
			var distance_to_walk = speed * delta
			var two = Vector2(22,22)
			path = nav_2d.get_simple_path(self.position, two)
	# Move the player along the path until he has run out of movement or the path ends.
			while distance_to_walk > 0 and path.size() > 0:
				var distance_to_next_point = position.distance_to(path[0])
				if distance_to_walk <= distance_to_next_point:
			# The player does not have enough movement left to get to the next point.
					position += position.direction_to(path[0]) * distance_to_walk
				else:
			# The player get to the next point
					position = path[0]
					path.remove(0)
		# Update the distance to walk
				distance_to_walk -= distance_to_next_point
#				var one = Vector2(11,11)
#				var two = Vector2(22,22)
#				var path = nav_2d.get_simple_path(one, two)
#				nav_2d.call_deferred("get_simple_path")
#				var current_point = 0
#				print(global_position.distance_to(path[current_point]))
#				while global_position != two:
#					while global_position != path[current_point]:
#						var distance = global_position.direction_to(path[current_point])
#						velocity = velocity.move_toward(distance * MAX_SPEED, ACCELERATION * delta)
##						sprite.flip_h = velocity.x < 0
#					current_point += 1
			
			state = IDLE
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector()* delta * 400
	velocity = move_and_slide(velocity)
	
func trigger_once():
	spawnLocation = self.global_position
	triggerOnce = 1

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		
func pick_new_state(state_list):
	state_list.shuffle()#shuffles the state list
	return state_list.pop_front()#picks a random state

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 110
	hurtbox.create_hit_effect()

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position


func _on_BedAssignment_tree_entered():
	state = GO_TO_ASSIGNMENT
#func set_path(value : PoolVector2Array) -> void:
#	path = value
#	if value.size() == 0:
#		return
#	set_process(true)
