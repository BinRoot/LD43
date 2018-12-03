extends Node2D

var p1

func _ready():
	var p1 = get_tree().get_nodes_in_group('user')[0]
	
func check_victory():
	var victory = true
	for unit in get_tree().get_nodes_in_group('unit'):
		if unit.AFFILIATION != 'P1':
			victory = false
	
	var ps = get_tree().get_nodes_in_group('user')
	if ps.size() > 0:
		p1 = ps[0]
	if victory:
		if weakref(p1).get_ref():
			p1.get_node('./VictoryLabel').show()	
	else:
		if p1 != null:
			var wr = weakref(p1)
			if (!wr.get_ref()):
				pass
			elif p1 != null and p1.get_node('./VictoryLabel') != null:
			    p1.get_node('./VictoryLabel').hide()
			

func _process(delta):
	check_victory()
	if Input.is_action_pressed('restart'):
		get_tree().reload_current_scene()

func _on_P1_game_over():
	print('p1 died')
	get_tree().reload_current_scene()
