module main

import os
import core
import config
import web
import db.sqlite
import time

const default_config_path = 'config.json'
const default_database_path = 'db.sqlite3'

fn main() {
	cfg_path := os.args[1] or { default_config_path }
	cfg := config.parse(cfg_path)!

	database_path := if cfg.database == '' { default_database_path } else { cfg.database }
	mut pool := core.new_pool(database_path, cfg.pool_size)!

	mut conn := pool.acquire()!
	core.run_migrations(mut conn)!
	pool.release(conn)

	if cfg.report_interval > 0 {
		spawn report_picture_statuses(&pool, cfg.report_interval)
	}

	web.run(cfg.port, cfg_path, pool)!
}

fn report_picture_statuses(pool &sqlite.ConnectionPool, interval u32) {
	for {
		time.sleep(interval * time.second)
		result := core.picture_statuses(pool) or { continue }
		println('
 PENDING: ${result[.pending]}
ACCEPTED: ${result[.accepted]}
DECLINED: ${result[.declined]}')
	}
}
