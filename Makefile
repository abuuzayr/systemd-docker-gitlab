service_files := $(wildcard *.service *.timer)
env_files := $(wildcard *.env)
script_files := $(wildcard *.sh)

enable: enable-service
install: install-aws install-env install-scripts install-service
uninstall: uninstall-aws uninstall-env uninstall-scripts uninstall-service

enable-service: $(service_files)
	systemctl enable $^

install-aws:
	docker create \
		--name gitlab-aws-credentials \
		--volume /root/.aws \
		--entrypoint /bin/true \
		cgswong/aws && \
	docker run -it --rm \
		--name gitlab-aws \
		--volumes-from gitlab-aws-credentials \
		--entrypoint aws \
		cgswong/aws configure

install-env: $(env_files)
	install -ZDm 0600 -t /etc/systemd/system/env $^

install-scripts: $(script_files)
	install -ZDm 0644 -t /etc/systemd/system/scripts $^

install-service: $(service_files)
	install -Zm 0644 -t /etc/systemd/system $^ && \
	systemctl daemon-reload

uninstall-aws:
	docker stop gitlab-aws; \
	docker rm gitlab-aws; \
	docker rm gitlab-aws-credentials

uninstall-env: $(env_files)
	cd /etc/systemd/system/env && \
	rm -f $^

uninstall-scripts: $(script_files)
	cd /etc/systemd/system/scripts && \
	rm -f $^

uninstall-service: $(service_files)
	systemctl stop $^ ; \
	systemctl disable $^ ; \
	cd /etc/systemd/system && \
	rm -f $^ && \
	systemctl daemon-reload
