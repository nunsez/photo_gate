module core

import db.sqlite
import os

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

pub fn set_status(mut pool sqlite.ConnectionPool, id i64, status PictureStatus) ! {
	conn := pool.acquire()!
	defer { pool.release(conn) }

	sql conn {
		update Picture set status = status, updated_at = time.utc() where id == id
	}!
}

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
	page     u32
	per_page u32 = 30
	limit    u32
	q        string
}

fn (c &PageConfig) offset() u32 {
	return (c.page - 1) * c.per_page
}

struct FetchResult[T] {
pub:
	items []T
	count u64
}

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
				limit params.per_page
				offset offset
			}!
		} else {
			sql conn {
				select from Picture
				where status == status
				order by updated_at desc
				limit params.per_page
				offset offset
			}!
		}
	}

	return FetchResult{ items: items, count: count }
}
