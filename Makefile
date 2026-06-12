IMG ?= ghcr.io/unict-cclab/mon-agent:latest
PROMETHEUS_URL ?= http://localhost:9090
NAMESPACE_LABEL_SELECTOR ?= mon-agent/enabled=true
SCRAPE_PERIOD_SECONDS ?= 30

run:
	PROMETHEUS_URL=${PROMETHEUS_URL} \
	NAMESPACE_LABEL_SELECTOR=${NAMESPACE_LABEL_SELECTOR} \
	SCRAPE_PERIOD_SECONDS=${SCRAPE_PERIOD_SECONDS} \
	go run .

build:
	go build -buildvcs=false

build-image:
	docker build -t ${IMG} .

push-image:
	docker push ${IMG}
