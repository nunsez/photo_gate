module main

import os
import core
import config
import web

const default_config_path = 'config.json'
const default_database_path = 'db.sqlite3'

fn main() {
	// sendfile SIGPIPE kills the process on aborted downloads
	os.signal_ignore(.pipe)

	cfg_path := os.args[1] or { default_config_path }
	cfg := config.parse(cfg_path)!

	database_path := if cfg.database == '' { default_database_path } else { cfg.database }
	mut pool := core.new_pool(database_path, cfg.pool_size)!

	mut conn := pool.acquire()!
	core.run_migrations(mut conn)!
	pool.release(conn)

	web.run(cfg.port, cfg_path, pool)!
}
