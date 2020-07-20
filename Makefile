RELEASE_DIR=/var/www/html

SCP=dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp
SSH=-p 33641 dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp
PRODUCT_CODES=centos jessie stretch xenial bionic debian
build_dir:
	rm -rf builds && mkdir builds

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
	rm -rf repo/centos
	docker-compose build yumrepo
	docker-compose run yumrepo

debrepo: ## Create some distribution packages
	for i in $(PRODUCT_CODES); do\
	  	if [ "$$i" = "centos" ];then continue; fi; \
		rm -rf repo/$$i; \
		docker-compose build debrepo-$$i; \
		docker-compose run debrepo-$$i; \
	done

repo_release: pkg yumrepo debrepo
	for i in $(PRODUCT_CODES); do\
		rsync --delete -avz repo/$$i -e 'ssh -p33641' $(SCP):$(RELEASE_DIR); \
	done
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp -P 33641 assets/GPG-KEY-stns $(SCP):$(RELEASE_DIR)/gpg/
	scp -P 33641 assets/scripts/yum-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
	scp -P 33641 assets/scripts/apt-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
