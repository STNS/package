RELEASE_DIR=/var/www/html

SCP=dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp
SSH=-p 33641 dark-hitoyoshi-1876@ssh-1.mc.lolipop.jp
PRODUCT_CODES=centos buster bullseye bionic focal jammy debian

old_assets:
	mkdir -p old_assets/centos/x86_64/{6,7,8} old_assets/centos/i386
	mkdir -p old_assets/deb
	curl https://github.com/STNS/STNS/releases/download/v0.4/stns-0.4-0.x86_64.rpm -s -L -o old_assets/centos/x86_64/stns-0.4-0.x86_64.rpm
	curl https://github.com/STNS/STNS/releases/download/v0.4/stns-0.4-0.i386.rpm -s -L -o old_assets/centos/i386/stns-0.4-0.i386.rpm
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libnss-stns-0.4.5-1.i386.rpm -s -L -o old_assets/centos/i386/libnss-stns-0.4.5-1.i386.rpm
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libpam-stns-0.4.5-1.i386.rpm -s -L -o old_assets/centos/i386/libpam-stns-0.4.5-1.i386.rpm
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libnss-stns-0.4.5-1.x86_64.rpm -s -L -o old_assets/centos/x86_64/libnss-stns-0.4.5-1.x86_64.rpm
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libpam-stns-0.4.5-1.x86_64.rpm -s -L -o old_assets/centos/x86_64/libpam-stns-0.4.5-1.x86_64.rpm
	curl https://github.com/STNS/STNS/releases/download/v0.4/stns_0.4.0_amd64.deb -s -L -o old_assets/deb/stns-0.4.0.amd64.deb
	curl https://github.com/STNS/STNS/releases/download/v0.4/stns_0.4.0_i386.deb -s -L -o old_assets/deb/stns-0.4.0.i386.deb
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libnss-stns_0.4.5_amd64.deb -s -L -o old_assets/deb/libnss-stns_0.4.5_amd64.deb
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libpam-stns_0.4.5_amd64.deb -s -L -o old_assets/deb/libpam-stns_0.4.5_amd64.deb
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libnss-stns_0.4.5_i386.deb -s -L -o old_assets/deb/libnss-stns_0.4.5_i386.deb
	curl https://github.com/STNS/libnss_stns/releases/download/v0.4.5/libpam-stns_0.4.5_i386.deb -s -L -o old_assets/deb/libpam-stns_0.4.5_i386.deb
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



repo_release: pkg old_assets yumrepo debrepo #server_pkg client_pkg cached_pkg
	for i in $(PRODUCT_CODES); do\
		rsync --delete -avz repo/$$i -e 'ssh -p33641' $(SCP):$(RELEASE_DIR); \
	done
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp -P 33641 assets/GPG-KEY-stns $(SCP):$(RELEASE_DIR)/gpg/
	scp -P 33641 assets/scripts/yum-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
	scp -P 33641 assets/scripts/apt-repo.sh $(SCP):$(RELEASE_DIR)/scripts/
