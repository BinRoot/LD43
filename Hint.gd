extends Node2D

export (Vector2) var final_scale = Vector2(1.4, 1.4)
export (float) var float_distance = 20
export (float) var scale_duration = 0.5
export (float) var position_duration = 3
export (float) var modulate_duration = 1

func _ready():
	$Tween.interpolate_property(self, 'scale', scale, final_scale, scale_duration, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	var transparent = modulate
	transparent.a = 0.0
	$Tween.interpolate_property(self, 'position', position, 
		position + Vector2(0, -float_distance), position_duration, $Tween.TRANS_BACK, $Tween.EASE_IN)
	$Tween.start()
	yield($Tween, 'tween_completed')
	
	$Tween.interpolate_property(self, 'position', position, 
		position + Vector2(0, -float_distance*5), position_duration, $Tween.TRANS_BACK, $Tween.EASE_OUT)
	$Tween.interpolate_property(self, 'modulate', modulate, 
		transparent, modulate_duration, 
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	yield($Tween, 'tween_completed')
	
	queue_free()
