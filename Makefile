IMAGE=dockerswarm_dns_server
TAG=latest

it:
	@echo "make [build|run]"

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run -it --rm --network dockerswarm_sd_network -p 5353:53/tcp $(IMAGE):$(TAG)

stack: stack/deploy

stack/deploy:
	$(MAKE) -C stack deploy

stack/destroy:
	$(MAKE) -C stack destroy
