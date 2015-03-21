
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z1-app-python-odoo() {
	run-app-test python-odoo "python-odoo"
}
