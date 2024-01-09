extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(overlap)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func overlap(body):
	if body is CharacterBody3D:
		body.die()
