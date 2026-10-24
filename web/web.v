module web

import veb
import db.sqlite
import core
import os
import net.urllib
import strconv
import walk
import datastar

pub struct Context {
	veb.Context
}

fn (mut ctx Context) datastar_remove(selector string) veb.Result {
	return ctx.send_response_to_client(datastar.sse, datastar.remove_event(selector))
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
	veb.StaticHandler
	pool     sqlite.ConnectionPool
	cfg_path string
}

pub fn run(port u16, cfg_path string, pool sqlite.ConnectionPool) ! {
	mut app := App{ pool: pool, cfg_path: cfg_path }

	app.enable_static_compression = true
	app.mount_static_folder_at('static', '/public')!

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
	q := (ctx.query['q'] or { '' }).trim_space()
	result := core.by_status(mut app.pool, .declined, limit: per_page, page: page, q: q)!
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
	q := (ctx.query['q'] or { '' }).trim_space()
	result := core.by_status(mut app.pool, .accepted, limit: per_page, page: page, q: q)!
	pagination := core.new_pagination(
		current_page: page
		total_items:  result.count
		per_page:     per_page
	)
	html := app.render_layout(content: $tmpl('templates/accepted.html'))
	return ctx.html(html)
}

enum PageKind {
	pending
	accepted
	declined
}

fn PageKind.from_ctx(ctx Context) !PageKind {
	return PageKind.from(ctx.form['pageKind'])!
}

@['/accept/:id'; patch]
pub fn (app &App) accept(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .accepted) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.pending { return ctx.redirect('/', typ: .see_other) }
		.declined {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('bad kind') }
	}
}

@['/decline/:id'; patch]
pub fn (app &App) decline(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .declined) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.pending { return ctx.redirect('/', typ: .see_other) }
		.accepted {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('') }
	}
}

@['/pending/:id'; patch]
pub fn (app &App) pending(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .pending) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.accepted, .declined {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('') }
	}
}

@['/scan'; post]
pub fn (app &App) scan(mut ctx Context) !veb.Result {
	spawn handle_scan(app.cfg_path, mut &app.pool)
	return ctx.redirect('/')
}

fn handle_scan(cfg_path string, mut pool sqlite.ConnectionPool) {
	mut conn := pool.acquire() or { return }
	defer { pool.release(conn) }
	walk.run_with_new_config(cfg_path, mut conn) or { return }
}

@['/:path...']
pub fn (app &App) fallback(mut ctx Context, path string) veb.Result {
	if os.is_file(path) { return ctx.file(path) }
	return ctx.not_found()
}
