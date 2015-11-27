set -e
set -x

if [[ "$EUID" != 0 ]]; then
  echo 'Please run this script as root.' >&2
  exit 1
fi

if [[ ! -d /docker-wd ]]; then
  echo '/docker-wd does not exist or is not a directory. Aborting...' >&2
  exit 1
fi

function check {
  if [[ -z "$(which "$1" 2>/dev/null)" ]]; then
    "\"$1\""' does not exist in $PATH. Aborting...' >&2
    exit 1
  fi
}

check docker

docker > /dev/null 2>&1

if [[ "$?" != 0 ]]; then
  echo 'Does not have permissions to use docker. Aborting...' >&2
  exit 1
fi

check install
check gzip
check mv
check systemctl

gitlab_isactive="$(systemctl is-active docker-gitlab.service)"

if [[ 'active' == "$gitlab_isactive" ]]; then
  systemctl stop docker-gitlab
fi


set +e
docker stop "$container"
docker rm "$container"
set -e

docker run \
  --name "$container" \
  -e              "GITLAB_HOST=$host" \
  -e              "GITLAB_SECRETS_DB_KEY_BASE=${secrets_db_key}" \
  --cpu-shares    "$cpu_share" \
  -m              "$memory" \
  --memory-swap   "$memory_swap" \
  --volumes-from  "$persistence_container" \
  --link          "${postgresql_container}:postgresql" \
  --link          "${redis_container}:redisio" \
  "$image" app:rake gitlab:backup:create

set +e
docker stop "$container"
docker rm "$container"
set -e

install -dZvm 0700 /docker-wd/gitlab

docker run \
  --name "$container" \
  --volumes-from "$persistence_container" \
  -v "/docker-wd/gitlab:/backup" \
  --entrypoint /bin/bash \
  "$image" -c 'mv -v /home/git/data/backups/* /backup'

if [[ "$gitlab_isactive" == 'active' ]]; then
  systemctl start docker-gitlab
fi

gzip -v /docker-wd/gitlab/*.tar
mv -v /docker-wd/gitlab/*.tar.gz "$backup_dir"

lastret="$?"

set +e
exit "$?"
