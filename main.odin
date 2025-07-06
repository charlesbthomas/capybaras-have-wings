package game

import "core:fmt"
import "core:strconv"
import rl "vendor:raylib"

Vector :: [2]f32

Player :: struct {
	pos:          Vector,
	acceleration: Vector,
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
GRAVITY: f32 : 400
PLAYER_SPEED: f32 : 350

init :: proc() -> GameState {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Capybara Olympics")
	rl.SetTargetFPS(60)

	game: GameState

	initial_player_pos := Vector{100, 0}

	game.spawn_counter = 10
	game.player = Player {
		acceleration = Vector{50, 0},
		pos          = initial_player_pos,
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
	}
	game.player.pos += game.player.acceleration * dt
	game.camera.target = game.player.pos
	game.spawn_counter -= 1
	if game.spawn_counter == 0 {
		fmt.println("Spawning snake at position:", game.player.pos.x + 100)
		game.spawn_counter = SCREEN_WIDTH / 2
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
}

render :: proc(game: ^GameState) {
	rl.BeginDrawing();defer rl.EndDrawing()
	rl.ClearBackground(rl.BLUE)

	rl.DrawText(fmt.ctprint("Score: ", game.score), 10, 10, 20, rl.WHITE)
	rl.BeginMode2D(game.camera);defer rl.EndMode2D()

	rl.DrawRectangle(
		i32(game.player.pos.x),
		i32(game.player.pos.y),
		50,
		50,
		rl.BROWN,
	)
	rl.DrawRectangle(
		i32(game.player.pos.x - (SCREEN_WIDTH / 2)),
		50,
		SCREEN_WIDTH,
		5000,
		rl.GREEN,
	)

	for snake in game.snakes {
		rl.DrawRectangle(
			i32(snake.pos),
			0 - (50 * (snake.height - 1)),
			50,
			50 * snake.height,
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
