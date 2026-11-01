module core

import time
import db.sqlite

pub enum PictureStatus {
	pending
	accepted
	declined
}

@[table: 'pictures']
pub struct Picture {
pub mut:
	id          i64    @[primary; serial]
	path        string @[required]
	status      PictureStatus = .pending
	modified_at time.Time @[required]
	last_seen   time.Time @[required]
	updated_at  time.Time = time.utc()
	created_at  time.Time = time.utc()
}

pub fn Picture.from_row(row sqlite.Row) !Picture {
	status := row.get_int('status')

	return Picture{
		id:          row.get_string('id').i64()
		path:        row.get_string('path')
		status:      PictureStatus.from(status) or { return error('invalid status: ${status}') }
		modified_at: time.unix(row.get_int('modified_at'))
		last_seen:   time.unix(row.get_int('last_seen'))
		updated_at:  time.unix(row.get_int('updated_at'))
		created_at:  time.unix(row.get_int('created_at'))
	}
}

pub fn Picture.dom_id(id i64, prefix ?string) string {
	if prefix == none {
		return 'picture-${id}'
	}
	return '${prefix}-${id}'
}

pub fn (p &Picture) dom_id() string {
	return Picture.dom_id(p.id)
}
