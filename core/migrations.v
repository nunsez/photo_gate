module core

import db.sqlite
import v.migrations as m

fn create_pictures(mut ctx m.Context) ! {
	ctx.execute('CREATE TABLE pictures (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  path        TEXT NOT NULL,
  status      INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  last_seen   INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  created_at  INTEGER NOT NULL
) STRICT')!
	ctx.execute('CREATE UNIQUE INDEX idx_pictures_path ON pictures (path)')!
}

fn drop_pictures(mut ctx m.Context) ! {
	ctx.execute('DROP TABLE pictures')!
}

pub fn run_migrations(mut db sqlite.DB) ! {
	mut migrator := m.new(mut db, [
		m.Migration{
			version: 20261022040812
			name:    'create_pictures'
			up:      create_pictures
			down:    drop_pictures
		},
	], m.Config{ dialect: .sqlite })!

	migrator.migrate()!
}
