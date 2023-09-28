extends CharacterBody3D

var SPEED
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0

# This is a var due to being potentially modified via ice physics!
var STOP_MOMENTUM = 4.0

const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.0075

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

const LOOK_MIN = -60
const LOOK_MAX = 60

const BASE_FOV = 75.0
const MOVE_FOV = 1.5

var mouseUnlocked = true
var unlockKeybind = KEY_Q
var cursorIcon = Resource.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D

# Private Functions #
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _updateMouse():
	if mouseUnlocked:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Public Functions #
func _ready():
	camera.fov = BASE_FOV
	mouseUnlocked = false
	cursorIcon.set("res://CursorDot.png", Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(cursorIcon, Input.CURSOR_ARROW, Vector2(0, 0))

func _unhandled_input(event):
	if event is InputEventMouseMotion and not mouseUnlocked:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(LOOK_MIN), deg_to_rad(LOOK_MAX))
		
	if event is InputEventKey:
			if event.pressed and event.keycode == unlockKeybind:
				mouseUnlocked = not mouseUnlocked

func _physics_process(delta):
	# Update Mouse-Lock
	_updateMouse()
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Sprint
	if Input.is_action_pressed("move_sprint"):
		SPEED = SPRINT_SPEED
	else:
		SPEED = WALK_SPEED

	# Get the input direction and handle the movement/deceleration
	# As good practice, you should replace UI actions with custom gameplay actions
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * STOP_MOMENTUM * 2)
			velocity.z = lerp(velocity.z, direction.x * SPEED, delta * STOP_MOMENTUM * 2)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * STOP_MOMENTUM)

	# Handle Viewbobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# Handle FOV
	var clampedVelocity = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var targetFOV = BASE_FOV + MOVE_FOV * clampedVelocity
	camera.fov = lerp(camera.fov, targetFOV, delta * 8.0)

	move_and_slide()
