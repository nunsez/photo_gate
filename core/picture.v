module core

import time

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

pub fn Picture.dom_id(id i64, prefix ?string) string {
	if prefix == none {
		return 'picture-${id}'
	}
	return '${prefix}-${id}'
}

pub fn (p &Picture) dom_id() string {
	return Picture.dom_id(p.id)
}
