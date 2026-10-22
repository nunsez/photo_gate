module walk

import os
import db.sqlite
import time
import config
import core { Picture }

struct Context {
	exclude []string
	db      sqlite.DB
}

pub fn run(cfg config.WalkConfig, mut db sqlite.DB) {
	ctx := Context{ db: db, exclude: cfg.exclude }
	os.walk_with_context(cfg.root, &ctx, callback)
}

fn callback(ctx &Context, path string) {
	if !os.is_file(path) { return }

	for exclude in ctx.exclude {
		if path.starts_with(exclude) { return }
	}

	stat := os.stat(path) or { return }

	pic := Picture{
		path:        path
		status:      .pending
		modified_at: time.unix(stat.mtime)
		last_seen:   time.utc()
	}

	sql ctx.db {
    insert pic into Picture
  } or {
		eprintln('walk error: ${err}')
		return
	}

	println('walk done: ${path}')
}
