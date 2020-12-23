SHELL := bash
.SHELLFLAGS := -o pipefail -euc

export PATH := bin:$(PATH)

include .env
export

.PHONY: help
help:
	@echo "usage:"
	@echo
	@cat Makefile | \
		grep -E '[.]PHONY|[#]##' | \
		sed -E 's/[.]PHONY: */  make /' | \
		sed -E 's/[#]## *(.+)/\n    (\1)\n/'

### Build things locally

.PHONY: packaging-image
packaging-image:
	docker build . -f docker/packaging/Dockerfile -t riju-packaging --pull

.PHONY: runtime-image
runtime-image:
	docker build . -f docker/runtime/Dockerfile -t riju-runtime --pull

.PHONY: app-image
app-image:
	docker build . -f docker/app/Dockerfile -t riju-app --pull

.PHONY: pkg
pkg:
	@: $${L}
	node src/packager/main.js --lang $(L)

### Run things inside Docker

.PHONY: packaging-shell
packaging-shell:
	docker run -it --rm -v $(PWD):/src riju:packaging

.PHONY: runtime-shell
runtime-shell:
	docker run -it --rm -v $(PWD):/src riju:runtime

### Fetch things from registries

.PHONY: fetch-packaging-image
fetch-packaging-image:
	docker pull $(DOCKER_REPO_BASE)-packaging
	docker tag $(DOCKER_REPO_BASE)-packaging riju-packaging

.PHONY: fetch-runtime-image
fetch-runtime-image:
	docker pull $(DOCKER_REPO_BASE)-runtime
	docker tag $(DOCKER_REPO_BASE)-runtime riju-runtime

.PHONY: fetch-app-image
fetch-app-image:
	docker pull $(DOCKER_REPO_BASE)-app
	docker tag $(DOCKER_REPO_BASE)-app riju-app

.PHONY: fetch-pkg
fetch-pkg:
	@: $${L}
	mkdir -p debs
	aws s3 cp s3://$(S3_BUCKET_BASE)-debs/debs/$(L).deb debs/$(L).deb

### Publish things to registries

.PHONY: publish-packaging-image
publish-packaging-image:
	docker tag riju-packaging $(DOCKER_REPO_BASE)-packaging
	docker push $(DOCKER_REPO_BASE)-packaging

.PHONY: publish-runtime-image
publish-runtime-image:
	docker tag riju-runtime $(DOCKER_REPO_BASE)-runtime
	docker push $(DOCKER_REPO_BASE)-runtime

.PHONY: publish-app-image
publish-app-image:
	docker tag riju-app $(DOCKER_REPO_BASE)-app
	docker push $(DOCKER_REPO_BASE)-app

.PHONY: publish-pkg
publish-pkg:
	@: $${L}
	aws s3 cp debs/$(L).deb s3://$(S3_BUCKET_BASE)-debs/debs/$(L).deb

### Miscellaneous

.PHONY: dockerignore
dockerignore:
	echo "# This file is generated by 'make dockerignore', do not edit." > .dockerignore
	cat .gitignore | sed 's#^#**/#' >> .dockerignore
