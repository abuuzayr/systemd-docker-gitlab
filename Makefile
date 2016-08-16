service_files := $(wildcard *.service *.timer)
env_files := $(wildcard *.env)
script_files := $(wildcard *.sh)

install: install-env install-scripts install-service
uninstall: uninstall-env uninstall-scripts uninstall-service

install-env: $(env_files)
	install -ZDm 0600 -t /etc/systemd/system/env $^

install-scripts: $(script_files)
	install -ZDm 0644 -t /etc/systemd/system/scripts $^

install-service: $(service_files)
	install -Zm 0644 -t /etc/systemd/system $^ && \
	systemctl daemon-reload

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
