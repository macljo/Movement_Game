extends Area3D

@export var speed := 50.0
@export var life_time = 3.0

var explosion_scene = preload("res://weapons/rpg/explosion.tscn")

var direction = Vector3.FORWARD

func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(queue_free)
	timer.start(life_time)
	
func _physics_process(delta):
	global_translate(direction * speed * delta)

func _on_body_entered(body: Node3D) -> void:
	print("rocket body: ", body.name)
	
	var explosion_instance = explosion_scene.instantiate()
	get_tree().root.add_child(explosion_instance)
	explosion_instance.global_transform.origin = global_transform.origin
		
	queue_free()
