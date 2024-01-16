extends Node3D
class_name Dummy

var damage = 0.0
var timer = 5.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Sprite3D/SubViewport/Label.text = str(damage)
	timer -= delta
	if timer <= 0.0:
		damage = 0.0

func add_damage(dmg):
	damage += dmg
	timer = 5.0
