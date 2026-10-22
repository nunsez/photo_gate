module core

pub struct Pagination {
pub:
	current u64
	last    u64
	range   []u64
}

pub fn (p &Pagination) has_next() bool {
	return p.current < p.last
}

pub fn (p &Pagination) has_prev() bool {
	return p.current > 1
}

@[params]
struct PaginationParams {
pub:
	current_page u64
	total_items  u64
	per_page     u64
}

pub fn new_pagination(params PaginationParams) Pagination {
	last_page := (params.total_items + params.per_page - 1) / params.per_page
	range := build_page_range(params.current_page, last_page)
	return Pagination{ current: params.current_page, last: last_page, range: range }
}

fn build_page_range(current u64, last u64) []u64 {
	if last <= 7 {
		mut result := []u64{}
		for i := 1; i <= last; i++ { result << i }
		return result
	}

	if current <= 4 {
		return [1, 2, 3, 4, 5, 0, last]
	}

	if current >= last - 3 {
		return [1, 0, last - 4, last - 3, last - 2, last - 1, last]
	}

	return [1, 0, current - 1, current, current + 1, 0, last]
}
