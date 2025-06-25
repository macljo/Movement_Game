extends CharacterBody3D

@export var speed := 20.0
@export var explosion_scene_path := ""

var direction := Vector3.FORWARD
var _explosion_packed_scene : PackedScene = null

func _ready():
	if has_node("Timer"):
		$Timer.timeout.connect(_on_timer_timeout)
	else:
		printerr("Warning: Rocket scene is missing a Timer node")
		
	print("Rocket _ready() called. Position: ", global_transform.origin, " Direction: ", direction, " Speed: ", speed)
		
func _physics_process(delta: float) -> void:
	velocity = direction * speed
	
	var collision = move_and_slide()
	
	if collision:
		trigger_explosion(global_transform.origin)
		queue_free()
		
func trigger_explosion(position : Vector3):
	if _explosion_packed_scene:
		var explosion_instance = _explosion_packed_scene.instantiate()
		get_tree().root.add_child(explosion_instance)
		explosion_instance.global_transform.origin = position
		
		var weapon_data = get_meta("weapon_data", null)
		var player_ref = get_meta("player_ref", null)
		
		if weapon_data and is_instance_valid(player_ref):
			if explosion_instance.has_method("setup_explosion"):
				explosion_instance.setup_explosion(
					weapon_data.explosion_damage,
					weapon_data.explosion_knockback_force,
					weapon_data.explosion_radius,
					player_ref
				)
			else:
				printerr("Explosion instance does not have 'setup_explosion' method.")
		else:
			printerr("Failed to retrieve weapon_data or player_ref from rocket metadata for explosion.")
	else:
		printerr("No explosion scene loaded in rocket to trigger. Path was: ", explosion_scene_path)
		
func _on_timer_timeout():
	trigger_explosion(global_transform.origin)
	queue_free()
	
func init_rocket(p_direction : Vector3, p_weapon_data : Weapons, p_player : CharacterBody3D):
	direction = p_direction
	speed = p_weapon_data.projectile_speed
	
	explosion_scene_path = p_weapon_data.explosion_scene_path
	print("Rocket.gd init_rocket: Received and set explosion_scene_path to: ", explosion_scene_path)
	
	set_meta("weapon_data", p_weapon_data)
	set_meta("player_ref", p_player)
	
	if not explosion_scene_path.is_empty():
		_explosion_packed_scene = load(explosion_scene_path) # <--- USED HERE (loads the scene)
		if not _explosion_packed_scene:
			printerr("Error: Rocket.gd init_rocket: Failed to load explosion scene: ", explosion_scene_path)
	else:
		printerr("Error: Rocket.gd init_rocket: No explosion_scene_path provided by weapon data.") # <--- YOUR ERROR ORIGINATES HERE
	
	if speed > 0:
		if has_node("Timer"):
			$Timer.wait_time = p_weapon_data.range / speed
			print("Rocket timer set to: ", $Timer.wait_time, " seconds. Range: ", p_weapon_data.range, " Speed: ", speed)
		else:
			printerr("Rocket missing timer node")
