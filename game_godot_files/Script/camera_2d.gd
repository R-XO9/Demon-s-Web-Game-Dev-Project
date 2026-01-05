extends Camera2D

@export var follow_strength: float = 12.0
@export var look_ahead_distance: float = 60.0
@export var deadzone: Vector2 = Vector2(24, 16)
@export var max_vertical_offset: float = 60.0
@export var target_path: NodePath

var target: CharacterBody2D
var look_ahead: float = 0.0


func _ready() -> void:
	if target_path != NodePath():
		target = get_node(target_path) as CharacterBody2D
	else:
		target = get_parent() as CharacterBody2D

	global_position = target.global_position


func _process(delta: float) -> void:
	if target == null:
		return

	var desired_pos: Vector2 = target.global_position

	# ======================
	# LOOK AHEAD (LOCKED)
	# ======================
	var vx: float = target.velocity.x
	if abs(vx) > 10.0:
		look_ahead = sign(vx) * look_ahead_distance
	else:
		look_ahead = 0.0

	desired_pos.x += look_ahead

	# ======================
	# DEADZONE
	# ======================
	var diff: Vector2 = desired_pos - global_position

	if abs(diff.x) < deadzone.x:
		diff.x = 0.0
	if abs(diff.y) < deadzone.y:
		diff.y = 0.0

	diff.y = clamp(diff.y, -max_vertical_offset, max_vertical_offset)

	# ======================
	# CLAMP CAMERA SPEED
	# ======================
	var max_cam_speed: float = max(abs(target.velocity.x), 120.0)
	var move: Vector2 = diff * follow_strength * delta

	move.x = clamp(move.x, -max_cam_speed * delta, max_cam_speed * delta)

	global_position += move
