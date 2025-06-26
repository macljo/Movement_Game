extends Node3D

@export var launch_force := 20.0
@export var launch_upward_factor := 1.0
@export var blast_radius := 5.0

@onready var particles = $GPUParticles3D
@onready var audio_player = $AudioStreamPlayer3D

func _ready():
	particles.emitting = true
	
	if audio_player:
		audio_player.play()
	
	await get_tree().process_frame
	
	launch_player()
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	queue_free()

func launch_player():
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() > 0:
		var player = players[0]
		
		if player is CharacterBody3D:
			var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
			
			print("Explosion position: ", global_transform.origin)
			print("Player position: ", player.global_transform.origin)
			print("Distance to player: ", distance_to_player)
			
			if distance_to_player <= blast_radius:
				var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
				
				var launch_direction = (direction_to_player + Vector3.UP * launch_upward_factor).normalized()
				
				var force_falloff = 1.0 - (distance_to_player / blast_radius)
				var final_force = launch_force * force_falloff
				
				player.velocity += launch_direction * final_force
				
				print("Launched player!")
