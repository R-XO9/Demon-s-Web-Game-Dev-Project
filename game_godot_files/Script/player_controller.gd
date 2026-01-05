extends CharacterBody2D

# =====================
# MOVEMENT
# =====================
const SPEED := 300.0
const JUMP_VELOCITY := -520.0

# =====================
# JUMP ANIMATION TUNING
# =====================
const APEX_VELOCITY_THRESHOLD := 40.0
const APEX_HANG_TIME := 0.30  # 🔥 increase/decrease for longer apex

# =====================
# NODES
# =====================
@onready var player: AnimatedSprite2D = $Player_Sprite
@onready var leg: AnimatedSprite2D = $leg_run
@onready var slash: AnimatedSprite2D = $slash

# =====================
# STATE
# =====================
var attacking := false
var attack_step := 0

var was_on_floor := false
var at_apex := false
var apex_timer := 0.0


# =====================
# READY
# =====================
func _ready() -> void:
	player.animation_finished.connect(_on_player_anim_finished)
	slash.animation_finished.connect(_on_slash_finished)

	slash.hide()
	slash.frame = 0


# =====================
# PHYSICS
# =====================
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")

	# Attack
	if Input.is_action_just_pressed("attack") and not attacking:
		start_attack_1()

	# Jump
	if Input.is_action_just_pressed("jump") and was_on_floor:
		velocity.y = JUMP_VELOCITY
		at_apex = false
		apex_timer = 0.0

	# Horizontal movement
	if direction != 0:
		velocity.x = direction * SPEED
		player.flip_h = direction < 0
		leg.flip_h = direction < 0
		slash.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animation(direction)

	was_on_floor = is_on_floor()


# =====================
# ATTACK LOGIC
# =====================
func start_attack_1() -> void:
	attacking = true
	attack_step = 1
	player.play("hit_idle")
	play_slash("hit")


func start_attack_2() -> void:
	attack_step = 2
	player.play("hit2")
	play_slash("hit2")


func play_slash(anim: String) -> void:
	slash.frame = 1 # skip empty frame
	slash.show()
	slash.play(anim)


# =====================
# ANIMATION CONTROL
# =====================
func update_animation(direction: float) -> void:
	# -----------------
	# ATTACKING
	# -----------------
	if attacking:
		update_legs(direction)
		return

	# -----------------
	# JUMP (3 PHASE + HANG)
	# -----------------
	if not is_on_floor():
		player.animation = "jump"

		# Rising
		if velocity.y < -APEX_VELOCITY_THRESHOLD:
			player.frame = 0
			at_apex = false
			apex_timer = 0.0

		# Apex (linger)
		elif abs(velocity.y) <= APEX_VELOCITY_THRESHOLD:
			player.frame = 1
			at_apex = true

		# Falling (delayed)
		else:
			if at_apex:
				apex_timer += get_physics_process_delta_time()
				if apex_timer < APEX_HANG_TIME:
					player.frame = 1
				else:
					player.frame = 2
					at_apex = false
			else:
				player.frame = 2

		update_legs(direction)
		return

	# -----------------
	# GROUND
	# -----------------
	if abs(velocity.x) > 1:
		player.play("run")
		update_legs(direction)
	else:
		player.play("idle")
		leg.hide()


func update_legs(direction: float) -> void:
	if direction != 0:
		if leg.animation != "runsword":
			leg.play("runsword")
		leg.show()
	else:
		if attacking:
			if leg.animation != "stopsword":
				leg.play("stopsword")
			leg.show()
		else:
			leg.hide()


# =====================
# SIGNALS
# =====================
func _on_player_anim_finished() -> void:
	if attack_step == 1:
		if Input.is_action_pressed("attack"):
			start_attack_2()
		else:
			reset_attack()
	elif attack_step == 2:
		reset_attack()


func _on_slash_finished() -> void:
	slash.hide()


func reset_attack() -> void:
	attacking = false
	attack_step = 0
