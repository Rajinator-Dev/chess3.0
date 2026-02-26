# /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$ 
#| $$__  $$ /$$__  $$ /$$__  $$| $$__  $$| $$__  $$
#| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$
#| $$$$$$$ | $$  | $$| $$$$$$$$| $$$$$$$/| $$  | $$
#| $$__  $$| $$  | $$| $$__  $$| $$__  $$| $$  | $$
#| $$  \ $$| $$  | $$| $$  | $$| $$  \ $$| $$  | $$
#| $$$$$$$/|  $$$$$$/| $$  | $$| $$  | $$| $$$$$$$/
#|_______/  \______/ |__/  |__/|__/  |__/|_______/ 

extends Node3D

signal promotionSelection(pieceType: int)

@onready var boardSquare: PackedScene = preload("res://scenes/board_square.tscn")
@onready var boardWhite: StandardMaterial3D = preload("res://materials/board_white.tres")
@onready var boardColor: StandardMaterial3D = preload("res://materials/board_color.tres")
@onready var pieceWhite: StandardMaterial3D = preload("res://materials/piece_white.tres")
@onready var pieceBlack: StandardMaterial3D = preload("res://materials/piece_black.tres")
@onready var selectionIndicator: StandardMaterial3D = preload("res://materials/selection_indicator.tres")

@onready var squareHolder: Node3D = %Squares
@onready var pieceHolder: Node3D = %Pieces

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var timer: Timer = %Timer

@export_group("Camera")
@export var camera: Camera3D  
@export var cineCamera: Camera3D
@export var cineCameraHolder: Node3D

@export_group("Menus")
@export var bars: Control
@export var pauseMenu: Control
@export var gameOverMenu: Control

@export_group("Promotion")
@export var promotionContainer: Control
@export var blackImages: GridContainer
@export var whiteImages: GridContainer
@export var knightButton: Button
@export var bishopButton: Button
@export var rookButton: Button
@export var queenButton: Button

enum chessPieces {PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING}

const SCENES: Dictionary = {
	chessPieces.PAWN: preload("res://assets/Pawn.glb"),
	chessPieces.KNIGHT: preload("res://assets/Knight.glb"),
	chessPieces.BISHOP: preload("res://assets/Bishop.glb"),
	chessPieces.ROOK: preload("res://assets/Rook.glb"),
	chessPieces.QUEEN: preload("res://assets/Queen.glb"),
	chessPieces.KING: preload("res://assets/King.glb")
}

const WHITE_EXPLOSION: Dictionary = {
	chessPieces.PAWN: preload("res://assets/white_explosion/Pawn_Explosion_White.glb"),
	chessPieces.KNIGHT: preload("res://assets/white_explosion/Knight_Explosion_White.glb"),
	chessPieces.BISHOP: preload("res://assets/white_explosion/Bishop_Explosion_White.glb"),
	chessPieces.ROOK: preload("res://assets/white_explosion/Rook_Explosion_White.glb"),
	chessPieces.QUEEN: preload("res://assets/white_explosion/Queen_Explosion_White.glb")
}

const BLACK_EXPLOSION: Dictionary = {
	chessPieces.PAWN: preload("res://assets/black_explosion/Pawn_Explosion_Black.glb"),
	chessPieces.KNIGHT: preload("res://assets/black_explosion/Knight_Explosion_Black.glb"),
	chessPieces.BISHOP: preload("res://assets/black_explosion/Bishop_Explosion_Black.glb"),
	chessPieces.ROOK: preload("res://assets/black_explosion/Rook_Explosion_Black.glb"),
	chessPieces.QUEEN: preload("res://assets/black_explosion/Queen_Explosion_Black.glb")
}

const MIN_SCREEN_SHAKE : float = 0.05
const MAX_SCREEN_SHAKE : float = 0.5

var selection: Vector2i = Vector2i(-1, -1)
var validMoves: Array
var initialBoard: Array = []
var isBusy: bool = false
var screenShakeTween : Tween
var isKillCamEnabled: bool = true
var isBoardRotationEnabled: bool = true

var pendingPromotionPos: Vector2i
var pendingSelectionPos: Vector2i

func _ready() -> void:
	GM.reset_game()
	initialBoard = GM.board
	generate_board()
	reset_positions()

	knightButton.pressed.connect(func() -> void: promotionSelection.emit(2))
	bishopButton.pressed.connect(func() -> void: promotionSelection.emit(3))
	rookButton.pressed.connect(func() -> void: promotionSelection.emit(4))
	queenButton.pressed.connect(func() -> void: promotionSelection.emit(5))
	promotionSelection.connect(_on_promotion_selected)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		pauseMenu.visible = true
# /$$$$$$ /$$   /$$ /$$$$$$ /$$$$$$$$ /$$$$$$  /$$$$$$  /$$       /$$$$$$ /$$$$$$$$ /$$$$$$$$       /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$ 
#|_  $$_/| $$$ | $$|_  $$_/|__  $$__/|_  $$_/ /$$__  $$| $$      |_  $$_/|_____ $$ | $$_____/      | $$__  $$ /$$__  $$ /$$__  $$| $$__  $$| $$__  $$
#  | $$  | $$$$| $$  | $$     | $$     | $$  | $$  \ $$| $$        | $$       /$$/ | $$            | $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$
#  | $$  | $$ $$ $$  | $$     | $$     | $$  | $$$$$$$$| $$        | $$      /$$/  | $$$$$         | $$$$$$$ | $$  | $$| $$$$$$$$| $$$$$$$/| $$  | $$
#  | $$  | $$  $$$$  | $$     | $$     | $$  | $$__  $$| $$        | $$     /$$/   | $$__/         | $$__  $$| $$  | $$| $$__  $$| $$__  $$| $$  | $$
#  | $$  | $$\  $$$  | $$     | $$     | $$  | $$  | $$| $$        | $$    /$$/    | $$            | $$  \ $$| $$  | $$| $$  | $$| $$  \ $$| $$  | $$
# /$$$$$$| $$ \  $$ /$$$$$$   | $$    /$$$$$$| $$  | $$| $$$$$$$$ /$$$$$$ /$$$$$$$$| $$$$$$$$      | $$$$$$$/|  $$$$$$/| $$  | $$| $$  | $$| $$$$$$$/
#|______/|__/  \__/|______/   |__/   |______/|__/  |__/|________/|______/|________/|________/      |_______/  \______/ |__/  |__/|__/  |__/|_______/ 

func generate_board() -> void:
	for rank: int in range(8):
		for file: int in range(8):
			var square: StaticBody3D = boardSquare.instantiate()
			square.position = Vector3(file, 0, rank)
			square.name = str(Vector2i(file, rank))
			squareHolder.add_child(square)

			connect_square_signal(square)

	reset_board_colors()

func reset_board_colors() -> void:
	for rank: int in range(8):
		for file: int in range(8):
			var scene: StaticBody3D = squareHolder.get_node(str(Vector2i(file, rank)))
			var obj: Node3D
			for child: Node3D in scene.get_children():
				if child is Node3D:
					obj = child
			var mesh: MeshInstance3D = obj.get_child(0)
			
			if (rank + file) % 2 == 0:
				mesh.set_surface_override_material(0, boardWhite)
				mesh.set_surface_override_material(1, boardWhite)
				mesh.set_surface_override_material(2, boardWhite)
			else:
				mesh.set_surface_override_material(0, boardColor)
				mesh.set_surface_override_material(1, boardColor)
				mesh.set_surface_override_material(2, boardColor)

func reset_positions() -> void:
	for rank: int in range(8):
		for file: int in range(8):
			var piece: int = initialBoard[file][rank]

			if piece != 0:
				var instance: Node3D = SCENES[abs(piece) - 1].instantiate()
				instance.position = Vector3(rank, 0.0, file)
				if sign(piece) == 1:
					instance.rotation.y = deg_to_rad(180)
				instance.scale = Vector3(1.5, 1.5, 1.5)
				instance.set_meta("piece", piece)
				instance.set_meta("position", Vector2i(rank, file))

				var mesh: MeshInstance3D = instance.get_child(0)
				mesh.set_surface_override_material(0, pieceWhite if sign(piece) == 1 else pieceBlack)

				pieceHolder.add_child(instance)

# /$$      /$$  /$$$$$$  /$$    /$$ /$$$$$$$$ /$$      /$$ /$$$$$$$$ /$$   /$$ /$$$$$$$$
#| $$$    /$$$ /$$__  $$| $$   | $$| $$_____/| $$$    /$$$| $$_____/| $$$ | $$|__  $$__/
#| $$$$  /$$$$| $$  \ $$| $$   | $$| $$      | $$$$  /$$$$| $$      | $$$$| $$   | $$   
#| $$ $$/$$ $$| $$  | $$|  $$ / $$/| $$$$$   | $$ $$/$$ $$| $$$$$   | $$ $$ $$   | $$   
#| $$  $$$| $$| $$  | $$ \  $$ $$/ | $$__/   | $$  $$$| $$| $$__/   | $$  $$$$   | $$   
#| $$\  $ | $$| $$  | $$  \  $$$/  | $$      | $$\  $ | $$| $$      | $$\  $$$   | $$   
#| $$ \/  | $$|  $$$$$$/   \  $/   | $$$$$$$$| $$ \/  | $$| $$$$$$$$| $$ \  $$   | $$   
#|__/     |__/ \______/     \_/    |________/|__/     |__/|________/|__/  \__/   |__/   

func handle_movement(coordinates: Vector2i) -> void:
	var moves: Array = GM.get_moves(coordinates)

	visualize_moves(moves, coordinates)
	make_move(moves, coordinates)
	var endState: String = GM.check_end_game()
	if endState != "":
		gameOverMenu.visible = true

func visualize_moves(moves: Array, coordinates: Vector2i) -> void:
	reset_board_colors()

	var pieceScene: StaticBody3D = squareHolder.get_node(str(coordinates))
	var pieceObj: Node3D = pieceScene.get_child(1)
	var pieceMesh: MeshInstance3D = pieceObj.get_child(0)
	pieceMesh.set_surface_override_material(1, selectionIndicator)
	
	for move: Vector2i in moves:
		var targetScene: StaticBody3D = squareHolder.get_node(str(move))
		var targetObj: Node3D = targetScene.get_child(1)
		var targetMesh: MeshInstance3D = targetObj.get_child(0)
		targetMesh.set_surface_override_material(1, selectionIndicator)

		for piece: Node3D in pieceHolder.get_children():
			var pos: Vector2i = piece.get_meta("position")

			if pos == move:
				targetMesh.set_surface_override_material(2, selectionIndicator)
func make_move(moves: Array, coordinates: Vector2i) -> void:
	if moves:
		selection = coordinates
		validMoves = moves
	elif selection != Vector2i(-1, -1):
		var isValidMove: bool = GM.move_piece(selection, coordinates, validMoves)
		
		if isValidMove:

			if abs(GM.board[coordinates.y][coordinates.x]) == 1 and (coordinates.y == 0 or coordinates.y == 7):
				pendingPromotionPos = coordinates
				pendingSelectionPos = selection
				get_tree().paused = true
				if GM.board[coordinates.y][coordinates.x] == 1:
					whiteImages.show()
					blackImages.hide()
				else:
					blackImages.show()
					whiteImages.hide()
				promotionContainer.show()
				return
			isBusy = true
			update_visual_move(selection, coordinates)
			GM.change_turn()

		selection = Vector2i(-1, -1)
		validMoves = []

func update_visual_move(oldPos: Vector2i, newPos: Vector2i) -> void:
	var movingPiece: Node3D = null
	var capturedPiece: Node3D = null

	for piece: Node3D in pieceHolder.get_children():
		var pos: Vector2i = piece.get_meta("position")

		if pos == oldPos:
			movingPiece = piece
		elif pos == newPos:
			capturedPiece = piece

	if movingPiece:
		var pieceValue: int = movingPiece.get_meta("piece")
		move_piece_smooth(movingPiece, newPos)

		if abs(pieceValue) == 1 and oldPos.x != newPos.x and capturedPiece == null:
			var direction: int = 1 if pieceValue > 0 else -1
			var pawnPos: Vector2i = Vector2i(newPos.x, newPos.y + direction)

			for piece: Node3D in pieceHolder.get_children():
				if piece.get_meta("position") == pawnPos:
					cineCameraHolder.position = Vector3(newPos.x - 3.5, 0.0, newPos.y - 3.5)	
					await play_capture_animation(piece)
					break

		if abs(pieceValue) == 6 and abs(newPos.x - oldPos.x) == 2:
			var rookOldPos: Vector2i
			var rookNewPos: Vector2i

			if newPos.x == 6:
				rookOldPos = Vector2i(7, oldPos.y)
				rookNewPos = Vector2i(5, oldPos.y)
			else:
				rookOldPos = Vector2i(0, oldPos.y)
				rookNewPos = Vector2i(3, oldPos.y)

			move_rook_visual(rookOldPos, rookNewPos)
		if capturedPiece == null:
			isBusy = false
	
	if capturedPiece:
		cineCameraHolder.position = Vector3(newPos.x - 3.5, 0.0, newPos.y - 3.5)	
		await play_capture_animation(capturedPiece)
	
	timer.start()

func play_capture_animation(piece: Node3D) -> void:
	var pieceValue: int = piece.get_meta("piece")
	
	if isKillCamEnabled:
		bars.visible = true
		camera.current = false
		cineCamera.current = true

		if sign(pieceValue) == -1:
			animationPlayer.play("BlackCineCamera")
		elif sign(pieceValue) == 1:
			animationPlayer.play("WhiteCineCamera")

	
	var fracturedScene: Node3D
	if sign(pieceValue) == -1:
		fracturedScene = BLACK_EXPLOSION[abs(pieceValue) - 1].instantiate()
	elif sign(pieceValue) == 1:
		fracturedScene = WHITE_EXPLOSION[abs(pieceValue) - 1].instantiate()

	if isKillCamEnabled:
		Engine.time_scale = 0.15
		await get_tree().create_timer(0.15).timeout
		Engine.time_scale = 1.0

	fracturedScene.position = piece.position
	pieceHolder.add_child(fracturedScene)

	piece.queue_free()

	var anim: AnimationPlayer = fracturedScene.get_node("AnimationPlayer")

	if isKillCamEnabled:
		add_screen_shake(0.1, 0.8)

	anim.play("Animation")
	await anim.animation_finished

	fracturedScene.queue_free()

	isBusy = false
	
	if isKillCamEnabled:
		bars.visible = false
		camera.current = true
		cineCamera.current = false

func replace_pawn_visual(pos: Vector2i, pieceType: int) -> void:
	var pawnNode: Node3D = null

	for piece: Node3D in pieceHolder.get_children():
		if piece.get_meta("position") == pos:
			pawnNode = piece
			break
	
	if pawnNode == null:
		return

	var oldValue: int = pawnNode.get_meta("piece")

	pawnNode.queue_free()

	var newScene: Node3D = SCENES[pieceType - 1].instantiate()
	var mesh: MeshInstance3D = newScene.get_child(0)
	mesh.set_surface_override_material(0, pieceWhite if oldValue > 0 else pieceBlack)

	newScene.position = Vector3(pos.x, 0.0, pos.y)
	newScene.scale = Vector3(1.5, 1.5, 1.5)
	newScene.set_meta("position", pos)
	newScene.set_meta("piece", pieceType if oldValue > 0 else -pieceType)

	pieceHolder.add_child(newScene)
	
# /$$   /$$ /$$$$$$$$ /$$       /$$$$$$$  /$$$$$$$$ /$$$$$$$        /$$$$$$$$ /$$   /$$ /$$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$  /$$   /$$  /$$$$$$ 
#| $$  | $$| $$_____/| $$      | $$__  $$| $$_____/| $$__  $$      | $$_____/| $$  | $$| $$$ | $$ /$$__  $$|__  $$__/|_  $$_/ /$$__  $$| $$$ | $$ /$$__  $$
#| $$  | $$| $$      | $$      | $$  \ $$| $$      | $$  \ $$      | $$      | $$  | $$| $$$$| $$| $$  \__/   | $$     | $$  | $$  \ $$| $$$$| $$| $$  \__/
#| $$$$$$$$| $$$$$   | $$      | $$$$$$$/| $$$$$   | $$$$$$$/      | $$$$$   | $$  | $$| $$ $$ $$| $$         | $$     | $$  | $$  | $$| $$ $$ $$|  $$$$$$ 
#| $$__  $$| $$__/   | $$      | $$____/ | $$__/   | $$__  $$      | $$__/   | $$  | $$| $$  $$$$| $$         | $$     | $$  | $$  | $$| $$  $$$$ \____  $$
#| $$  | $$| $$      | $$      | $$      | $$      | $$  \ $$      | $$      | $$  | $$| $$\  $$$| $$    $$   | $$     | $$  | $$  | $$| $$\  $$$ /$$  \ $$
#| $$  | $$| $$$$$$$$| $$$$$$$$| $$      | $$$$$$$$| $$  | $$      | $$      |  $$$$$$/| $$ \  $$|  $$$$$$/   | $$    /$$$$$$|  $$$$$$/| $$ \  $$|  $$$$$$/
#|__/  |__/|________/|________/|__/      |________/|__/  |__/      |__/       \______/ |__/  \__/ \______/    |__/   |______/ \______/ |__/  \__/ \______/ 
																																						  
func move_rook_visual(oldPos: Vector2i, newPos: Vector2i) -> void:
	for piece: Node3D in pieceHolder.get_children():
		if piece.get_meta("position") == oldPos:
			var tween: Tween = move_piece_smooth(piece, newPos)
			await tween.finished
			return

func string_to_vector2i(string: String) -> Vector2i:
	if string:
		var newString: String = string
		newString = newString.erase(0, 1)
		newString = newString.erase(newString.length() - 1, 1)
		var array: Array = newString.split(", ")

		return Vector2i(int(array[0]), int(array[1]))

	return Vector2i.ZERO

func move_piece_smooth(piece: Node3D, newPos: Vector2i) -> Tween:
	var target: Vector3 = Vector3(newPos.x, 0.0, newPos.y)
	var tween: Tween = create_tween()
	#tween.tween_property(piece, "position", target, 0.25)
	tween.tween_method(
	func(t: float)-> void:
			var arcHeight: float = 0.4
			var mid: Vector3 = piece.position.lerp(target, t)
			mid.y += sin(t * PI) * arcHeight
			piece.position = mid,
		0.0, 1.0, 0.3
	)
	tween.tween_callback(func()-> void:
		piece.set_meta("position", newPos)
	)
	return tween

func add_screen_shake(amount: float, seconds: float) -> void:
	if screenShakeTween:
		screenShakeTween.kill()

	screenShakeTween = create_tween()
	screenShakeTween.tween_method(update_screen_shake.bind(amount), 0.0, 1.0, seconds).set_ease(Tween.EASE_OUT)

func update_screen_shake(alpha: float, amount: float) -> void:
	amount = remap(amount, 0.0, 1.0, MIN_SCREEN_SHAKE, MAX_SCREEN_SHAKE)
	var currentShakeAmount: float = amount * (1.0 - alpha)

	cineCamera.h_offset = randf_range(-currentShakeAmount, currentShakeAmount)
	cineCamera.h_offset = randf_range(-currentShakeAmount, currentShakeAmount)


#  /$$$$$$  /$$$$$$  /$$$$$$  /$$   /$$  /$$$$$$  /$$        /$$$$$$ 
# /$$__  $$|_  $$_/ /$$__  $$| $$$ | $$ /$$__  $$| $$       /$$__  $$
#| $$  \__/  | $$  | $$  \__/| $$$$| $$| $$  \ $$| $$      | $$  \__/
#|  $$$$$$   | $$  | $$ /$$$$| $$ $$ $$| $$$$$$$$| $$      |  $$$$$$ 
# \____  $$  | $$  | $$|_  $$| $$  $$$$| $$__  $$| $$       \____  $$
# /$$  \ $$  | $$  | $$  \ $$| $$\  $$$| $$  | $$| $$       /$$  \ $$
#|  $$$$$$/ /$$$$$$|  $$$$$$/| $$ \  $$| $$  | $$| $$$$$$$$|  $$$$$$/
# \______/ |______/ \______/ |__/  \__/|__/  |__/|________/ \______/ 

func connect_square_signal(square: StaticBody3D) -> void:
	square.input_event.connect(
		func(_camera: Node, _event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
			if isBusy:
				return

			if (_event is InputEventMouseButton and 
				_event.pressed and 
				_event.button_index == MOUSE_BUTTON_LEFT):
				var coordinates: Vector2i = string_to_vector2i(square.name)
				handle_movement(coordinates)
			)

func _on_timer_timeout() -> void:
	if isBoardRotationEnabled:
		if GM.turn == -1:
			animationPlayer.play("camera")
		else:
			animationPlayer.play_backwards("camera")

func _on_promotion_selected(pieceType: int) -> void:
	isBusy = true
	
	GM.promotion(pendingPromotionPos, pieceType)
	
	promotionContainer.hide()
	get_tree().paused = false

	await update_visual_move(pendingSelectionPos, pendingPromotionPos)
	replace_pawn_visual(pendingPromotionPos, pieceType)

	GM.change_turn()

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
	GM.reset_game()

func _on_resume_button_pressed() -> void:
	pauseMenu.visible = false

func _on_kill_cam_button_toggled(toggled_on: bool) -> void:
	isKillCamEnabled = toggled_on

func _on_board_rotation_button_toggled(toggled_on: bool) -> void:
	isBoardRotationEnabled = toggled_on
