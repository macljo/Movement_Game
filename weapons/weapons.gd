class_name Weapons extends Resource

@export var name : StringName
@export_category("Weapon Orientation")
@export var position : Vector3
@export var rotation : Vector3
@export_category("Visual Settings")
@export var mesh : Mesh
@export var shadow : bool
@export_category("Bullet Weapon Function")
@export var base_damage : float
@export var bullet_count : int
@export var spread_angle : float
@export var knockback : float
@export var ammo_capacity : float
@export var reload_time : float
@export var fire_delay : float
@export var range : float
@export_category("Explosive Weapon Function")
@export var explosion_radius : float
@export var explosion_damage : float
@export var explosion_knockback_force : float
@export var projectile_speed : float
@export var explosion_scene_path : String
