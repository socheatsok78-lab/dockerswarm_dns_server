docker_stack_name := dockerswarm_dns_server

it:
	@echo "make [deploy|destroy]"
	@echo "  deploy: deploy docker stack"
	@echo "  destroy: destroy docker stack"

deploy:
	docker stack deploy -c docker-compose.yml $(docker_stack_name)

destroy:
	docker stack rm $(docker_stack_name)
