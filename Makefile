systemd_service_dir := /etc/systemd/system
sysconfig_dir := /etc/sysconfig
bin_dir := /usr/local/bin

repos_systemd_service_dir := systemd/system
repos_sysconfig_dir := sysconfig
repos_bin_dir := bin

port := 80
ssh_port := 10022

image := sameersbn/gitlab
container := gitlab
data_container := $(container)-data
data_dir := /home/git/data
log_container := $(container)-log
log_dir := /var/log/gitlab
sysconfig := docker-$(container)
service := docker-$(container).service
backup_script := backup-docker-$(container)


postgresql_image := postgres:9.4
postgresql_container := gitlab-postgresql
postgresql_username := gitlab
postgresql_db := $(postgresql_username)
postgresql_password := q97uHKwqaCVx6nwqFVzMsUIRcl8EEY54
postgresql_data_container := $(postgresql_container)-data
postgresql_data_dir := /var/lib/postgresql/data
postgresql_sysconfig := docker-$(postgresql_container)
postgresql_service := docker-$(postgresql_container).service
postgresql_backup_script := backup-docker-$(postgresql_container)

redis_image := redis:3.0
redis_container := gitlab-redis
redis_data_container := $(redis_container)-data
redis_data_dir := /data
redis_sysconfig := docker-$(redis_container)
redis_service := docker-$(redis_container).service
redis_backup_script := backup-docker-$(redis_container)

# all section
# -----------

persistence: postgresql-data redis-data gitlab-data gitlab-log

rm: rm-postgresql-data rm-redis-data rm-gitlab-data rm-gitlab-log

stop: | stop-gitlab stop-redis stop-postgresql

install: install-postgresql install-redis install-gitlab

uninstall: uninstall-gitlab uninstall-postgresql uninstall-redis


# gitlab section
# --------------
gitlab-data:
	docker create \
		--name '$(data_container)' \
		-v '$(data_dir)' \
		'$(image)' /bin/true; \
	exit 0

gitlab-log:
	docker create \
		--name '$(log_container)' \
		-v '$(log_dir)' \
		'$(image)' /bin/true; \
	exit 0

rm-gitlab-data:
	docker rm '$(data_container)'; \
	exit 0

rm-gitlab-log:
	docker rm '$(log_container)'; \
	exit 0

run-gitlab:
	docker run -it --rm \
		--name '$(container)' \
		--volumes-from '$(data_container)' \
		--volumes-from '$(log_container)' \
		--link '$(postgresql_container):postgresql' \
		--link '$(redis_container):redisio' \
		-p '$(port):80' \
		-p '$(ssh_port):22' \
		-e 'GITLAB_PORT=$(port)' \
		-e 'GITLAB_SSH_PORT=$(ssh_port)' \
		'$(image)'

run-gitlab-bash:
	docker run -it --rm \
		--name '$(container)' \
		--volumes-from '$(data_container)' \
		--volumes-from '$(log_container)' \
		'$(image)' bash

stop-gitlab:
	docker stop '$(container)'; \
	exit 0

install-gitlab:
	install -Zm 0600 -o root -g root \
		'$(repos_systemd_service_dir)/$(service)' \
		'$(systemd_service_dir)/$(service)' && \
	systemctl daemon-reload && \
	install -bZm 0600 -o root -g root \
		'$(repos_sysconfig_dir)/$(sysconfig)' \
		'$(sysconfig_dir)/$(sysconfig)' && \
	install -Zm 0700 -o root -g root \
		'$(repos_bin_dir)/$(backup_script)' \
		'$(bin_dir)/$(backup_script)'

uninstall-gitlab:
	rm -f '$(systemd_service_dir)/$(service)' && \
	systemctl daemon-reload && \
	rm -f '$(sysconfig_dir)/$(sysconfig)' && \
	rm -f '$(bin_dir)/$(backup_script)'

# redis section
# -------------
redis-data:
	docker create \
		--name '$(redis_data_container)' \
		-v '$(redis_data_dir)' \
		'$(redis_image)' /bin/true; \
	exit 0

rm-redis-data:
	docker rm '$(redis_data_container)'; \
	exit 0

run-redis:
	docker run -it --rm \
		--name '$(redis_container)' \
		--volumes-from '$(redis_data_container)' \
		'$(redis_image)'

run-redis-bash:
	docker run -it --rm \
		--name '$(redis_container)' \
		--volumes-from '$(redis_data_container)' \
		'$(redis_image)' bash

stop-redis:
	docker stop '$(redis_container)'; \
	exit 0

install-redis:
	install -Zm 0600 -o root -g root \
		'$(repos_systemd_service_dir)/$(redis_service)' \
		'$(systemd_service_dir)/$(redis_service)' && \
	systemctl daemon-reload && \
	install -bZm 0600 -o root -g root \
		'$(repos_sysconfig_dir)/$(redis_sysconfig)' \
		'$(sysconfig_dir)/$(redis_sysconfig)' && \
	install -Zm 0700 -o root -g root \
		'$(repos_bin_dir)/$(redis_backup_script)' \
		'$(bin_dir)/$(redis_backup_script)'

uninstall-redis:
	rm -f '$(systemd_service_dir)/$(redis_service)' && \
	systemctl daemon-reload && \
	rm -f '$(sysconfig_dir)/$(redis_sysconfig)' && \
	rm -f '$(bin_dir)/$(redis_backup_script)'


# postgresql section
# ------------------
postgresql-data:
	docker create \
		--name '$(postgresql_data_container)' \
		-v '$(postgresql_data_dir)' \
		'$(postgresql_image)' /bin/true; \
	exit 0

rm-postgresql-data:
	docker rm '$(postgresql_data_container)'; \
	exit 0

run-postgresql:
	docker run -it --rm \
		--name '$(postgresql_container)' \
		-e 'POSTGRES_USER=$(postgresql_username)' \
		-e 'POSTGRES_PASSWORD=$(postgresql_password)' \
		-e 'DB_NAME=$(postgresql_db)' \
		-e 'DB_USER=$(postgresql_username)' \
		-e 'DB_PASS=$(postgresql_password)' \
		--volumes-from '$(postgresql_data_container)' \
		'$(postgresql_image)'

run-postgresql-bash:
	docker run -it --rm \
		--name '$(postgresql_container)' \
		-e 'POSTGRES_USER=$(postgresql_username)' \
		-e 'POSTGRES_PASSWORD=$(postgresql_password)' \
		-e 'DB_NAME=$(postgresql_db)' \
		-e 'DB_USER=$(postgresql_username)' \
		-e 'DB_PASS=$(postgresql_password)' \
		--volumes-from '$(postgresql_data_container)' \
		'$(postgresql_image)' bash

stop-postgresql:
	docker stop '$(postgresql_container)'; \
	exit 0

install-postgresql:
	install -Zm 0600 -o root -g root \
		'$(repos_systemd_service_dir)/$(postgresql_service)' \
		'$(systemd_service_dir)/$(postgresql_service)' && \
	systemctl daemon-reload && \
	install -bZm 0600 -o root -g root \
		'$(repos_sysconfig_dir)/$(postgresql_sysconfig)' \
		'$(sysconfig_dir)/$(postgresql_sysconfig)' && \
	install -Zm 0700 -o root -g root \
		'$(repos_bin_dir)/$(postgresql_backup_script)' \
		'$(bin_dir)/$(postgresql_backup_script)'

uninstall-postgresql:
	rm -f '$(systemd_service_dir)/$(postgresql_service)' && \
	systemctl daemon-reload && \
	rm -f '$(sysconfig_dir)/$(postgresql_sysconfig)' && \
	rm -f '$(bin_dir)/$(postgresql_backup_script)'

.PHONY: gitlab-data gitlab-log rm-gitlab-data rm-gitlab-log run-gitlab run-gitlab-bash stop-gitlab install-gitlab uninstall-gitlab redis-data rm-redis-data run-redis run-redis-bash stop-redis install-redis uninstall-redis postgresql-data rm-postgresql-data run-postgresql run-postgresql-bash stop-postgresql install-postgresql uninstall-postgresql
