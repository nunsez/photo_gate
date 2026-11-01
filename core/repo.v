module core

import db.sqlite
import os
import time

// TODO: ON CONFLICT (path) DO NOTHING
pub fn insert_or_ignore(mut db sqlite.DB, picture Picture) ! {
	sql db {
    upsert picture into Picture
  }!
}

// TODO: use conn instead of pool ?
pub fn delete(mut pool sqlite.ConnectionPool, id i64) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql conn {
		delete from Picture where id == id
	}!
}

pub struct Option[T] {
pub:
	value ?T
}

// TODO: use conn instead of pool ?
pub fn find(mut pool sqlite.ConnectionPool, id i64) !Option[Picture] {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	rows := sql conn {
		select from Picture where id == id
	}!

	return Option{rows[0]}
}

// TODO: use conn instead of pool ?
pub fn random_pending(mut pool sqlite.ConnectionPool) !Picture {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql := 'SELECT * FROM pictures WHERE status = ${int(PictureStatus.pending)} ORDER BY RANDOM() LIMIT 1'

	row := conn.exec(sql)![0] or { return error('not found') }

	return Picture.from_row(row)
}

// TODO: use conn instead of pool ?
pub fn set_status(mut pool sqlite.ConnectionPool, id i64, status PictureStatus) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql conn {
		update Picture set status = status, updated_at = time.utc() where id == id
	}!
}

// TODO: use conn instead of pool ?
pub fn remove_from_disk(mut pool sqlite.ConnectionPool, path string) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	os.rm(path)!

	sql conn {
		delete from Picture where path == path
	}!
}

@[params]
struct PageConfig {
pub:
	page  u32 @[required]
	limit u32 = 30
	q     string
}

fn (c &PageConfig) offset() u32 {
	if c.page < 1 { return 0 }
	return (c.page - 1) * c.limit
}

struct FetchResult[T] {
pub:
	items []T
	count u64
}

// TODO: use conn instead of pool ?
// FIXME: complicated, double queries
pub fn by_status(mut pool sqlite.ConnectionPool, status PictureStatus, params PageConfig) !FetchResult[Picture] {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	has_query := params.q != ''
	pattern := '%${params.q}%'

	count := if has_query {
		sql conn {
			select count from Picture where status == status && path like pattern
		}!
	} else {
		sql conn {
			select count from Picture where status == status
		}!
	}

	mut items := []Picture{}

	// TODO: bug with `offset params.offset()`
	if count > 0 {
		offset := params.offset()

		items = if has_query {
			sql conn {
				select from Picture
				where status == status && path like pattern
				order by updated_at desc
				limit params.limit
				offset offset
			}!
		} else {
			sql conn {
				select from Picture
				where status == status
				order by updated_at desc
				limit params.limit
				offset offset
			}!
		}
	}

	return FetchResult{ items: items, count: count }
}

pub fn picture_statuses(pool &sqlite.ConnectionPool) !map[PictureStatus]string {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	rows := conn.exec('SELECT status, count(id) FROM pictures GROUP BY status ORDER BY status')!
	mut result := map[PictureStatus]string{}

	for row in rows {
		status_str := row.vals[0] or { continue }
		count := row.vals[1] or { continue }
		status := PictureStatus.from(status_str.int()) or { continue }
		result[status] = count
	}

	return result
}
