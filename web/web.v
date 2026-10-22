module web

import veb
import db.sqlite
import core
import os
import net.urllib

pub struct Context {
	veb.Context
}

pub struct App {
	pool sqlite.ConnectionPool
}

pub fn run(port u16, pool sqlite.ConnectionPool) ! {
	mut app := App{ pool: pool }
	veb.run[App, Context](mut app, port)
}

@[params]
struct LayoutParams {
	layout  string = 'main'
	title   string = 'Picture Gate'
	content string
}

fn (app &App) render_layout(params LayoutParams) string {
	return $tmpl('templates/layouts/main.html')
}

@['/']
pub fn (app &App) index(mut ctx Context) !veb.Result {
	pending_picture := core.random_pending(mut app.pool) or {
		html := app.render_layout(content: '<p style="text-align: center;">No More Pending!</p>')
		return ctx.html(html)
	}

	html := app.render_layout(content: $tmpl('templates/pending.html'))
	return ctx.html(html)
}

@['/accept'; post]
pub fn (app &App) accept(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.accept(mut app.pool, url.path)!
	return ctx.redirect('/', typ: .see_other)
}

@['/decline'; post]
pub fn (app &App) decline(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.decline(mut app.pool, url.path)!
	return ctx.redirect('/', typ: .see_other)
}

@['/:path...']
pub fn (app &App) fallback(mut ctx Context, path string) veb.Result {
	if os.is_file(path) { return ctx.file(path) }
	return ctx.not_found()
}
