extends Node2D

export (Vector2) var final_scale = Vector2(1.2, 1.2)
export (float) var float_distance = 160
export (float) var duration = 2.25

var delay_duration = 0

func _ready():
	pop()
	
func init(text, duration):
	$Label.text = text
	self.duration = duration
	
func delay(delay_duration):
	self.delay_duration = delay_duration
	
func pop():
	var modulate_old = modulate
	
	var transparent = modulate
	transparent.a = 0.0
	
	if self.delay_duration > 0:
		$Tween.interpolate_property(self, 'modulate', transparent, 
			transparent, self.delay_duration, 
			Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, 'tween_completed')
	
	modulate = modulate_old
	
	$Tween.interpolate_property(self, 'scale', scale, final_scale, duration, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Tween.interpolate_property(self, 'position', position, 
		position + Vector2(0, -float_distance), duration, Tween.TRANS_BACK, Tween.EASE_IN)
	
	$Tween.interpolate_property(self, 'modulate', modulate, 
		transparent, duration, 
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, 'tween_completed')
	queue_free()
	
