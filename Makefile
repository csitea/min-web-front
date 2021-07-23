# Makefile
# usage: run the "make" command in the root, than make <<cmd>> ...
#
# TODO: define proj and product_name
SHELL = bash
default: help

PRODUCT := $(shell basename $$PWD)

.PHONY: help  ## @-> show this help  the default action
help:
	@clear
	@fgrep -h "##" $(MAKEFILE_LIST)|fgrep -v fgrep|sed -e 's/^\.PHONY: //'|sed -e 's/^\(.*\)##/\1/'| \
		column -t -s $$'@'

.PHONY: install  ## @-> setup the whole local devops environment
install: install_devops

.PHONY: install_devops ## @-> setup the whole local devops environment
install_devops: do_build_devops_docker_img do_create_devops_container

.PHONY: install_no_cache ## @-> setup the whole environment to run this proj, do NOT use docker cache
install_no_cache: do_build_devops_docker_img_no_cache do_create_devops_container

.PHONY: run ## @-> run some function , in this case hello world
run:
	./run -a do_run_hello_world

.PHONY: do_run ## @-> run some function , in this case hello world via the running docker container
do_run: demand_var-ENV
	@clear
	docker exec -e ENV=$$ENV -it ${PRODUCT}-devops-con /opt/min-web-front/run -a do_run_hello_world

.PHONY: do_build_devops_docker_img ## @-> build the devops docker image
do_build_devops_docker_img:
	@clear
	docker build . -t ${PRODUCT}-devops-img \
		--build-arg UID=$(shell id -u) \
		--build-arg GID=$(shell id -g) \
		--build-arg PRODUCT=${PRODUCT} \
		-f src/docker/devops/Dockerfile

.PHONY: do_build_devops_docker_img_no_cache ## @-> build the devops docker image
do_build_devops_docker_img_no_cache:
	@clear
	docker build . -t ${PRODUCT}-devops-img --no-cache \
		--build-arg UID=$(shell id -u) \
		--build-arg GID=$(shell id -g) \
		--build-arg PRODUCT=${PRODUCT} \
		-f src/docker/devops/Dockerfile

.PHONY: do_create_devops_container ## @-> create a new container our of the build img
do_create_devops_container: do_stop_devops_container
	@clear
	docker run -d \
		-v $$(pwd):/opt/${PRODUCT} \
		-v $$HOME/.aws:/home/ubuntu/.aws \
   	-v $$HOME/.ssh:/home/ubuntu/.ssh \
		--name ${PRODUCT}-devops-con ${PRODUCT}-devops-img ;
	@echo -e to attach run: "\ndocker exec -it ${PRODUCT}-devops-con /bin/bash"
	@echo -e to get help run: "\ndocker exec -it ${PRODUCT}-devops-con ./run --help"

.PHONY: do_stop_devops_container ## @-> stop the devops running container
do_stop_devops_container:
	@clear
	-@docker container stop $$(docker ps -aqf "name=${PRODUCT}-devops-con") 2> /dev/null
	-@docker container rm $$(docker ps -aqf "name=${PRODUCT}-devops-con") 2> /dev/null

.PHONY: do_prune_docker_system ## @-> stop & completely wipe out all the docker caches for ALL IMAGES !!!
do_prune_docker_system:
	@clear
	-docker kill $$(docker ps -q)
	-docker rm $$(docker ps -aq)
	docker image prune -a -f
	docker builder prune -f -a
	docker system prune --volumes -f

.PHONY: zip_me ## @-> zip the whole project without the .git dir
zip_me:
	@clear
	-rm -v ../min-web-front.zip ; zip -r ../min-web-front.zip  . -x '*.git*'

demand_var-%:
	@clear
	@if [ "${${*}}" = "" ]; then \
		echo "the var \"$*\" is not set, do set it by: export $*='value'"; \
		exit 1; \
	fi

.PHONY: task-which-requires-a-var ## @-> test shell variable is set enforcemnt
task-which-requires-a-var: demand_var-ENV
	@clear
	@echo the required variable ENV\'s value was: ${ENV}

.PHONY: spawn_tgt_project ## @-> spawn a new target project
spawn_tgt_project: demand_var-TGT_PROJ demand_var-ENV zip_me
	@clear
	-rm -r $(shell echo $(dir $(abspath $(dir $$PWD)))$$TGT_PROJ) 2>/dev/null
	unzip -o ../min-web-front.zip -d $(shell echo $(dir $(abspath $(dir $$PWD)))$$TGT_PROJ)
	ENV=dev to_srch=${PRODUCT} to_repl=$(shell echo $$TGT_PROJ) dir_to_morph=$(shell echo $(dir $(abspath $(dir $$PWD)))$$TGT_PROJ) ./run -a do_morph_dir
