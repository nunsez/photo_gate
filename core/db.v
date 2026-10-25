module core

import db.sqlite

const bootstrap_db_cmds = [
	'PRAGMA page_size = 8192',
	'PRAGMA auto_vacuum = INCREMENTAL',
	'PRAGMA journal_mode = WAL',
]

const setup_conn_cmds = [
	'PRAGMA foreign_keys = ON',
	'PRAGMA synchronous = NORMAL',
	'PRAGMA busy_timeout = 5000',
	'PRAGMA cache_size = -20000',
	'PRAGMA temp_store = MEMORY',
	'PRAGMA mmap_size = 2147483648',
]

fn bootstrap(db_path string) ! {
	mut conn := sqlite.connect(db_path)!
	defer { conn.close() or {} }
	for cmd in bootstrap_db_cmds { conn.exec(cmd)! }
}

// TODO: add callback after pool creation?
pub fn new_pool(db_path string, pool_size i32) !sqlite.ConnectionPool {
	bootstrap(db_path)!

	mut pool := sqlite.new_connection_pool(db_path, pool_size)!

	for _ in 0 .. pool_size {
		mut conn := pool.acquire()!
		for cmd in setup_conn_cmds { conn.exec(cmd)! }
		pool.release(conn)
	}

	return pool
}
