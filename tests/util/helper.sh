
fn-source() {
	declare desc="Prints the source of a function"
	declare -f $1 | tail -n +2
}

check-buildpacks() {
	[[ "$(docker ps -qaf name=herokuish-buildpacks)" ]]
}

download-buildpacks() {
	docker run --name herokuish-buildpacks -v /tmp/buildpacks \
		herokuish:cedar14 \
		herokuish buildpack install
}

run-in-docker() {
	declare fn="$1"
	[[ "$CI" ]] || rmflag="--rm"
	docker run $rmflag \
		herokuish:cedar14 \
		bash -c "set -e; $(fn-source $fn)" \
		|| $fail "$fn exited non-zero"
}

run-app-test() {
	declare app="$1" expected="$2"
	check-buildpacks || download-buildpacks
	[[ "$CI" ]] || rmflag="--rm"
	docker run $rmflag -v "$PWD/tests/apps/$app:/tmp/app" --volumes-from herokuish-buildpacks \
		herokuish:cedar14 \
		bash -c "\
			rm -rf /app && cp -r /tmp/app /app
			/mnt/build/linux/herokuish buildpack build
			PORT=5678 /mnt/build/linux/herokuish procfile start web &
			for retry in \$(seq 1 10); do sleep 1 && nc -z -w 5 localhost 5678 && break; done
			output=\"\$(curl --retry 3 -v -s localhost:5678)\"
			sleep 1
			echo '=== APP OUTPUT ==='
			echo -e \"\$output\"
			echo '=== END OUTPUT ==='
			[[ \"\$output\" == \"$expected\" ]]" \
		|| $fail "Unable to build $app app or output not: $expected"
}
