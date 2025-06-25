@tool

extends Node3D

@export var WEAPON_TYPE : Weapons:
	set(value):
		WEAPON_TYPE = value

@onready var weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var weapon_shadow : MeshInstance3D = %WeaponShadow

func _ready() -> void:
	load_weapon()
	
func _input(event):
	if event.is_action_pressed("weapon1"):
		WEAPON_TYPE = load("res://weapons/shotgun/shotgun.tres")
		if WEAPON_TYPE:
			print("INIT_WEAPON: Loaded rocket launcher. Name: ", WEAPON_TYPE.name)
		else:
			printerr("INIT_WEAPON: FAILED to load shotgun.tres! Check path")
		load_weapon()
	elif event.is_action_pressed("weapon2"):
		WEAPON_TYPE = load("res://weapons/rpg/rpg.tres")
		if WEAPON_TYPE:
			print("INIT_WEAPON: Loaded rocket launcher. Name: ", WEAPON_TYPE.name)
			print("INIT_WEAPON: Rocket Launcher Explosion Path from resource: ", WEAPON_TYPE.explosion_scene_path)
		else:
			printerr("INIT_WEAPON: FAILED to load rpg.tres! Check path")
		load_weapon()
	
func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	weapon_shadow.visible = WEAPON_TYPE.shadow
