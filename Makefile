RELEASE_DIR=/home/xs549470/stns.jp/public_html/repo

SSH=xs549470@sv13076.xserver.jp
PRODUCT_CODES=centos almalinux buster bullseye bookworm focal jammy noble debian

pkg:
	bin/download_artifacts STNS STNS
	bin/download_artifacts STNS libnss
	bin/download_artifacts STNS cache-stnsd

yumrepo: ## Create some distribution packages
	sudo rm -rf repo/centos
	docker compose build yumrepo
	docker compose run -e GPG_PASSWORD=$(GPG_PASSWORD) yumrepo

debrepo: ## Create some distribution packages
	for i in $(PRODUCT_CODES); do\
	  	if [ "$$i" = "centos" ];then continue; fi; \
	  	if [ "$$i" = "almalinux" ];then continue; fi; \
		sudo rm -rf repo/$$i; \
		docker compose build debrepo-$$i; \
		docker compose run -e GPG_PASSWORD=$(GPG_PASSWORD) debrepo-$$i; \
	done


deploy: pkg yumrepo debrepo
	for i in $(PRODUCT_CODES); do\
		rsync --delete -avz repo/$$i -e 'ssh -p10022' $(SSH):$(RELEASE_DIR); \
	done
	ssh -p10022 $(SSH) mkdir -p $(RELEASE_DIR)/scripts
	ssh -p10022 $(SSH) mkdir -p $(RELEASE_DIR)/gpg
	scp -P10022 assets/GPG-KEY-stns $(SSH):$(RELEASE_DIR)/gpg/
	scp -P10022 assets/scripts/yum-repo.sh $(SSH):$(RELEASE_DIR)/scripts/
	scp -P10022 assets/scripts/apt-repo.sh $(SSH):$(RELEASE_DIR)/scripts/

run_docker:
	docker build -t stns-build .
	docker rm -f stns-build || true
	docker run --name stns-build -d --privileged -t stns-build /sbin/init
	docker exec -it stns-build /bin/bash
