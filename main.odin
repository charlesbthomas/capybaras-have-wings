package game

import "core:fmt"
import "core:strconv"
import rl "vendor:raylib"

Vector :: [2]f32

Player :: struct {
	pos:          Vector,
	acceleration: Vector,
	texture:      rl.Texture2D,
	frame_timer:  f32,
	curr_frame:   int,
	frame_length: f32,
}

Snake :: struct {
	pos:    f32,
	height: i32, // height of the snake, 1 or 2
}

GameState :: struct {
	player:        Player,
	score:         i32,
	camera:        rl.Camera2D,
	spawn_counter: i32,
	snakes:        [dynamic]Snake,
}


SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
GRAVITY: f32 : 450
PLAYER_SPEED: f32 : 370

init :: proc() -> GameState {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Capybaras Have Wings")
	rl.SetTargetFPS(60)

	game: GameState

	initial_player_pos := Vector{100, 0}

	game.spawn_counter = 10
	game.player = Player {
		acceleration = Vector{150, 0},
		pos          = initial_player_pos,
		texture      = rl.LoadTexture("capy-run.png"),
		frame_length = 0.25,
	}

	game.camera.zoom = 1.0
	game.camera.target = game.player.pos
	game.camera.offset = rl.Vector2{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}

	return game
}

update :: proc(game: ^GameState, dt: f32) {
	kp := rl.GetKeyPressed()
	#partial switch kp {
	case .SPACE:
		game.player.acceleration.y -= PLAYER_SPEED
	}
	game.player.acceleration.y += GRAVITY * dt
	if game.player.pos.y >= 0 && game.player.acceleration.y >= 0 {
		game.player.acceleration.y = 0
		game.player.pos.y = 0
	}
	game.player.pos += game.player.acceleration * dt
	game.camera.target = game.player.pos
	game.spawn_counter -= i32(game.player.acceleration.x * dt)
	if game.spawn_counter == 0 {
		game.spawn_counter = SCREEN_WIDTH / 3
		// randomize the height of the snake between 1 and 2
		height := 1 + rl.GetRandomValue(0, 1)
		append(
			&game.snakes,
			Snake{pos = game.player.pos.x + SCREEN_WIDTH / 2, height = height},
		)
	}
	for s, idx in game.snakes {
		if s.pos < game.player.pos.x - (SCREEN_WIDTH / 2) {
			game.score += 1
			ordered_remove(&game.snakes, idx)
		}
	}

	game.player.frame_timer += dt
	if game.player.frame_timer >= game.player.frame_length {
		game.player.curr_frame += 1
		game.player.frame_timer = 0
		if game.player.curr_frame >= 2 {
			game.player.curr_frame = 0
		}
		if game.player.pos.y < 0 {
			game.player.curr_frame = 2
		}
	}
}

render :: proc(game: ^GameState) {
	rl.BeginDrawing();defer rl.EndDrawing()
	rl.ClearBackground(rl.BLUE)

	rl.DrawText(fmt.ctprint("Score: ", game.score), 10, 10, 20, rl.WHITE)
	rl.BeginMode2D(game.camera);defer rl.EndMode2D()

	src := rl.Rectangle {
		x      = f32(game.player.curr_frame * 16),
		y      = 0,
		width  = 16,
		height = 16,
	}
	dest := rl.Rectangle {
		x      = game.player.pos.x,
		y      = game.player.pos.y,
		width  = 48,
		height = 48,
	}
	rl.DrawTexturePro(game.player.texture, src, dest, 0, 0, rl.WHITE)

	// Draw ground
	rl.DrawRectangle(
		i32(game.player.pos.x - (SCREEN_WIDTH / 2)),
		48,
		SCREEN_WIDTH,
		5000,
		rl.GREEN,
	)

	for snake in game.snakes {
		rl.DrawRectangle(
			i32(snake.pos),
			0 - (48 * (snake.height - 1)),
			48,
			48 * snake.height,
			rl.RED,
		)
	}

}

main :: proc() {
	game := init()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		update(&game, dt)
		render(&game)
	}
}
