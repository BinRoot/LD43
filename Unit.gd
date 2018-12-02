extends KinematicBody2D

export (String) var CONTROLLER = 'CPU'
export (String) var AFFILIATION = 'P1'
export (int) var POWER = 10
export (Color) var color
export (bool) var chant_heard = false
export (bool) var sacrifice_leader = false
var prev_chant_heard = 0

enum Message { SPLIT_FROM_TEAM, JOIN_WITH_TEAM, JOIN_WITH_ENEMY, KILLED_ENEMY, CHANT, CHANT_RESPONSE }

var nlg = {
	SPLIT_FROM_TEAM: ["Go distract them!", "Time to split!", "I'm going rogue", "Go die in honor!", 
		"Go be a distraction!", "Your actions won't be forgotten!"],
	JOIN_WITH_TEAM: ["Join me", "Let's go", "Come with me", "Regroup!", "This way!", "Come!", 
		"Good work so far!", "Let's team up", "Together we fight!"],
	JOIN_WITH_ENEMY: ["You're mine!", "I'm your leader now!", "You obey me, now!", "Where's your god now?", 
		"I am your king!", "You are now prisoners!", "I have killed your leader!"],
	KILLED_ENEMY: ["Ha!", "Die!", "Raw!", "Ho!"],
	CHANT: ["Ho!"],
	CHANT_RESPONSE: ["Ha!"]
}

const inf = 3.402823e+38
const ninf = -2.802597e-45

var player_controller = {
	'P1': {'up': 'p1_up', 'down': 'p1_down', 'left': 'p1_left', 'right': 'p1_right', 
		'split_1': 'p1_split_1', 'split_2': 'p1_split_2', 'split_3': 'p1_split_3',
		'chant': 'p1_chant'},
	'P2': {'up': 'p2_up', 'down': 'p2_down', 'left': 'p2_left', 'right': 'p2_right',
		'split_1': 'p2_split_1', 'split_2': 'p2_split_2', 'split_3': 'p2_split_3',
		'chant': 'p2_chant'}
}

var affiliation_color = {
	'P1': Color(0, 0, 255),
	'P2': Color(0, 255, 0),
	'CPU': Color(255, 0, 0)
}

var affiliation_speed = {
	'P1': 100,
	'P2': 100,
	'CPU': 100
}

var velocity 
export (Vector2) var direction = Vector2()
var goal_position
export (float) var SPEED = null
var sword_points_at_enemy = false


func _ready():
	add_to_group("unit")
	add_to_group(AFFILIATION)
	set_colors()
	set_collision_layer_bit(0, true)
	set_collision_mask_bit(0, true)
	if SPEED != null:
		affiliation_speed[AFFILIATION] = SPEED
	
	
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
	if Input.is_action_just_pressed(player_controller[CONTROLLER]['chant']):
		say(Message.CHANT)
		for unit in get_parent().get_children():
			unit.chant_heard = true
	if velocity.length() != 0:
		direction = direction.normalized() * 0.9 + velocity.normalized() * 0.1
	velocity = velocity.normalized() * affiliation_speed[AFFILIATION]
	
func split_faction(split_type):
	say(Message.SPLIT_FROM_TEAM)
	var split_modulo = split_type + 1
	var current_faction = get_node('.').get_parent()
	var faction_units = current_faction.get_children()
	var sub_faction_primary = Node2D.new()
	var sub_faction_secondary = Node2D.new()
	
	faction_units.erase(self)
	sub_faction_primary.add_child(self.duplicate())
	
	for unit_idx in range(faction_units.size()):
		var unit = faction_units[unit_idx]
		get_node('.').get_parent().remove_child(unit)
		if unit_idx % split_modulo == split_modulo - 1:
			sub_faction_primary.add_child(unit.duplicate())
		else:
			sub_faction_secondary.add_child(unit.duplicate())
	get_node('.').get_parent().get_parent().add_child(sub_faction_primary)
	get_node('.').get_parent().get_parent().add_child(sub_faction_secondary)
	current_faction.queue_free()
	
	
func get_faction_leader(faction):
	var max_power = -1.0
	var leader = self
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
	if get_faction_leader(get_parent()).color == null:
		get_faction_leader(get_parent()).color = Color(randf(), randf(), randf())
	$Shadow.color = get_faction_leader(get_parent()).color
	
	var end_color = affiliation_color[AFFILIATION].darkened((1.0 - 1.0 / POWER) * 0.5)
	
	if get_faction_leader(get_parent()) == get_node('.'):
		$ColorRect.color = affiliation_color[AFFILIATION].lightened((1.0 - 1.0 / POWER) * 0.5)
	else:
		if $ColorRect.color != null:
			$Tween.interpolate_property($ColorRect, 'color', 
				$ColorRect.color, end_color, 0.3, 
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			yield($Tween, 'tween_completed')
		else:
			$ColorRect.color = end_color
	
func get_max(nums):
	var max_idx = -1
	var highest_val = ninf
	for idx in range(nums.size()):
		if nums[idx] > highest_val:
			highest_val = nums[idx]
			max_idx = idx
	return max_idx
	
func _draw():
	if goal_position != null:
		pass
		#draw_line(Vector2(0, 0), goal_position - position, Color(0.5, 0.5, 0.5), 1)
	
func get_p1():
	for unit in get_tree().get_nodes_in_group('unit'):
		if unit.CONTROLLER == 'P1':
			return unit
		
func get_system_input():
	var enemy = find_nearest_enemy()
	velocity = Vector2()
	# identify leader of faction
	var leader = get_faction_leader(get_parent())
	if leader == get_node('.'):
		if enemy != null:
			velocity = (enemy.position - position).normalized() * affiliation_speed[AFFILIATION]
		else:
			var p1 = get_p1()
			velocity = (p1.position - position).normalized() * affiliation_speed[AFFILIATION]
			
	else:
		#print('{n} is following leader {m}'.format({'n': get_node('.').name, 'm': leader.name}))
		velocity = leader.position - position
		var candidate_positions = []
		for i in range(10, 40, 1):
			candidate_positions.append(leader.position + leader.direction.normalized()*50 + leader.direction.tangent().normalized() * i)
			candidate_positions.append(leader.position + leader.direction.normalized()*50 - leader.direction.tangent().normalized() * i)
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
			avg_candidate_dists[candidate_idx] /= (faction_units.size() + 0.0)
			avg_candidate_dists[candidate_idx] -= candidate_positions[candidate_idx].distance_to(position)
		var max_dist_from_player = 50.0
		var max_candidate_idx = get_max(avg_candidate_dists)
		if velocity.length() > max_dist_from_player or enemy == null:
			sword_points_at_enemy = false
			
			var dist_to_goal = candidate_positions[max_candidate_idx].distance_to(position)
			var speed = dist_to_goal
			
			velocity = (candidate_positions[max_candidate_idx] - position).normalized() * speed
			goal_position = candidate_positions[max_candidate_idx]
			update()
		else:
			sword_points_at_enemy = true
			var dist_ratio = velocity.length() / max_dist_from_player
			var speed = affiliation_speed[AFFILIATION]
			if dist_ratio > 0.01:
				speed = -log(dist_ratio) * affiliation_speed[AFFILIATION] * 10
			velocity = (enemy.position - position).normalized() * speed
			goal_position = enemy.position
			update()
	if velocity.length() != 0:
		direction = direction.normalized() * 0.9 + velocity.normalized() * 0.1

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
	var avg_direction = Vector2()
	for unit in get_node('.').get_parent().get_children():
		avg_direction += unit.direction
	return avg_direction.normalized()

func rotate_sword():
	if direction.length() != 0:
		var enemy = find_nearest_enemy()
		var num_units_in_faction = 0
		var enemy_vec = Vector2()
		if enemy != null:
			enemy_vec = enemy.position - position
			num_units_in_faction = enemy.get_parent().get_children().size()
		if sword_points_at_enemy and enemy_vec.length() != 0:
			var avg_sword = get_faction_sword_direction()
			$Sword.rotation = (enemy_vec * 0.1 + avg_sword * 0.9).angle()
		elif CONTROLLER == 'CPU':
			$Sword.rotation = (enemy_vec * 0.1 + direction).angle()
		else:
			$Sword.rotation = direction.angle()

func set_speed():
	var faction_size = get_parent().get_children().size()
	var speed_factor = 2.0 / faction_size
	SPEED = speed_factor * affiliation_speed[AFFILIATION]

func _physics_process(delta):
	if CONTROLLER == "CPU":
		get_system_input()
	else:
		get_user_input()
	move_and_slide(velocity)
	rotate_sword()
	set_colors()
	set_speed()
	if chant_heard and CONTROLLER == 'CPU' and OS.get_unix_time() - prev_chant_heard > 1:
		POWER += 1
		say(Message.CHANT_RESPONSE)
		chant_heard = false
		prev_chant_heard = OS.get_unix_time()

func join_with(faction):
	for unit in faction.get_children():
		var unit2 = unit.duplicate()
		unit2.AFFILIATION = AFFILIATION
		get_parent().add_child(unit2)
		unit.queue_free()
	
func say(message_type):
	var chat = load('res://Chat.tscn').instance()
	chat.position += Vector2(0, -20)
	#var text_color = affiliation_color[AFFILIATION].darkened(0.5)
	var utterance = nlg[message_type][randi() % nlg[message_type].size()]
	match message_type:
		JOIN_WITH_ENEMY:
			chat.init(utterance, 2)
		JOIN_WITH_TEAM:
			chat.init(utterance, 2)
		SPLIT_FROM_TEAM:
			chat.init(utterance, 2)
		KILLED_ENEMY:
			chat.init(utterance, 0.5)
		CHANT:
			chat.init(utterance, 0.5)
		CHANT_RESPONSE:
			chat.init(utterance, 0.5)
			chat.delay(1)
	chat.set('z', 1)
	add_child(chat)

func _on_Sword_body_entered(body):
	if not 'CONTROLLER' in body:
		return
	var faction_leader_of_body = get_faction_leader(body.get_parent())
	if 'AFFILIATION' in body and body.AFFILIATION != AFFILIATION:
		print('{me} ({me_power}) hit {other} ({other_power})'.format({'me': name, 'other': body.name, 'me_power': POWER, 'other_power': body.POWER}))
		if randi() % body.POWER == 0:
			if faction_leader_of_body == body:
				if not sacrifice_leader: 
					join_with(body.get_parent())
					say(Message.JOIN_WITH_ENEMY)
				else:
					say(Message.CHANT)
					for unit in get_parent().get_children():
						unit.chant_heard = true
			else:
				say(Message.KILLED_ENEMY)
			body.queue_free()
	elif body.get_parent() != get_parent():
		if faction_leader_of_body == body and get_faction_leader(get_parent()) == get_node('.'):
			join_with(body.get_parent())
			say(Message.JOIN_WITH_TEAM)

