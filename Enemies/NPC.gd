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
var path = PoolVector2Array()
var state = null
var point = 0
onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var spawnLocation = null
onready var triggerOnce = 0
onready var nav : Navigation2D = $"../../../Navigation2D"
onready var line : Line2D = $"../../../Line2D"
onready var assignmentPosition = null
onready var assignCollision = $AssignCollision

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)
	if triggerOnce == 0:
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
			assignmentPosition = get_parent().position
			var goal = assignmentPosition
			path = nav.get_simple_path(self.global_position, goal, false)
			line.points = PoolVector2Array(path)
			line.show()
			if global_position == path[point]:
				point += 1
			move_and_slide((path[point] - global_position).normalized() * MAX_SPEED)
			if goal.x / position.x > 0.8 && goal.y / position.y > 0.8:
				wanderController.start_position == global_position
				state = pick_new_state([IDLE, WANDER]) 
				wanderController.start_wander_timer(rand_range(1, 3))
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector()* delta * 400
	velocity = move_and_slide(velocity)
func trigger_once():
	spawnLocation = self.global_position
	triggerOnce = 1
	state = GO_TO_ASSIGNMENT

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

