module datastar

pub const sse = 'text/event-stream'

pub fn remove_event(selector string) string {
	return 'event: datastar-patch-elements
data: selector ${selector}
data: mode remove\n\n'
}
