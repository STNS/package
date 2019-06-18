RELEASE_DIR=/var/www/html

SCP=dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp
SSH=-p 33641 dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp

build_dir:
	rm -rf builds && mkdir builds

pkg: build_dir server_pkg client_pkg
	cp ../libnss/builds/* builds
	cp ../STNS/builds/* builds

server_pkg:
	cd ../STNS && make pkg && (make github_release || true)

client_pkg:
	cd ../libnss && make pkg && (make github_release || true)

yumrepo: ## Create some distribution packages
	rm -rf repo/centos
	docker-compose build yumrepo
	docker-compose run yumrepo

debrepo: ## Create some distribution packages
	rm -rf repo/jessie
	rm -rf repo/stretch
	rm -rf repo/xenial
	docker-compose build debrepo-xenial
	docker-compose build debrepo-jessie
	docker-compose build debrepo-stretch
	docker-compose run debrepo-xenial
	docker-compose run debrepo-jessie
	docker-compose run  debrepo-stretch

repo_release: pkg yumrepo debrepo
	ssh $(SSH) rm -rf $(RELEASE_DIR)/centos
	ssh $(SSH) rm -rf $(RELEASE_DIR)/jessie
	ssh $(SSH) rm -rf $(RELEASE_DIR)/stretch
	ssh $(SSH) rm -rf $(RELEASE_DIR)/xenial
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp -P 33641 -r repo/centos $(SCP):$(RELEASE_DIR)
	scp -P 33641 -r repo/jessie $(SCP):$(RELEASE_DIR)
	scp -P 33641 -r repo/stretch $(SCP):$(RELEASE_DIR)
	scp -P 33641 -r repo/xenial $(SCP):$(RELEASE_DIR)
	scp -P 33641 assets/GPG-KEY-stns $(SCP):$(RELEASE_DIR)/gpg/
	scp -P 33641 assets/scripts/yum-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
	scp -P 33641 assets/scripts/apt-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
