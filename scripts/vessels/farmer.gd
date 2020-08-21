extends KinematicBody2D


# Declare member variables here. Examples:
var possessed = false

var move = Vector2()
var speed = 100
var knockback = Vector2(0,0)

const abilityDelay = 1
var abilityTimer = 0

var state = Game.IDLE

var path = PoolVector2Array()

var color = Game.rand_color()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("vessel")
	add_to_group("alive")
	add_to_group("farmer")
	add_to_group("human")
	randomize()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	$dizzy.visible = state == Game.DIZZY
	$curious.visible = state == Game.CURIOUS
	$scared.visible = state == Game.SCARED
	
	match state:
		Game.POSSESSED:
			possessed(delta)
		Game.DIZZY:
			dizzy()
		Game.IDLE:
			idle()
		Game.CURIOUS:
			curious()
		Game.SCARED:
			scared()
	pass

func idle():
	$AnimationPlayer.play("idle")
	$CollisionShape2D/Sprite.flip_h = move.x < 0
	
	move = move*0.99
	move_and_slide(move)
	pass

func dizzy():
	$AnimationPlayer.play("dizzy")
	move = Vector2(0,0)
	pass

func possessed(delta):
	$CollisionShape2D/Sprite.flip_h = not get_global_mouse_position().x > get_global_position().x
	$AnimationPlayer.play("idle")
	
	#MOVE
	move = Vector2(0,0)
	if Input.is_action_pressed("mouseL"):
		if get_global_mouse_position().distance_to(get_global_position()) > 20:
			move = (get_global_mouse_position() - get_global_position()).normalized() * speed
	move_and_slide(move)
	
	#SAY 'Hey!'
	abilityTimer = clamp(abilityTimer - delta, 0, abilityDelay)
	if abilityTimer <= 0 and Input.is_action_just_pressed("mouseR"):
		abilityTimer = abilityDelay
		print("'Hey!'")
		for body in $Area2D.get_overlapping_bodies():
			if body.is_in_group("chicken"):
				body.get_curious(name)
	
	pass

func curious():
	move_and_slide((path[0]-global_position).normalized()*speed)
	if path[0].distance_to(global_position) <= 32:
		path.remove(0)
	if len(path) == 0:
		state = Game.IDLE
	pass

func _on_Timer_timeout():
	#NPC MOVEMENT
	if state != Game.POSSESSED:
		move = Vector2(((randf()-0.5)*2), ((randf()-0.5)*2)).normalized()*speed
		$Timer.wait_time = randf()*1
	pass # Replace with function body.


func scared():
	move_and_slide((path[0]-global_position).normalized()*speed)
	if path[0].distance_to(global_position) <= 32:
		path.remove(0)
	if len(path) == 0:
		Game.get_main().get_node("church").spawn_priest()
		state = Game.IDLE
	
func get_curious(where):
	if state == Game.IDLE or state == Game.CURIOUS:
		state = Game.CURIOUS
		if path.size() > 0:
			if path[-1].distance_to(global_position) > where.distance_to(global_position):
				path = Game.get_main().get_node("Navigation2D").get_simple_path(global_position, where, false)
		else:
			path = Game.get_main().get_node("Navigation2D").get_simple_path(global_position, where, false) 


func be_scared():
	if state == Game.IDLE or state == Game.CURIOUS or state == Game.SCARED:
		var nearChurch = false
		for body in $Area2D.get_overlapping_bodies():
			if body.is_in_group("church"):
				print(body.is_in_group("church"))
			nearChurch = nearChurch or body.is_in_group("church")
		if not nearChurch:
			state = Game.SCARED
			path = Game.get_main().get_node("Navigation2D").get_simple_path(global_position, Game.get_main().get_node("church").global_position, false)

func die():
	var headstone = load("res://scenes/others/headstone.tscn").instance()
	headstone.name = "headstone" + name
	headstone.global_position = global_position
	Game.get_main().add_child(headstone)
	if state != Game.DIZZY:
		leave_soul()
	Game.get_sacrifice().sacrifice(self)
	queue_free()

func leave_soul():
	var soul = load("res://scenes/soul.tscn").instance()
	soul.human = is_in_group("human")
	soul.bodyName = name
	soul.color = color
	soul.global_position = global_position
	Game.get_main().add_child(soul)
	pass
