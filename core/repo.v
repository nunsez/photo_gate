module core

import db.sqlite

pub fn random_pending(mut pool sqlite.ConnectionPool) !Picture {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	rows := conn.execute('SELECT id FROM pictures WHERE status = 0 ORDER BY RANDOM() LIMIT 1')!
	pending_id := if row := rows[0] { row.vals[0] } else { return error('not found') }

	pictures := sql conn {
    select from Picture where id == pending_id
  }!

	return pictures[0]
}

pub fn accept(mut pool sqlite.ConnectionPool, path string) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql conn {
		update Picture set status = .accepted where path == path
	}!
}

pub fn decline(mut pool sqlite.ConnectionPool, path string) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql conn {
		update Picture set status = .declined where path == path
	}!
}
