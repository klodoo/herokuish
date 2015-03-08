
source "$(dirname $BASH_SOURCE)/../util/helper.sh"

test_binary() {
	declare wrap="run-in-docker"
	herokuish
}

test_slug-generate() {
	declare wrap="run-in-docker"
	herokuish slug generate
	tar tzf /tmp/slug.tgz
}
