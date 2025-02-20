
DOCKER_REPO=gcr.io/brainscode-140622/tf-ipynb
TAG=v35
NBDIME_URL=http://host.docker.internal:8081/d/
CHART := tf-ipynb

HELM := $(shell which helm)



.PHONY: build
build: #lint
	docker build -t ${DOCKER_REPO}:${TAG} .

.PHONY: run
run:
	docker run -it -p 8080:80 \
		-v /tmp/notebooks:/notebooks \
		-v "${PWD}"/cluster_setup/:/secrets \
		-e NBDIME_URL=${NBDIME_URL} \
		-e GOOGLE_APPLICATION_CREDENTIALS="/secrets/tf2up.json" \
		${DOCKER_REPO}:${TAG}

.PHONY: push
push:
	gcloud docker -- push ${DOCKER_REPO}:${TAG}

# TODO: add env here
.PHONY: deploy
deploy:
	${HELM} lint ${CHART}
	${HELM} upgrade --install ${CHART} ./${CHART} \
		--debug #--dry-run

.PHONY: purge
purge:
	helm del --purge ${CHART}

# ====== nbdime part

.PHONY: nbbuild
nbbuild:
	docker build -t ${DOCKER_REPO}.nbdime:${TAG} -f Dockerfile.nbdime .

.PHONY: nbrun
nbrun:
	docker run -it -p 8081:81 \
		-v /tmp/notebooks:/notebooks \
		${DOCKER_REPO}.nbdime:${TAG}

.PHONY: nbpush
nbpush:
	gcloud docker -- push ${DOCKER_REPO}.nbdime:${TAG}

# ===== GCP
.PHONY: keys_update
keys_update:
	kubectl delete secret tf2up-key || true
	kubectl create secret generic tf2up-key \
		--from-file=google.json=cluster_setup/tf2up.json

# ===== lint
.PHONY: lint
lint:
	mypy \
		--config-file=configs/mypy.ini \
		src/ || true
	@echo '========================================'
	pylint src/main.py