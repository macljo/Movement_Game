extends CharacterBody3D

@export var look_sensitivity : float = 0.004
@export var jump_velocity := 4.5
@export var auto_bhop := true
@onready var _original_capsule_height = $CollisionShape3D.shape.height
@onready var player_camera = %Camera3D

# ground movement settings
@export var walk_speed := 7.0
@export var crouch_speed := walk_speed * 0.8
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# air movement settings
@export var air_cap := 0.85 # can surf steeper ramps if higher, makes it easier to stick and bhop
@export var air_accel := 1600.0
@export var air_move_speed := 700.0

var wish_dir := Vector3.ZERO

# crouch settings
const CROUCH_TRANSLATE = 0.7
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9 # adds camera jitter in air on crouch
var is_crouched := false

# weapon variables
@onready var init_weapons_node = $"%Camera3D/Weapon"
@onready var fireDelayTimer := $FireDelayTimer
@export var rocket_scene : PackedScene
var can_fire := true

# reference speed label
@onready var speed_label : Label = get_node("/root/World/HUD/SpeedLabel")

func _ready():
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	
	fireDelayTimer.timeout.connect(_on_fire_delay_timer_timeout)
	seed(hash(Time.get_unix_time_from_system()))

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:	
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		if event.is_action_pressed("fire") and can_fire:
			fire_weapon()

func _process(delta):
	if speed_label:
		var current_speed = velocity.length()
		speed_label.text = "Speed: " + str(round(current_speed * 100) / 100.0 * 50) + " UPS"
	
func clip_velocity(normal: Vector3, overbounce : float, delta : float) -> void:
	# allows surfing
	var backoff := self.velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change := normal * backoff
	self.velocity -= change
	
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust

func is_surface_too_steep(normal : Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0, 1, 0))
	if normal.dot(Vector3(0,1,0)) < max_slope_ang_dot:
		return true
	return false

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	# wish speed (if wish_dir > 0 length) capped to air_cap
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap) 
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1, delta) # allows surf

func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = walk_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * walk_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	# apply friction
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	# depending on which way you have the character facing, you may have to negate the input directions
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	_handle_crouch(delta)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
		
	move_and_slide()
	
func _handle_crouch(delta) -> void:
	var was_crouched_last_frame = is_crouched
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	elif is_crouched and not self.test_move(self.global_transform, Vector3(0, CROUCH_TRANSLATE,0)):
		is_crouched = false
		
	# implement source style crouch-jump
	var translate_y_if_possible := 0.0
	if was_crouched_last_frame != is_crouched and not is_on_floor():
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.global_transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		%Head.position.y -= result.get_travel().y
		%Head.position.y = clampf(%Head.position.y, -CROUCH_TRANSLATE, 0)
	
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouched else 0, 7.0 * delta)
	$CollisionShape3D.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2

func fire_weapon():
	var current_weapon_data = init_weapons_node.WEAPON_TYPE
	
	if not current_weapon_data:
		print("No weapon equipped!")
		return
		
	# handle weapon-specific firing logic
	match current_weapon_data.name:
		"Shotgun":
			fire_shotgun(current_weapon_data)
		"RPG":
			spawn_rocket(current_weapon_data)
		_:
			print("Unknown weapon type")
			return
	
	#print("fired: " + current_weapon_data.name)
	can_fire = false
	fireDelayTimer.start(current_weapon_data.fire_delay)

# --- weapon firing implementations ---
func fire_shotgun(weapon_data : Weapons):
	var knockback = weapon_data.knockback
	var knockback_direction = %Camera3D.global_transform.basis.z.normalized()
	self.velocity += knockback_direction * knockback
	
func spawn_rocket(weapon_data : Weapons):
	print("FPSController: Spawning Rocket! Current Weapon Name: ", weapon_data.name)
	print("FPSController: Weapon Data Explosion Path: ", weapon_data.explosion_scene_path)
	
	var knockback_direction = -player_camera.global_transform.basis.z.normalized()
	self.velocity += knockback_direction * weapon_data.knockback
	
	if not rocket_scene:
		printerr("Rocket scene not assigned in FPSController")
		return
		
	var rocket_instance = rocket_scene.instantiate()
	get_tree().root.add_child(rocket_instance)
	
	rocket_instance.global_transform.origin = player_camera.global_transform.origin # CHANGE TO MUZZLE POSITION
	
	var rocket_direction = -player_camera.global_transform.basis.z
	
	rocket_instance.init_rocket(rocket_direction, weapon_data, self)
	
	rocket_instance.look_at(rocket_instance.global_transform.origin + rocket_direction, Vector3.UP)

func get_bullet_direction_with_spread(spread_angle : float) -> Vector3:
	var base_direction = -player_camera.global_transform.basis.z # Forward direction of the camera
	
	# Apply random spread
	var rand_x = randf_range(-1.0, 1.0)
	var rand_y = randf_range(-1.0, 1.0)
	var spread_vector = Vector3(rand_x, rand_y, 0).normalized() * tan(deg_to_rad(spread_angle * 0.5))
	
	# Transform the spread vector by the camera's basis to align with its orientation
	var rotated_spread = player_camera.global_transform.basis * spread_vector
	
	var final_direction = (base_direction + rotated_spread).normalized()
	return final_direction

func _on_fire_delay_timer_timeout():
	can_fire = true
