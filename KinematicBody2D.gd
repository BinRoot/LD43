extends KinematicBody2D

export (int) var SPEED = 200

var velocity

func _ready():
	pass

func get_user_input():
	velocity = Vector2()
	if Input.is_action_pressed('p1_up'):
		velocity.y -= 1
	if Input.is_action_pressed('p1_down'):
		velocity.y += 1
	if Input.is_action_pressed('p1_left'):
		velocity.x -= 1
	if Input.is_action_pressed('p1_right'):
		velocity.x += 1
	velocity = velocity.normalized() * SPEED
	print(velocity)

func _physics_process(delta):
	get_user_input()
	move_and_slide(velocity)