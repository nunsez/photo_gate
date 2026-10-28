module datastar

pub const sse = 'text/event-stream'

pub fn remove_event(selector string) string {
	return 'event: datastar-patch-elements
data: selector ${selector}
data: mode remove\n\n'
}

pub fn append_event(selector string, elements string) string {
	return 'event: datastar-patch-elements
data: selector ${selector}
data: mode append
data: elements ${elements}\n\n'
}
