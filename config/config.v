module config

import os
import json2

pub struct Config {
pub:
	database  string
	pool_size i32
	walk      []WalkConfig
}

pub struct WalkConfig {
pub:
	root    string
	exclude []string
}

pub fn parse(config_path string) !Config {
	content := os.read_file(config_path)!
	cfg := json2.decode[Config](content, strict: true)!
	return cfg
}
