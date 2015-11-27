service_files := $(wildcard *.service *.timer)
config_files := $(wildcard *.pod.conf)
script_files := $(wildcard *.sh)

install: install-config install-scripts install-service
uninstall: uninstall-config uninstall-scripts uninstall-service

install-config: $(config_files)
	install -Zbm 0600 -t /etc $^

install-scripts: $(script_files)
	install -Zm 0644 -t /usr/local/bin $^

install-service: $(service_files)
	install -Zm 0644 -t /etc/systemd/system $^ && \
	systemctl daemon-reload

uninstall-config: $(config_files)
	cd /etc && \
	rm -f $^

uninstall-scripts: $(script_files)
	cd /usr/local/bin && \
	rm -f $^

uninstall-service: $(service_files)
	systemctl stop $^ ; \
	systemctl disable $^ ; \
	cd /etc/systemd/system && \
	rm -f $^ && \
	systemctl daemon-reload
