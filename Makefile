RELEASE_DIR=/var/www/html

ENVIRONMENT ?= staging
PRODUCTION_SSH=rough-field-2764@ssh.mc.lolipop.jp
STAGING_SSH=lingering-dew-9357@ssh.mc.lolipop.jp

SSH = $(if $(filter staging,$(ENVIRONMENT)),$(STAGING_SSH),$(PRODUCTION_SSH))
PRODUCT_CODES=centos almalinux buster bullseye focal jammy debian

build_dir:
	mkdir -p builds
	rm -rf builds/*
pkg: build_dir
	cp ../libnss/builds/* builds
	cp ../STNS/builds/* builds
	cp ../cache-stnsd/builds/* builds

server_pkg:
	cd ../STNS && make pkg && (make github_release || true)

client_pkg:
	cd ../libnss && make pkg && (make github_release || true)

cached_pkg:
	cd ../cache-stnsd && make pkg && (make github_release || true)

yumrepo: ## Create some distribution packages
	sudo rm -rf repo/centos
	docker-compose build yumrepo
	docker-compose run yumrepo

debrepo: ## Create some distribution packages
	for i in $(PRODUCT_CODES); do\
	  	if [ "$$i" = "centos" ];then continue; fi; \
	  	if [ "$$i" = "almalinux" ];then continue; fi; \
		rm -rf repo/$$i; \
		docker-compose build debrepo-$$i; \
		docker-compose run debrepo-$$i; \
	done

production_deploy: ENVIRONMENT=production
production_deploy: deploy
staging_deploy: ENVIRONMENT=staging
staging_deploy: deploy

deploy: #pkg yumrepo debrepo #server_pkg client_pkg cached_pkg
	for i in $(PRODUCT_CODES); do\
		rsync --delete -avz repo/$$i -e 'ssh' $(SSH):$(RELEASE_DIR); \
	done
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp assets/GPG-KEY-stns $(SSH):$(RELEASE_DIR)/gpg/
	scp assets/scripts/yum-repo.sh $(SSH):$(RELEASE_DIR)/scripts/
	scp assets/scripts/apt-repo.sh $(SSH):$(RELEASE_DIR)/scripts/
