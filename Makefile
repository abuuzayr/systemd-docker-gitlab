service_files = docker-gitlab.service docker-gitlab-postgresql.service docker-gitlab-redis.service
config_files = docker-gitlab.pod.conf

install:
	install -Zvm 0644 -t /etc/systemd/system $(service_files) && \
	systemctl daemon-reload && \
	install -Zvbm 0600 -t /etc $(config_files)

uninstall:
	cd /etc/systemd/system && \
	rm -vf $(service_files) \
	systemctl daemon-reload && \
	cd /etc && \
	rm -vf $(config_files)
