RELEASE_DIR=/var/www/releases
build_dir:
	rm -rf builds && mkdir builds

pkg: build_dir server_pkg client_pkg
	cp ../libnss/builds/* builds
	cp ../STNS/builds/* builds

server_pkg:
	cd ../STNS && make pkg

client_pkg:
	cd ../libnss && make pkg

yumrepo: ## Create some distribution packages
	rm -rf repo/centos
	docker-compose build yumrepo
	docker-compose run yumrepo

debrepo: ## Create some distribution packages
	rm -rf repo/debian
	docker-compose build debrepo
	docker-compose run debrepo

repo_release: pkg yumrepo debrepo
	ssh pyama@stns.jp rm -rf $(RELEASE_DIR)/centos
	ssh pyama@stns.jp rm -rf $(RELEASE_DIR)/debian
	scp -r repo/centos pyama@stns.jp:$(RELEASE_DIR)
	scp -r repo/debian pyama@stns.jp:$(RELEASE_DIR)
	scp -r assets/scripts/yum-repo.sh  pyama@stns.jp:$(RELEASE_DIR)/scripts
	scp -r assets/scripts/apt-repo.sh  pyama@stns.jp:$(RELEASE_DIR)/scripts
