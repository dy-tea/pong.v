module main

import gg
import gx
import os

const window_width = 800
const window_height = 600
const window_title = 'Pong'
const paddle_width = 20
const paddle_length = 100
const paddle_spd = 10
const x_0 = paddle_width
const x_1 = window_width - 2 * paddle_width
const ball_size = 20
const scores_file_name = 'scores.txt'

enum GameState {
	menu
	play
	game_over
	scores
	exit
}

enum Direction {
	up   = -1
	down = 1
}

struct Position {
	x int
	y int
}

struct MenuItem {
	name  string
	state GameState
}

struct Menu {
mut:
	items    []MenuItem
	selected int
}

struct Rect {
mut:
	x int
	y int
	w int
	h int
}

struct App {
mut:
	gg          &gg.Context = unsafe { nil }
	frame       int
	state       GameState = .menu
	score       int
	last_score  int
	paddle      []int // player = 0, cpu = 1
	ball_pos    Position
	ball_lr     Direction
	ball_ud     Direction
	ball_spd    f64
	menu_main   Menu
	menu_reset  Menu
	menu_scores Menu
	file_scores os.File
	scores      []int
	high_score  int
}

fn collide_rects(r1 Rect, r2 Rect) bool {
	if r1.x + r1.w >= r2.x && r1.x <= r2.x + r2.w && r1.y + r1.h >= r2.y && r1.y <= r2.y + r2.h {
		return true
	}
	return false
}

// Set starting game values
fn (mut app App) new_game() {
	app.score = 0
	app.frame = 0
	app.ball_lr = .up
	app.ball_ud = .up
	app.ball_spd = 2
	app.paddle = [window_height / 2 - paddle_length / 2, window_height / 2 - paddle_length / 2]
	app.ball_pos = Position{window_width / 2 - ball_size / 2, window_height / 2 - ball_size / 2}
}

fn (mut app App) move(d Direction, p int) {
	if d == .up {
		if app.paddle[p] >= 0 {
			app.paddle[p] -= paddle_spd
		}
		if app.paddle[p] < 0 {
			app.paddle[p] = 0
		}
	}
	if d == .down {
		if app.paddle[p] + paddle_length <= window_height {
			app.paddle[p] += paddle_spd
		}
		if app.paddle[p] + paddle_length > window_height {
			app.paddle[p] = window_height - paddle_length
		}
	}
}

fn (mut menu Menu) navigate(d Direction) {
	l := menu.items.len
	s := menu.selected

	if d == .up {
		if s == 0 {
			menu.selected = l - 1
		} else {
			menu.selected -= 1
		}
	}
	if d == .down {
		if s == l - 1 {
			menu.selected = 0
		} else {
			menu.selected += 1
		}
	}
}

// ugly code
fn (mut app App) navigate(d Direction) {
	match app.state {
		.menu {
			app.menu_main.navigate(d)
		}
		.game_over {
			app.menu_reset.navigate(d)
		}
		.scores {
			app.menu_scores.navigate(d)
		}
		else {}
	}
}

fn (mut app App) select_item() {
	app.state = match app.state {
		.menu {
			app.menu_main.items[app.menu_main.selected].state
		}
		.game_over {
			app.menu_reset.items[app.menu_reset.selected].state
		}
		.scores {
			app.menu_scores.items[app.menu_scores.selected].state
		}
		else {
			app.state
		}
	}
}

fn (app &App) draw() {
	text_cfg := gx.TextCfg{
		color: gx.white
		align: .center
		size:  48
	}

	match app.state {
		.menu {
			// Main menu
			app.gg.draw_text(window_width / 2, 100, 'Pong', text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2, app.menu_main.items[0].name,
				text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2 + 48, app.menu_main.items[1].name,
				text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2 + 96, app.menu_main.items[2].name,
				text_cfg)
			// Selection box
			app.gg.draw_rect_empty(window_width / 2 - 64, window_height / 2 +
				app.menu_main.selected * 48, 128, 48, gx.white)
		}
		.play {
			// Paddles
			app.gg.draw_rect_filled(x_0, app.paddle[0], paddle_width, paddle_length, gx.white)
			app.gg.draw_rect_filled(x_1, app.paddle[1], paddle_width, paddle_length, gx.white)
			// Ball
			app.gg.draw_rect_filled(app.ball_pos.x, app.ball_pos.y, ball_size, ball_size,
				gx.white)
			// Score
			app.gg.draw_text(window_width / 2, 10, app.score.str(), text_cfg)
		}
		.game_over {
			// Game Over menu
			app.gg.draw_text(window_width / 2, 10, 'Game Over', text_cfg)
			app.gg.draw_text(window_width / 2, window_width / 4, 'Score: ${app.last_score}',
				text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2, app.menu_reset.items[0].name,
				text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2 + 48, app.menu_reset.items[1].name,
				text_cfg)
			// Selection box
			app.gg.draw_rect_empty(window_width / 2 - 64, window_height / 2 +
				app.menu_reset.selected * 48, 128, 48, gx.white)
		}
		.scores {
			// Score menu
			app.gg.draw_text(window_width / 2, 10, 'High Score: ${app.high_score}', text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2, app.menu_scores.items[0].name,
				text_cfg)
			app.gg.draw_text(window_width / 2, window_height / 2 + 48, app.menu_scores.items[1].name,
				text_cfg)
			// Selection box
			app.gg.draw_rect_empty(window_width / 2 - 64, window_height / 2 +
				app.menu_scores.selected * 48, 128, 48, gx.white)
		}
		else {}
	}
}

fn (mut app App) on_key_down(key gg.KeyCode) {
	match key {
		.w, .up {
			if app.state == .play {
				app.move(.up, 0)
			} else {
				app.navigate(.up)
			}
		}
		.s, .down {
			if app.state == .play {
				app.move(.down, 0)
			} else {
				app.navigate(.down)
			}
		}
		.enter {
			app.select_item()
		}
		else {}
	}
}

fn (mut app App) update() {
	// Update ball speed over time
	if app.gg.frame % 600 == 0 {
		app.ball_spd *= 1.05
	}

	// Update Game
	match app.state {
		.play {
			// Move cpu (very dumb)
			if app.gg.frame % 5 == 0 {
				if app.ball_pos.y + ball_size / 2 > app.paddle[1] + paddle_length / 2 {
					app.move(.down, 1)
				} else {
					app.move(.up, 1)
				}
			}

			// Move Ball
			app.ball_pos = Position{int(app.ball_pos.x + -1 * int(app.ball_lr) * app.ball_spd), int(
				app.ball_pos.y + -1 * int(app.ball_ud) * app.ball_spd)}

			// Collide ball and wall / celing
			if app.ball_pos.y < 0 {
				app.ball_ud = .up
			}
			if app.ball_pos.y + ball_size > window_height {
				app.ball_ud = .down
			}

			// Collide ball and paddles
			r_paddle_0 := Rect{x_0, app.paddle[0], paddle_width, paddle_length}
			r_paddle_1 := Rect{x_1, app.paddle[1], paddle_width, paddle_length}
			r_ball := Rect{app.ball_pos.x, app.ball_pos.y, ball_size, ball_size}

			lr_tmp := app.ball_lr

			if collide_rects(r_paddle_0, r_ball) {
				app.ball_lr = .up
			}
			if collide_rects(r_paddle_1, r_ball) {
				app.ball_lr = .down
			}

			// Increment score
			if lr_tmp != app.ball_lr && lr_tmp == .down {
				app.score += 1
			}

			// Collide ball and right wall
			if app.ball_pos.x + ball_size > window_width {
				app.ball_lr = .down
			}

			// Game Over check
			if app.ball_pos.x < 0 {
				app.state = .game_over
				app.last_score = app.score

				// Append score
				app.scores << app.last_score

				app.new_game()
			}
		}
		.scores {
			// Update High score
			for n in app.scores {
				if n > app.high_score {
					app.high_score = n
				}
			}
		}
		.exit {
			// Write scores to file
			for n in app.scores {
				app.file_scores.writeln(n.str()) or { panic(err) }
			}
			app.file_scores.close()

			// Exit
			app.gg.quit()
		}
		else {}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			app.on_key_down(e.key_code)
		}
		else {}
	}
}

fn frame(mut app App) {
	app.gg.begin()
	app.update()
	app.draw()
	app.gg.end()
}

fn init(mut app App) {
	// Init score file
	if os.exists(scores_file_name) {
		// Read in high score
		lines := os.read_lines(scores_file_name) or { panic(err) }
		for l in lines {
			if l.int() > app.high_score {
				app.high_score = l.int()
			}
		}
		// Prepare file for appending
		app.file_scores = os.open_append(scores_file_name) or { panic(err) }
	} else {
		// Create file for writing
		app.file_scores = os.create(scores_file_name) or { panic(err) }
	}

	// Init menus
	app.menu_main.items << [MenuItem{'Play', .play}, MenuItem{'Score', .scores},
		MenuItem{'Exit', .exit}]
	app.menu_reset.items << [MenuItem{'Retry', .play}, MenuItem{'Exit', .exit}]
	app.menu_scores.items << [MenuItem{'Menu', .menu}, MenuItem{'Exit', .exit}]

	// Init game
	app.new_game()
}

fn main() {
	mut app := &App{}
	app.gg = gg.new_context(
		width:        window_width
		height:       window_height
		window_title: window_title
		bg_color:     gx.black
		frame_fn:     frame
		user_data:    app
		init_fn:      init
		event_fn:     on_event
	)
	app.gg.run()
}
