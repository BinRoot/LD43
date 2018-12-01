extends KinematicBody2D

export (String) var CONTROLLER = 'CPU'
export (String) var AFFILIATION = 'P1'
export (int) var POWER = 10
export (Color) var color

const inf = 3.402823e+38
const ninf = -2.802597e-45

var player_controller = {
	'P1': {'up': 'p1_up', 'down': 'p1_down', 'left': 'p1_left', 'right': 'p1_right', 
		'split_1': 'p1_split_1', 'split_2': 'p1_split_2', 'split_3': 'p1_split_3'},
	'P2': {'up': 'p2_up', 'down': 'p2_down', 'left': 'p2_left', 'right': 'p2_right',
		'split_1': 'p2_split_1', 'split_2': 'p2_split_2', 'split_3': 'p2_split_3'}
}

var affiliation_color = {
	'P1': Color(0, 0, 255),
	'P2': Color(0, 255, 0),
	'CPU': Color(255, 0, 0)
}

var affiliation_speed = {
	'P1': 200,
	'P2': 200,
	'CPU': 10
}

var velocity 
var SPEED = 200
var sword_points_at_enemy = false

func _ready():
	add_to_group("unit")
	add_to_group(AFFILIATION)
	set_colors()
	set_collision_layer_bit(0, true)
	set_collision_mask_bit(0, true)
	SPEED = affiliation_speed[AFFILIATION]
	
	
func get_user_input():
	velocity = Vector2()
	if Input.is_action_pressed(player_controller[CONTROLLER]['up']):
		velocity.y -= 1
	if Input.is_action_pressed(player_controller[CONTROLLER]['down']):
		velocity.y += 1
	if Input.is_action_pressed(player_controller[CONTROLLER]['left']):
		velocity.x -= 1
	if Input.is_action_pressed(player_controller[CONTROLLER]['right']):
		velocity.x += 1
	if Input.is_action_just_pressed(player_controller[CONTROLLER]['split_1']):
		split_faction(1)
	if Input.is_action_just_pressed(player_controller[CONTROLLER]['split_2']):
		split_faction(2)
	if Input.is_action_just_pressed(player_controller[CONTROLLER]['split_3']):
		split_faction(3)
	velocity = velocity.normalized() * SPEED
	
func split_faction(split_type):
	var split_modulo = split_type + 1
	var current_faction = get_node('.').get_parent()
	var faction_units = current_faction.get_children()
	var sub_faction_primary = Node2D.new()
	var sub_faction_secondary = Node2D.new()
	
	for unit_idx in range(faction_units.size()):
		var unit = faction_units[unit_idx]
		if unit == get_node('.'):
			sub_faction_primary.add_child(unit.duplicate())
		else:
			var unit2 = unit.duplicate()
			get_node('.').get_parent().remove_child(unit)
			if unit_idx % split_modulo == 0:
				sub_faction_primary.add_child(unit2)
			else:
				sub_faction_secondary.add_child(unit2)
	print('{p} primary, {s} secondary'.format({'p': sub_faction_primary.get_children().size(), 's': sub_faction_secondary.get_children().size()}))
	get_node('.').get_parent().get_parent().add_child(sub_faction_primary)
	get_node('.').get_parent().get_parent().add_child(sub_faction_secondary)
	current_faction.queue_free()
	
	
func get_faction_leader(faction):
	var max_power = -1.0
	var leader = get_node('.')
	for unit in faction.get_children():
		if unit.CONTROLLER == 'P1' or unit.CONTROLLER == 'P2':
			return unit
		if unit.POWER > max_power:
			max_power = unit.POWER
			leader = unit
	return leader
	
func set_colors():
	if color == null:
		color = Color(randf(), randf(), randf())
	$Shadow.color = get_faction_leader(get_parent()).color
	$ColorRect.color = affiliation_color[AFFILIATION].darkened((1.0 - 1.0 / POWER) * 0.5)
	if get_faction_leader(get_parent()) == get_node('.'):
		$ColorRect.color = affiliation_color[AFFILIATION].lightened((1.0 - 1.0 / POWER) * 0.5)
	
func get_max(nums):
	var max_idx = -1
	var highest_val = ninf
	for idx in range(nums.size()):
		if nums[idx] > highest_val:
			highest_val = nums[idx]
			max_idx = idx
	return max_idx
	
func get_system_input():
	var enemy = find_nearest_enemy()
	velocity = Vector2()
	# identify leader of faction
	var leader = get_faction_leader(get_parent())
	if leader == get_node('.'):
		# print('{n} is leader'.format({'n': name}))
		if enemy != null:
			velocity = (enemy.position - position).normalized() * SPEED
	else:
		#print('{n} is following leader {m}'.format({'n': get_node('.').name, 'm': leader.name}))
		velocity = leader.position - position
		var candidate_positions = []
		candidate_positions.append(leader.position + velocity.rotated(90).normalized() * 40)
		candidate_positions.append(leader.position + velocity.rotated(-90).normalized() * 41)
		var avg_candidate_dists = []
		for i in range(candidate_positions.size()):
			avg_candidate_dists.append(0)
		var faction_units = get_parent().get_children()
		for unit in faction_units:
			if unit == leader:
				pass
			for candidate_idx in range(candidate_positions.size()):
				avg_candidate_dists[candidate_idx] += candidate_positions[candidate_idx].distance_to(unit.position)
		for candidate_idx in range(candidate_positions.size()):
				avg_candidate_dists[candidate_idx] /= faction_units.size()
		var max_dist_from_player = 50.0
		var max_candidate_idx = get_max(avg_candidate_dists)
		if velocity.length() > max_dist_from_player:
			sword_points_at_enemy = false
			velocity = (candidate_positions[max_candidate_idx] - position).normalized() * SPEED
		else:
			sword_points_at_enemy = true
			var dist_ratio = velocity.length() / max_dist_from_player
			var speed = SPEED
			if dist_ratio > 0.01:
				speed = -log(dist_ratio) * SPEED
			if enemy != null:
				velocity = (enemy.position - position).normalized() * speed
			else:
				velocity = (candidate_positions[max_candidate_idx] - position).normalized() * speed / 5

func find_nearest_enemy():
	var shortest_dist = inf
	var nearest_enemy = null
	var all_units = get_tree().get_nodes_in_group('unit')
	for unit in all_units:
		if unit.AFFILIATION != AFFILIATION:
			#print('{my} enemy is {enemy}'.format({'my': name, 'enemy': unit.name}))
			var dist = (unit.position - position).length()
			if dist < shortest_dist:
				shortest_dist = dist
				nearest_enemy = unit
	#print('{my} nearest enemy is {enemy}'.format({'my': name, 'enemy': nearest_enemy.name}))
	return nearest_enemy

func get_faction_sword_direction():
	var avg_velocity = Vector2()
	for unit in get_node('.').get_parent().get_children():
		avg_velocity += unit.velocity
	return avg_velocity.normalized()

func rotate_sword():
	if velocity.length() != 0:
		var enemy = find_nearest_enemy()
		var num_units_in_faction = 0
		var enemy_vec = Vector2()
		if enemy != null:
			enemy_vec = enemy.position - position
			num_units_in_faction = enemy.get_parent().get_children().size()
		if sword_points_at_enemy and enemy_vec.length() != 0:
			$Sword.rotation = enemy_vec.angle()
		elif CONTROLLER == 'CPU':
			$Sword.rotation = (enemy_vec * 0.1 + velocity).angle()
		else:
			$Sword.rotation = velocity.angle()


func _physics_process(delta):
	if CONTROLLER == "CPU":
		get_system_input()
	else:
		get_user_input()
	move_and_slide(velocity)
	rotate_sword()
	set_colors()

func join_with(faction):
	for unit in faction.get_children():
		get_parent().add_child(unit.duplicate())
		unit.queue_free()
	

func _on_Sword_body_entered(body):
	if 'AFFILIATION' in body and body.AFFILIATION != AFFILIATION:
		print('{me} hit {other}'.format({'me': name, 'other': body.name}))
		if randi() % body.POWER == 0:
			body.queue_free()
	elif body.get_parent() != get_parent():
		if get_faction_leader(body.get_parent()) == body:
			join_with(body.get_parent())

