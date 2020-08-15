extends KinematicBody2D


# Declare member variables here. Examples:
var move = Vector2()
var dash = Vector2()
var speed = 25
var dashSpeed = 1000

const dashDelay = 2
var dashTimer = 0

var possessing = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta):
	$CollisionShape2D/Sprite.visible = not possessing
	$arrow.look_at(get_global_mouse_position())
	
	#WHEN NOT POSSESSING
	if not possessing:
		$CollisionShape2D/Sprite.flip_h = get_global_mouse_position().x > get_global_position().x
		
		#DASH ABILITY TIMER
		if dashTimer <= 0:
			$arrow/Sprite.texture = load("res://sprites/arrow_full.png")
		else:
			$arrow/Sprite.texture = load("res://sprites/arrow.png")
			dashTimer = clamp(dashTimer - delta, 0, dashDelay)
		
		#MOVEMENT
		if Input.is_action_pressed("mouseL"):
			if get_global_mouse_position().distance_to(get_global_position()) > 20:
				move += (get_global_mouse_position() - get_global_position()).normalized() * speed
		
		#DASH
		if dashTimer <= 0:
			if Input.is_action_just_pressed("mouseR"):
				dash = (get_global_mouse_position() - get_global_position()).normalized() * dashSpeed
				dashTimer = dashDelay
				#dash = (get_global_mouse_position() - get_global_position()).normalized() * get_global_mouse_position().distance_to(get_global_position()) * dashSpeed
		
		
		
		#GOING THROUGH WALLS
		set_collision_layer_bit(2, not dash.length() > 100)
		set_collision_mask_bit(2, not dash.length() > 100)
		
		
		move_and_slide(move + dash)
		
		if dash.length() > 100:
			$CollisionShape2D/Sprite.modulate = Color(1, 0.5, 0.5)
			dash = dash*0.9
			move = move*0.7
		else:
			dash = Vector2(0,0)
			$CollisionShape2D/Sprite.modulate = Color(1, 1, 1)
			move = move*0.9
	
	
	#WHEN POSSESSING
	else:
		global_position = possessing.global_position
		
		
		if possessing.abilityTimer <= 0:
			$arrow/Sprite.texture = load("res://sprites/arrow_full.png")
		else:
			$arrow/Sprite.texture = load("res://sprites/arrow.png")
		
		#STOP POSSESSING
		if Input.is_action_just_pressed("space"):
			possessing.possessed = false
			possessing.dizzy = 4
			possessing = null
	pass


func _on_Area2D_body_entered(body):
	#POSSESS VESSEL
	if body.is_in_group("vessel"):
		if body.dizzy <= 0:
			if dash.length() > 100 and not possessing:
				possessing = body
				body.possessed = true
				move = Vector2(0,0)
				dash = Vector2(0,0)
	pass # Replace with function body.
