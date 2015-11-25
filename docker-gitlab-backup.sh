set -e
docker='/usr/bin/docker'
systemctl='/usr/bin/systemctl'
gz='/usr/bin/gzip'
mv='/usr/bin/mv'

function errnoexe {
  echo "$1 not found or not executable" >&2
}

if [[ ! -x $docker ]]; then
  errnoexe "$docker"
  exit 1
fi

if [[ ! -x $systemctl ]]; then
  errnoexe "$systemctl"
  exit 1
fi

if [[ ! -x $gz ]]; then
  errnoexe "$gz"
  exit 1
fi

if [[ ! -x $mv ]]; then
  errnoexe "$mv"
  exit 1
fi


gitlab_isactive="$($systemctl is-active docker-gitlab.service)"

if [[ "$gitlab_isactive" == 'active' ]]; then
  "$systemctl" stop docker-gitlab
fi


set +e
"$docker" stop "$container"
"$docker" rm "$container"
set -e

"$docker" run \
  --name "$container" \
  -e              "GITLAB_HOST=$host" \
  --cpu-shares    "$cpu_share" \
  -m              "$memory" \
  --memory-swap   "$memory_swap" \
  --volumes-from  "$persistence_container" \
  --link          "${postgresql_container}:postgresql" \
  --link          "${redis_container}:redisio" \
  "$image" app:rake gitlab:backup:create

set +e
"$docker" stop "$container"
"$docker" rm "$container"
set -e

install -dvm 0700 /docker-tmp
install -dvm 0700 /docker-tmp/gitlab

"$docker" run \
  --name "$container" \
  --volumes-from "$persistence_container" \
  -v "/docker-tmp/gitlab:/backup" \
  --entrypoint /bin/bash \
  "$image" -c 'mv -v /home/git/data/backups/* /backup'

if [[ "$gitlab_isactive" == 'active' ]]; then
  "$systemctl" start docker-gitlab
fi

"$gz" -v /docker-tmp/gitlab/*.tar
"$mv" -v /docker-tmp/gitlab/*.tar.gz "$backup_dir"

lastret="$?"

set +e
exit "$?"
