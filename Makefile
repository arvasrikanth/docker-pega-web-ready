IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)
MAJOR_MINOR := $(if $(MAJOR_MINOR),$(MAJOR_MINOR),CUSTOM)
BUILD_NUMBER := $(if $(GITHUB_RUN_NUMBER),$(GITHUB_RUN_NUMBER),BUILD)
VERSION := $(if $(VERSION),$(VERSION),$(MAJOR_MINOR).$(BUILD_NUMBER))
EXTRACT_VAR=JAVA_VERSION

all: image

container: image

define inspect_image
    docker pull akshithachittanoori276/testir:US-624164-tomcat
	$(eval $(EXTRACT_VAR)=$(shell docker inspect akshithachittanoori276/testir:US-624164-tomcat | jq -r '.[0].Config.Env[] | select(startswith("$(EXTRACT_VAR)="))' | cut -d'=' -f2))
endef

inspect:
	$(inspect_image)
	@echo "Extracted $(EXTRACT_VAR): $(JAVA_VERSION)"

image:inspect
#	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk17 -t $(IMAGE_NAME) . # Build image and automatically tag it as latest on jdk17
	docker build --build-arg VERSION=$(VERSION)  --build-arg $(EXTRACT_VAR)=$(JAVA_VERSION) --build-arg BASE_TOMCAT_IMAGE=akshithachittanoori276/testir:US-624164-tomcat -t $(IMAGE_NAME):US-624164-tomcat . # Build image using tomcat 9 , jdk 11
#	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk17 -t $(IMAGE_NAME):3-jdk17 . # Build image using tomcat 9 , jdk 17


test: image
	# Build image for executing test cases against it
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=akshithachittanoori276/testir:US-624164-tomcat -t qualitytest . --target qualitytest
	# Execute test cases
	#container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	#container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml
	#container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	#container-structure-test test --image $(IMAGE_NAME):3-jdk11 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):US-624164-tomcat --config tests/pega-web-ready-release-testcases_jdk11_version.yaml
	#container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases.yaml
	#container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases_jdk17_version.yaml

push: image
	#docker tag $(IMAGE_NAME):3-jdk11 $(IMAGE_NAME):US-624164-tomcat-jdk11
	#docker tag $(IMAGE_NAME):3-jdk17 $(IMAGE_NAME):$(VERSION)-jdk17
	docker push $(IMAGE_NAME):US-624164-tomcat
	#docker push $(IMAGE_NAME):$(VERSION)-jdk17
	#docker push $(IMAGE_NAME):3-jdk11
	#docker push $(IMAGE_NAME):3-jdk17
	#docker push $(IMAGE_NAME):latest