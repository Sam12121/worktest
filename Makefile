# Set the fallback version to "v2.0.1" if git describe fails
VERSION ?= $(shell git describe --tags 2>/dev/null || echo "v2.0.1")
GIT_COMMIT=`git rev-parse HEAD`
BUILD_TIME=`date -u +%FT%TZ`

all: toae_worker

local: toae_worker

image:
	docker run --rm -i -v $(ROOT_MAKEFILE_DIR):/src:rw -v /tmp/go:/go:rw toaeio/toae_builder_ce:$(DF_IMG_TAG) bash -c 'cd /src/toae_worker && make toae_worker'
	docker build -f ./Dockerfile --build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY) --build-arg DF_IMG_TAG=$(DF_IMG_TAG) -t $(IMAGE_REPOSITORY)/toae_worker_ce:$(DF_IMG_TAG) ..

vendor: go.mod $(shell find ./toae_utils -path ./toae_utils/vendor -prune -o -name '*.go')
	go mod tidy -v
	go mod vendor

toae_worker: vendor $(shell find . -path ./vendor -prune -o -name '*.go')
	go build -buildvcs=false -buildmode=pie -ldflags="-s -w -X main.Version=${VERSION} -X main.Commit=${GIT_COMMIT} -X main.BuildTime=${BUILD_TIME}"

clean:
	-rm toae_worker
	-rm -rf ./vendor

.PHONY: all clean image local
