package game

import "core:fmt"
import "core:strconv"
import rl "vendor:raylib"

Vector :: [2]f32

AnimatedTexture :: struct {
	texture:      rl.Texture2D,
	frame_length: f32,
	frame_timer:  f32,
	curr_frame:   int,
}

Player :: struct {
	pos:          Vector,
	acceleration: Vector,
	texture:      AnimatedTexture,
	jumps:        i32,
}

Snake :: struct {
	pos:     f32,
	texture: AnimatedTexture,
}

GameState :: struct {
	game_over:     bool,
	player:        Player,
	background:    rl.Texture2D,
	bgScroll:      f32,
	score:         i32,
	camera:        rl.Camera2D,
	spawn_counter: i32,
	snakes:        [dynamic]Snake,
}


SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
GRAVITY: f32 : 500
PLAYER_SPEED: f32 : 250


init :: proc() -> GameState {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Capybaras Have Wings")
	rl.SetTargetFPS(60)

	game: GameState

	initial_player_pos := Vector{100, 0}

	game.spawn_counter = 10
	capy_text := AnimatedTexture {
		texture      = rl.LoadTexture("assets/capy-run.png"),
		frame_length = 0.25,
		frame_timer  = 0,
		curr_frame   = 0,
	}
	game.player = Player {
		acceleration = Vector{150, 0},
		pos          = initial_player_pos,
		texture      = capy_text,
		jumps        = 0,
	}

	game.camera.zoom = 1.0
	game.camera.target = game.player.pos
	game.camera.offset = rl.Vector2 {
		SCREEN_WIDTH / 2,
		(SCREEN_HEIGHT / 2) + 100,
	}

	game.background = rl.LoadTexture("assets/sky.png")
	game.bgScroll = 0.0

	return game
}

handle_animated_texture :: proc(
	texture: ^AnimatedTexture,
	max_frame: int,
	dt: f32,
) {
	texture.frame_timer += dt
	if texture.frame_timer >= texture.frame_length {
		texture.curr_frame += 1
		texture.frame_timer = 0
		if texture.curr_frame >= max_frame {
			texture.curr_frame = 0
		}
	}
}

update :: proc(game: ^GameState, dt: f32) {
	kp := rl.GetKeyPressed()
	#partial switch kp {
	case .SPACE:
		if game.player.jumps < 2 {
			game.player.acceleration.y = -PLAYER_SPEED
			game.player.jumps += 1
		}
	}
	if (game.player.pos.y >= 0) && (game.player.acceleration.y >= 0) {
		game.player.jumps = 0
	}
	game.player.acceleration.y += GRAVITY * dt
	if game.player.pos.y >= 0 && game.player.acceleration.y >= 0 {
		game.player.acceleration.y = 0
		game.player.pos.y = 0
	}
	game.player.pos += game.player.acceleration * dt
	game.camera.target = game.player.pos
	game.camera.offset.y = 532
	game.spawn_counter -= i32(game.player.acceleration.x * dt)

	if game.spawn_counter <= 0 {
		fmt.println("Spawning snake")
		game.spawn_counter = SCREEN_WIDTH / 3
		append(
			&game.snakes,
			Snake {
				pos = game.player.pos.x + SCREEN_WIDTH / 2,
				texture = AnimatedTexture {
					texture = rl.LoadTexture("assets/snake.png"),
					frame_length = 0.25,
					frame_timer = 0,
					curr_frame = 0,
				},
			},
		)

	}
	for &s, idx in game.snakes {
		handle_animated_texture(&s.texture, 2, dt)
		if s.pos < game.player.pos.x - (SCREEN_WIDTH / 2) {
			game.score += 1
			ordered_remove(&game.snakes, idx)
		}

		if (game.player.pos.x + 20 >= s.pos) &&
		   (game.player.pos.x <= s.pos + 20) &&
		   (game.player.pos.y >= -40) {
			game.game_over = true
		}
	}

	handle_animated_texture(&game.player.texture, 2, dt)
	if game.player.pos.y < 0 {
		game.player.texture.curr_frame = 2
	}

	game.bgScroll -= 75 * dt
	if game.bgScroll <= -f32(game.background.width) {
		game.bgScroll = 0
	}


}

render :: proc(game: ^GameState) {
	rl.BeginDrawing();defer rl.EndDrawing()
	rl.ClearBackground(rl.BLUE)

	for i in 0 ..< 3 {
		rl.DrawTextureEx(
			game.background,
			Vector {
				game.bgScroll + f32(game.background.width * i32(i)),
				-game.player.pos.y - 200,
			},
			0,
			1,
			rl.WHITE,
		)
	}

	rl.BeginMode2D(game.camera)

	src := rl.Rectangle {
		x      = f32(game.player.texture.curr_frame * 16),
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
	rl.DrawTexturePro(game.player.texture.texture, src, dest, 0, 0, rl.WHITE)

	for snake in game.snakes {
		src := rl.Rectangle {
			x      = f32(snake.texture.curr_frame * 16),
			y      = 0,
			width  = 16,
			height = 16,
		}
		dest := rl.Rectangle {
			x      = snake.pos,
			y      = 0,
			width  = 48,
			height = 48,
		}
		rl.DrawTexturePro(snake.texture.texture, src, dest, 0, 0, rl.WHITE)
	}
	rl.EndMode2D()

	rl.DrawText(fmt.ctprint("Score: ", game.score), 10, 10, 20, rl.WHITE)

}

main :: proc() {
	game := init()
	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		if game.game_over {
			rl.ClearBackground(rl.BLACK)
			rl.BeginDrawing();defer rl.EndDrawing()
			rl.DrawText("Game Over! Press R to restart", 200, 300, 20, rl.RED)
			if rl.IsKeyPressed(.R) {
				game = init()
			}
			continue
		}
		update(&game, dt)
		render(&game)
	}
}
