extends CharacterBody2D
class_name BetterJumpPlayer

#region Variables
@export_group("Movement")
@export var max_speed: float = 250.0
@export var acceleration: float = 2000
@export var deceleration: float = 2500
@export var jump_acceleration: float = 1000
@export var jump_deceleration: float = 1200
@export var fall_acceleration: float = 1500
@export var fall_deceleration: float = 1800

@export_group("Jump")
@export var jump_velocity: float = -650.0
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.7
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

var _coyote_timer: float
var _buffer_timer: float

@export_group("Gravity")
@export var gravity: float = 1200.0
@export var fall_gravity: float = 1800.0
@export var apex_gravity: float = 700.0
@export var apex_threshold: float = 80.0

var _velocity: Vector2

@export_group("Sprite")
@export var sprite: Node2D
@export var stretch_intensity: float = 0.002
@export var stretch_lerp_speed: float = 15.0
@export var max_stretch: float = 0.5

var _base_scale: Vector2
#endregion

func _ready():
	if sprite:
		_base_scale = sprite.scale

func _physics_process(delta: float) -> void:
	_movement(delta)
	_jump(delta)
	_gravity(delta)
	_sprite(delta)
	
	velocity = _velocity
	move_and_slide()

func _movement(delta: float) -> void:
	var input_axis := Input.get_axis("left", "right")
	var target_speed := input_axis * max_speed
	var acc: float
	var dec: float
	
	if is_on_floor():
		acc = acceleration
		dec = deceleration
	else:
		if _velocity.y < 0:
			acc = jump_acceleration
			dec = jump_deceleration
		else:
			acc = fall_acceleration
			dec = fall_deceleration
	
	if input_axis != 0:
		_velocity.x = move_toward(_velocity.x, target_speed, acc * delta)
	else:
		_velocity.x = move_toward(_velocity.x, 0.0, dec * delta)
	
func _jump(delta: float) -> void:
	#Coyote Timer
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
	
	#Jump Buffer Timer
	if Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer_time
	else:
		_buffer_timer -= delta
	
	#Jump
	if _coyote_timer > 0 and _buffer_timer > 0:
		_velocity.y = jump_velocity
		_coyote_timer = 0
		_buffer_timer = 0
	
	#Variable Jump Height
	if Input.is_action_just_released("jump") and _velocity.y < 0.0:
		_velocity.y *= jump_cut_multiplier

func _gravity(delta: float) -> void:
	var current_gravity: float
	
	if not is_on_floor():
		#Apex gravity
		if abs(_velocity.y) < apex_threshold:
			current_gravity = apex_gravity
		#Fall gravity
		elif _velocity.y > 0:
			current_gravity = fall_gravity
		#Normal gravity:
		else:
			current_gravity = gravity
	
	_velocity.y += current_gravity * delta

func _sprite(delta: float) -> void:
	if not sprite: return

	var stretch_factor = abs(velocity.y) * stretch_intensity
	var target_y = _base_scale.y * (1.0 + stretch_factor)
	var target_x = _base_scale.x * (1.0 / (1.0 + stretch_factor))
	
	target_y = clamp(target_y,
				_base_scale.y,
				_base_scale.y * (1.0 + max_stretch))
	target_x = clamp(target_x, 
				_base_scale.x * (1.0 - max_stretch),
				_base_scale.x)
	
	sprite.scale.x = lerp(sprite.scale.x, target_x, stretch_lerp_speed * delta)
	sprite.scale.y = lerp(sprite.scale.y, target_y, stretch_lerp_speed * delta)
