extends Node

var board: Array
var debugBoard: Array

#PIECE REPRESENTATION INDEX
#1: PAWN
#2: KNIGHT
#3: BISHOP
#4: ROOK
#5: QUEEN
#6: KING
#POSITIVE == WHITE && NEGATIVE == BLACK

var turn: int = 1 #1 == WHITE && -1 == BLACK

var whiteKingMoved: bool = false
var whiteQRookMoved: bool = false
var whiteKRookMoved: bool = false

var blackKingMoved: bool = false
var blackQRookMoved: bool = false
var blackKRookMoved: bool = false

var enPassantTarget: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	initialize_board()
	reset_board()
	print_board()

func reset_game() -> void:
	board = []
	debugBoard = []
	turn = 1
	whiteKingMoved = false
	whiteQRookMoved = false
	whiteKRookMoved = false

	blackKingMoved = false
	blackQRookMoved = false
	blackKRookMoved = false

	enPassantTarget = Vector2i(-1, -1)

	initialize_board()
	reset_board()
	print_board()


func initialize_board() -> void:
	for rank: int in range(8):
		board.append([])
		for file: int in range(8):
			board[rank].append(0)

func reset_board() -> void:
	var back_rank: Array = [4, 2, 3, 5, 6, 3, 2, 4]

	for file: int in range(8):
		#Initialize Black Pieces
		board[0][file] = -back_rank[file]
		board[1][file] = -1

		#Initialize White Pieces
		board[6][file] = 1
		board[7][file] = back_rank[file]


# /$$      /$$  /$$$$$$  /$$    /$$ /$$$$$$$$  /$$$$$$ 
#| $$$    /$$$ /$$__  $$| $$   | $$| $$_____/ /$$__  $$
#| $$$$  /$$$$| $$  \ $$| $$   | $$| $$      | $$  \__/
#| $$ $$/$$ $$| $$  | $$|  $$ / $$/| $$$$$   |  $$$$$$ 
#| $$  $$$| $$| $$  | $$ \  $$ $$/ | $$__/    \____  $$
#| $$\  $ | $$| $$  | $$  \  $$$/  | $$       /$$  \ $$
#| $$ \/  | $$|  $$$$$$/   \  $/   | $$$$$$$$|  $$$$$$/
#|__/     |__/ \______/     \_/    |________/ \______/ 


func move_piece(pos: Vector2i, target: Vector2i, moves: Array) -> bool:
	var piece: int = board[pos.y][pos.x]
	for move: Vector2i in moves:
		if target == move:
			var oldEnPassant: Vector2i = enPassantTarget
			enPassantTarget = Vector2i(-1, -1)

			if abs(piece) == 1 and target == oldEnPassant:
				var capturePawnPos: Vector2i = Vector2i(target.x, pos.y)
				board[capturePawnPos.y][capturePawnPos.x] = 0
			
			board[pos.y][pos.x] = 0
			board[target.y][target.x] = piece


			#if abs(piece) == 1:

			#	var promoteTo: int = choose_promotion_piece()
			#	promotion(target, promoteTo)

			if abs(piece) == 4 or abs(piece) == 6:
				update_castle_flags(piece, pos)

			if abs(piece) == 6 and abs(target.x - pos.x) == 2:
				if target.x == 6:
					board[target.y][5] = board[target.y][7]
					board[target.y][7] = 0
				elif target.x == 2:
					board[target.y][3] = board[target.y][0]
					board[target.y][0] = 0

			if abs(piece) == 1 and abs(target.y - pos.y) == 2:
				enPassantTarget = Vector2i(target.x, (pos.y + target.y) / 2)

			return true
	return false

func change_turn() -> void:
	turn = -turn
	print_board()

func check_end_game() -> String:
	var endState: String = ""
	if not has_any_legal_moves(turn):
		if is_in_check(turn):
			print("Checkmate")
			endState = "Checkmate"
			return endState
		else:
			print("Stalemate")
			endState = "Stalemate"
			return endState

	return endState

func update_castle_flags(piece: int, pos: Vector2i) -> void:
	if piece == 6:
		whiteKingMoved = true
	elif piece == -6:
		blackKingMoved = true

	if piece == 4:
		if pos == Vector2i(0, 7):
			whiteQRookMoved = true
		elif pos == Vector2i(7, 7):
			whiteKRookMoved = true

	if piece == -4:
		if pos == Vector2i(0, 0):
			blackQRookMoved = true
		elif pos == Vector2i(7, 0):
			blackKRookMoved = true

func promotion(target: Vector2i, promoteTo: int) -> void:
	var piece: int = board[target.y][target.x]
	if (piece == 1 and target.y == 0) or (piece == -1 and target.y == 7):
		board[target.y][target.x] = promoteTo * sign(piece)

func get_moves(pos: Vector2i) -> Array:
	var psuedoMoves: Array = []
	var piece: int = board[pos.y][pos.x]

	if sign(piece) != sign(turn):
		return []

	if piece == 0:
		return []

	match abs(piece):
		1:	psuedoMoves = get_pawn_moves(pos)
		2:	psuedoMoves = get_knight_moves(pos)
		3:	psuedoMoves = sliding_moves(pos)
		4:	psuedoMoves = sliding_moves(pos)
		5:	psuedoMoves = sliding_moves(pos)
		6:	psuedoMoves = get_king_moves(pos)

	return filter_legal_moves(pos, psuedoMoves)

# /$$       /$$$$$$$$  /$$$$$$   /$$$$$$  /$$             /$$      /$$  /$$$$$$  /$$    /$$ /$$$$$$$$  /$$$$$$ 
#| $$      | $$_____/ /$$__  $$ /$$__  $$| $$            | $$$    /$$$ /$$__  $$| $$   | $$| $$_____/ /$$__  $$
#| $$      | $$      | $$  \__/| $$  \ $$| $$            | $$$$  /$$$$| $$  \ $$| $$   | $$| $$      | $$  \__/
#| $$      | $$$$$   | $$ /$$$$| $$$$$$$$| $$            | $$ $$/$$ $$| $$  | $$|  $$ / $$/| $$$$$   |  $$$$$$ 
#| $$      | $$__/   | $$|_  $$| $$__  $$| $$            | $$  $$$| $$| $$  | $$ \  $$ $$/ | $$__/    \____  $$
#| $$      | $$      | $$  \ $$| $$  | $$| $$            | $$\  $ | $$| $$  | $$  \  $$$/  | $$       /$$  \ $$
#| $$$$$$$$| $$$$$$$$|  $$$$$$/| $$  | $$| $$$$$$$$      | $$ \/  | $$|  $$$$$$/   \  $/   | $$$$$$$$|  $$$$$$/
#|________/|________/ \______/ |__/  |__/|________/      |__/     |__/ \______/     \_/    |________/ \______/ 

func has_any_legal_moves(color: int) -> bool:
	for rank: int in range(8):
		for file: int in range(8):
			var piece: int = board[rank][file]
			if sign(piece) == color:
				var moves: Array = get_moves(Vector2i(file, rank))
				if moves.size() > 0:
					return true

	return false

func filter_legal_moves(pos: Vector2i, psuedoMoves: Array) -> Array:
	var legal: Array = []

	for move: Vector2i in psuedoMoves:
		var captured: int = board[move.y][move.x]
		var piece: int = board[pos.y][pos.x]
		var isCastle: bool = abs(piece) == 6 and abs(move.x - pos.x) == 2
		var color: int = sign(piece)

		#board[move.y][move.x] = piece
		#board[pos.y][pos.x] = 0
		var rookFrom: Vector2i
		var rookTo: Vector2i
		var rookPiece: int

		board[move.y][move.x] = piece
		board[pos.y][pos.x] = 0

		if isCastle:
			if move.x == 6:
				rookFrom = Vector2i(7, move.y)
				rookTo = Vector2i(5, move.y)
			elif move.x == 2:
				rookFrom = Vector2i(0, move.y)
				rookTo = Vector2i(3, move.y)

			rookPiece = board[rookFrom.y][rookFrom.x]
			board[rookTo.y][rookTo.x] = rookPiece
			board[rookFrom.y][rookFrom.x] = 0

		var isEnPassant: bool = abs(piece) == 1 and move == enPassantTarget
		var capturedPawnsPos: Vector2i
		var capturedPawnPiece: int

		if isEnPassant:
			capturedPawnsPos = Vector2i(move.x, pos.y)
			capturedPawnPiece = board[capturedPawnsPos.y][capturedPawnsPos.x]
			board[capturedPawnsPos.y][capturedPawnsPos.x] = 0

		if not is_in_check(color):
			legal.append(move)
		
		if isEnPassant:
			board[capturedPawnsPos.y][capturedPawnsPos.x] = capturedPawnPiece

		board[pos.y][pos.x] = piece
		board[move.y][move.x] = captured

		if isCastle:
			board[rookFrom.y][rookFrom.x] = rookPiece
			board[rookTo.y][rookTo.x] = 0

	return legal

func is_in_check(color: int) -> bool:
	var kingSpace: Vector2i = find_king(color)
	return is_square_attacked(kingSpace, -color)

func is_square_attacked(move: Vector2i, piece: int) -> bool:
	var knightOffsets: Array = [
		Vector2i(-2, 1),
		Vector2i(-2, -1),
		Vector2i(2, 1),
		Vector2i(2, -1),
		Vector2i(1, 2),
		Vector2i(1, -2),
		Vector2i(-1, 2),
		Vector2i(-1, -2)
	]
	var bishopQueenOffsets: Array = [
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	var rookQueenOffsets: Array = [
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
	]
	var kingOffsets: Array = [
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	#var pawnDir: int = sign(piece)
	var pawnOffsets: Array = [
		Vector2i(-sign(piece), sign(piece)),
		Vector2i(sign(piece), sign(piece))
	]


	for offset: Vector2i in knightOffsets:
		var pos: Vector2i = move + offset
		if is_inside(pos) and board[pos.y][pos.x] == 2 * piece:
			return true

	for offset: Vector2i in bishopQueenOffsets:
		var pos: Vector2i = move + offset
		while is_inside(pos):
			if not is_target_empty(pos):
				if board[pos.y][pos.x] == 3 * piece or board[pos.y][pos.x] == 5 * piece:
					return true
				else:
					break

			pos = pos + offset
	
	for offset: Vector2i in rookQueenOffsets:
		var pos: Vector2i = move + offset
		while is_inside(pos):
			if not is_target_empty(pos):
				if board[pos.y][pos.x] == 4 * piece or board[pos.y][pos.x] == 5 * piece:
					return true
				else:
					break

			pos = pos + offset

	for offset: Vector2i in kingOffsets:
		var pos: Vector2i = move + offset
		if is_inside(pos) and board[pos.y][pos.x] == 6 * piece:
			return true

	for offsets: Vector2i in pawnOffsets:
		var pos: Vector2i = move + offsets
		if is_inside(pos) and board[pos.y][pos.x] == 1 * piece:
			return true

	return false

# /$$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$ /$$$$$$$   /$$$$$$          /$$       /$$$$$$$$  /$$$$$$   /$$$$$$  /$$      
#| $$__  $$ /$$__  $$| $$  | $$| $$_____/| $$__  $$ /$$__  $$        | $$      | $$_____/ /$$__  $$ /$$__  $$| $$      
#| $$  \ $$| $$  \__/| $$  | $$| $$      | $$  \ $$| $$  \ $$        | $$      | $$      | $$  \__/| $$  \ $$| $$      
#| $$$$$$$/|  $$$$$$ | $$  | $$| $$$$$   | $$  | $$| $$  | $$ /$$$$$$| $$      | $$$$$   | $$ /$$$$| $$$$$$$$| $$      
#| $$____/  \____  $$| $$  | $$| $$__/   | $$  | $$| $$  | $$|______/| $$      | $$__/   | $$|_  $$| $$__  $$| $$      
#| $$       /$$  \ $$| $$  | $$| $$      | $$  | $$| $$  | $$        | $$      | $$      | $$  \ $$| $$  | $$| $$      
#| $$      |  $$$$$$/|  $$$$$$/| $$$$$$$$| $$$$$$$/|  $$$$$$/        | $$$$$$$$| $$$$$$$$|  $$$$$$/| $$  | $$| $$$$$$$$
#|__/       \______/  \______/ |________/|_______/  \______/         |________/|________/ \______/ |__/  |__/|________/

func get_pawn_moves(pos: Vector2i) -> Array:
	var moves: Array = []
	var piece: int = board[pos.y][pos.x]
	var direction: Vector2i = Vector2i(0, -sign(piece))

	var target: Vector2i = pos + direction
	if is_inside(target) and is_target_empty(target):
		moves.append(target)
	
		if pos.y == 6 or pos.y == 1:
			var doubleTarget: Vector2i = target + direction
			if is_inside(doubleTarget) and is_target_empty(doubleTarget):
				moves.append(doubleTarget)

	var attack_direction: Array = [
		Vector2i(-sign(piece), -sign(piece)),
		Vector2i(sign(piece), -sign(piece))
	]
	for dir: Vector2i in attack_direction:
		var attack_target: Vector2i = dir + pos
		if is_inside(attack_target) and not is_target_empty(attack_target) and is_enemy(attack_target, piece):
			moves.append(attack_target)

	for dir: Vector2i in attack_direction:
		var epTarget: Vector2i = pos + dir
		if epTarget == enPassantTarget:
			moves.append(epTarget)
			
	
	return moves

func get_knight_moves(pos: Vector2i) -> Array:
	var moves: Array = []
	var piece: int = board[pos.y][pos.x]
	var offsets : Array = [
		Vector2i(-2, 1),
		Vector2i(-2, -1),
		Vector2i(2, 1),
		Vector2i(2, -1),
		Vector2i(1, 2),
		Vector2i(1, -2),
		Vector2i(-1, 2),
		Vector2i(-1, -2)
	]

	for offset: Vector2i in offsets:
		var target: Vector2i = pos + offset

		if is_inside(target) and (is_target_empty(target) or is_enemy(target, piece)):
			moves.append(target)

	return moves

func get_king_moves(pos: Vector2i) -> Array:
	var moves: Array = []
	var piece: int = board[pos.y][pos.x]
	var color: int = sign(piece)
	var offsets : Array = [
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]

	for offset: Vector2i in offsets:
		var target: Vector2i = pos + offset

		if is_inside(target) and (is_target_empty(target) or is_enemy(target, piece)):
			moves.append(target)

	if color == 1 and not whiteKingMoved and not whiteKRookMoved and board[7][7] == 4:
		if is_target_empty(Vector2i(5, 7)) and is_target_empty(Vector2i(6, 7)):
			if not is_in_check(color) \
			and not is_square_attacked(Vector2i(5, 7), -color) \
			and not is_square_attacked(Vector2i(6, 7), -color):
				moves.append(Vector2i(6, 7))

	if color == 1 and not whiteKingMoved and not whiteQRookMoved and board[7][0] == 4:
		if is_target_empty(Vector2i(1, 7)) and is_target_empty(Vector2i(2, 7)) and is_target_empty(Vector2i(3, 7)):
			if not is_in_check(color) \
			and not is_square_attacked(Vector2i(3, 7), -color) \
			and not is_square_attacked(Vector2i(2, 7), -color):
				moves.append(Vector2i(2, 7))

	if color == -1 and not blackKingMoved and not blackKRookMoved and board[0][7] == -4:
		if is_target_empty(Vector2i(5, 0)) and is_target_empty(Vector2i(6, 0)):
			if not is_in_check(color) \
			and not is_square_attacked(Vector2i(5, 0), -color) \
			and not is_square_attacked(Vector2i(6, 0), -color):
				moves.append(Vector2i(6, 0))

	if color == -1 and not blackKingMoved and not blackQRookMoved and board[0][0] == -4:
		if is_target_empty(Vector2i(1, 0)) and is_target_empty(Vector2i(2, 0)) and is_target_empty(Vector2i(3, 0)):
			if not is_in_check(color) \
			and not is_square_attacked(Vector2i(3, 0), -color) \
			and not is_square_attacked(Vector2i(2, 0), -color):
				moves.append(Vector2i(2, 0))

	return moves

func sliding_moves(pos: Vector2i) -> Array:
	var piece: int = board[pos.y][pos.x]
	var bishopMoves: Array = [
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	var rookMoves: Array = [
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
	]
	var queenMoves: Array = [
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]

	if abs(piece) == 3:
		return get_sliding_moves(pos, bishopMoves)
	elif abs(piece) == 4:
		return get_sliding_moves(pos, rookMoves)
	elif abs(piece) == 5:
		return get_sliding_moves(pos, queenMoves)

	return []

func get_sliding_moves(pos: Vector2i, direction: Array) -> Array:
	var moves: Array = []
	var piece: int = board[pos.y][pos.x]
	for dir: Vector2i in direction:
		var target: Vector2i = pos + dir
		while is_inside(target):
			if is_target_empty(target) or is_enemy(target, piece):
				moves.append(target)

			if not is_target_empty(target):
				break

			target = target + dir

	return moves

# /$$   /$$ /$$$$$$$$ /$$       /$$$$$$$  /$$$$$$$$ /$$$$$$$        /$$$$$$$$ /$$   /$$ /$$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$  /$$   /$$  /$$$$$$ 
#| $$  | $$| $$_____/| $$      | $$__  $$| $$_____/| $$__  $$      | $$_____/| $$  | $$| $$$ | $$ /$$__  $$|__  $$__/|_  $$_/ /$$__  $$| $$$ | $$ /$$__  $$
#| $$  | $$| $$      | $$      | $$  \ $$| $$      | $$  \ $$      | $$      | $$  | $$| $$$$| $$| $$  \__/   | $$     | $$  | $$  \ $$| $$$$| $$| $$  \__/
#| $$$$$$$$| $$$$$   | $$      | $$$$$$$/| $$$$$   | $$$$$$$/      | $$$$$   | $$  | $$| $$ $$ $$| $$         | $$     | $$  | $$  | $$| $$ $$ $$|  $$$$$$ 
#| $$__  $$| $$__/   | $$      | $$____/ | $$__/   | $$__  $$      | $$__/   | $$  | $$| $$  $$$$| $$         | $$     | $$  | $$  | $$| $$  $$$$ \____  $$
#| $$  | $$| $$      | $$      | $$      | $$      | $$  \ $$      | $$      | $$  | $$| $$\  $$$| $$    $$   | $$     | $$  | $$  | $$| $$\  $$$ /$$  \ $$
#| $$  | $$| $$$$$$$$| $$$$$$$$| $$      | $$$$$$$$| $$  | $$      | $$      |  $$$$$$/| $$ \  $$|  $$$$$$/   | $$    /$$$$$$|  $$$$$$/| $$ \  $$|  $$$$$$/
#|__/  |__/|________/|________/|__/      |________/|__/  |__/      |__/       \______/ |__/  \__/ \______/    |__/   |______/ \______/ |__/  \__/ \______/ 
																																						  
func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func is_target_empty(target: Vector2i) -> bool:
	return board[target.y][target.x] == 0

func is_enemy(target: Vector2i, piece: int) -> bool:
	return sign(piece) != sign(board[target.y][target.x])

func find_king(color: int) -> Vector2i:
	for rank: int in range(8):
		for file: int in range(8):
			if board[rank][file] == 6 * color:
				return Vector2i(file, rank)

	return Vector2i.ZERO
func print_board() -> void:
	debugBoard = board.duplicate_deep()

	for rank: int in range(len(debugBoard)):
		for file: int in range(len(debugBoard[rank])):
			match debugBoard[rank][file]:
				0:	debugBoard[rank][file] = "."
				1:	debugBoard[rank][file] = "P"
				2:	debugBoard[rank][file] = "N"
				3:	debugBoard[rank][file] = "B"
				4:	debugBoard[rank][file] = "R"
				5:	debugBoard[rank][file] = "Q"
				6:	debugBoard[rank][file] = "K"
				-1:	debugBoard[rank][file] = "p"
				-2:	debugBoard[rank][file] = "n"
				-3: debugBoard[rank][file] = "b"
				-4:	debugBoard[rank][file] = "r"
				-5:	debugBoard[rank][file] = "q"
				-6:	debugBoard[rank][file] = "k"
					
		print(" ".join(debugBoard[rank]))
	print("\n")
