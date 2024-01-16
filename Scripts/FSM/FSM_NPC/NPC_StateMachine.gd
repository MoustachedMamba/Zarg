extends StateMachine
class_name NPC_StateMachine


var npc: CharacterBody3D


func _ready():
	npc = get_parent()
	super()
	
