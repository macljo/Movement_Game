extends Node3D

@export var explosion_radius :=5-.0
@export var explosion_damage := 50.0
@export var explosion_knockback_force := 20.0

var player_ref : CharacterBody3D

func _ready():
	if has_node("Timer"):
		$Timer.timeout.connect(queue_free)
	else:
		printerr("Explosion scene missing timer node")
		
	play_explosion_effects()
	apply_explosion_effects()
	
func play_explosion_effects():
	if has_node("Debris"):
		$Debris.restart()
	if has_node("Smoke"):
		$Smoke.restart()
	if has_node("Fire"):
		$Fire.restart()
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()
		
func apply_explosion_effects():
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	query.shape.radius = explosion_radius
	query.transform.origin = global_transform.origin
	query.collision_mask = 1
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		if collider:
			var target_position = collider.global_transform.origin
			var direction_to_target = (target_position - global_transform.origin).normalized()
			var distance = global_transform.origin.distance_to(target_position)
			
			var falloff = 1.0 - clampf(distance / explosion_radius, 0.0, 1.0)
			var final_damage = explosion_damage * falloff
			var final_knockback_force = explosion_knockback_force * falloff
			
			if collider.has_method("take_damage"):
				collider.call("take_damage", final_damage)
				
			if collider is CharacterBody3D:
				var body = collider as CharacterBody3D
				var push_vector = direction_to_target * final_knockback_force
				
				push_vector.y += final_knockback_force * 0.5
				
				if body == player_ref:
					player_ref.velocity += push_vector
				else:
					body.velocity += push_vector
			elif collider is RigidBody3D:
				var body = collider as RigidBody3D
				body.apply_central_impulse(direction_to_target * final_knockback_force)

func setup_explosion(p_explosion_damage : float, p_explosion_knockback_force : float, p_explosion_radius: float, p_player_ref : CharacterBody3D):
	explosion_damage = p_explosion_damage
	explosion_knockback_force = p_explosion_knockback_force
	explosion_radius = p_explosion_radius
	player_ref = p_player_ref
