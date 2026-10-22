module web

import veb
import db.sqlite
import core
import os
import net.urllib
import strconv

pub struct Context {
	veb.Context
}

pub fn (ctx &Context) build_page_url(page u64) string {
	mut params := ctx.query.clone()
	params['page'] = page.str()

	mut parts := []string{cap: params.len}
	for k, v in params {
		parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
	}
	parts.sort()

	path := ctx.req.url.all_before('?')
	q := parts.join('&')
	return if q == '' { path } else { '${path}?${q}' }
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
	picture := core.random_pending(mut app.pool) or {
		html := app.render_layout(content: '<p style="text-align: center;">No More Pending!</p>')
		return ctx.html(html)
	}

	html := app.render_layout(content: $tmpl('templates/pending.html'))
	return ctx.html(html)
}

const per_page = 30

@['/declined']
pub fn (app &App) declined(mut ctx Context) !veb.Result {
	page := strconv.atou32(ctx.query['page'] or { '1' })!
	result := core.by_status(mut app.pool, .declined, limit: per_page, page: page)!
	pagination := core.new_pagination(
		current_page: page
		total_items:  result.count
		per_page:     per_page
	)
	html := app.render_layout(content: $tmpl('templates/declined.html'))
	return ctx.html(html)
}

@['/accepted']
pub fn (app &App) accepted(mut ctx Context) !veb.Result {
	page := strconv.atou32(ctx.query['page'] or { '1' })!
	result := core.by_status(mut app.pool, .accepted, limit: per_page, page: page)!
	pagination := core.new_pagination(
		current_page: page
		total_items:  result.count
		per_page:     per_page
	)
	html := app.render_layout(content: $tmpl('templates/accepted.html'))
	return ctx.html(html)
}

@['/accept'; post]
pub fn (app &App) accept(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.set_status(mut app.pool, url.path, .accepted)!
	return ctx.ok('')
}

@['/decline'; post]
pub fn (app &App) decline(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.set_status(mut app.pool, url.path, .declined)!
	return ctx.ok('')
}

@['/pending'; post]
pub fn (app &App) pending(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.set_status(mut app.pool, url.path, .pending)!
	return ctx.ok('')
}

@['/remove'; post]
pub fn (app &App) remove(mut ctx Context) !veb.Result {
	url := urllib.parse(ctx.form['src'])!
	core.remove_from_disk(mut app.pool, url.path)!
	return ctx.ok('')
}

@['/:path...']
pub fn (app &App) fallback(mut ctx Context, path string) veb.Result {
	if os.is_file(path) { return ctx.file(path) }
	return ctx.not_found()
}
