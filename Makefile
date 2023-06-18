RELEASE_DIR=/var/www/html

ENVIRONMENT ?= staging
PRODUCTION_SSH=rough-field-2764@ssh.mc.lolipop.jp
STAGING_SSH=lingering-dew-9357@ssh.mc.lolipop.jp

SSH = $(if $(filter staging,$(ENVIRONMENT)),$(STAGING_SSH),$(PRODUCTION_SSH))
PRODUCT_CODES=centos almalinux buster bullseye focal jammy debian

pkg:
	bin/download_artifacts STNS STNS
	bin/download_artifacts STNS libnss
	bin/download_artifacts STNS cache-stnsd

yumrepo: ## Create some distribution packages
	sudo rm -rf repo/centos
	docker-compose build yumrepo
	docker-compose run -e GPG_PASSWORD=$(GPG_PASSWORD) yumrepo

debrepo: ## Create some distribution packages
	for i in $(PRODUCT_CODES); do\
	  	if [ "$$i" = "centos" ];then continue; fi; \
	  	if [ "$$i" = "almalinux" ];then continue; fi; \
		sudo rm -rf repo/$$i; \
		docker-compose build debrepo-$$i; \
		docker-compose run -e GPG_PASSWORD=$(GPG_PASSWORD) debrepo-$$i; \
	done

production_deploy: ENVIRONMENT=production
production_deploy: deploy
staging_deploy: ENVIRONMENT=staging
staging_deploy: deploy

deploy: pkg yumrepo debrepo
	for i in $(PRODUCT_CODES); do\
		rsync --delete -avz repo/$$i -e 'ssh' $(SSH):$(RELEASE_DIR); \
	done
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp assets/GPG-KEY-stns $(SSH):$(RELEASE_DIR)/gpg/
	scp assets/scripts/yum-repo.sh $(SSH):$(RELEASE_DIR)/scripts/
	scp assets/scripts/apt-repo.sh $(SSH):$(RELEASE_DIR)/scripts/
