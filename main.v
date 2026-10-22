module main

import os
import core
import walk
import config

const default_config_path = 'config.json'

fn main() {
	cfg_path := os.args[1] or { default_config_path }
	cfg := config.parse(cfg_path)!

	mut pool := core.new_pool(cfg.database, cfg.pool_size)!
	mut conn := pool.acquire()!
	core.run_migrations(mut conn)!

	for walk_cfg in cfg.walk {
		walk.run(walk_cfg, mut conn)
	}

	defer { pool.release(conn) }
}
