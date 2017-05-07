#! /bin/sh

# Go 1.8+ required. Ubuntu installation:
#  sudo add-apt-repository ppa:longsleep/golang-backports
#  sudo apt-get update
#  sudo apt-get install golang-go

[ $# -eq 0 -o $# -eq 1 -a "$1" = run ] || (echo "Usage: $0 [run]" >&2; false) || exit 1

GOPATH="$(dirname "$0")"
export GOPATH="$(cd "$GOPATH" && pwd)" || exit 1

(
set -x

# Format code
gofmt -w "$GOPATH/src/github.com/mgoltzsche"

# Fetch dependencies
go get gopkg.in/yaml.v2 &&
go get gopkg.in/appc/docker2aci.v0 &&

# Build linked binary to $GOPATH/bin/rkt-compose
go install github.com/mgoltzsche/rkt-compose &&

# Build and run tests
go test github.com/mgoltzsche/checks &&
sudo GOPATH="$GOPATH" go test github.com/mgoltzsche/model
) || exit 1

# Run
if [ "$1" = run ]; then
	set -x
	sudo "$GOPATH/bin/rkt-compose" --verbose=true run --name=examplepod --uuid-file=/var/run/examplepod.uuid test-resources/example-docker-compose-images.yml

	#sudo "$GOPATH/bin/rkt-compose" run --name=consul --uuid-file=/var/run/consul.uuid test-resources/consul.json &
	#sudo "$GOPATH/bin/rkt-compose" run --name=testpod --uuid-file=/var/run/pod.uuid --consul-ip=172.16.28.1 test-resources/example-docker-compose-images.yml
else
	cat <<-EOF
		___________________________________________________

		rkt-compose has been built and tested successfully!

		Run example pod:
		  sudo "$GOPATH/bin/rkt-compose" run --name=examplepod --uuid-file=/var/run/examplepod.uuid test-resources/example-docker-compose-images.yml

		Run consul and example pod registered at consul:
		  sudo "$GOPATH/bin/rkt-compose" run --name=consul --uuid-file=/var/run/consul.uuid test-resources/consul.json &
		  sudo "$GOPATH/bin/rkt-compose" run --name=examplepod --uuid-file=/var/run/examplepod.uuid --consul-ip=172.16.28.1 test-resources/example-docker-compose-images.yml
	EOF
fi
