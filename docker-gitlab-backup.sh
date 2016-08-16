set -e
set -x

if [[ "$EUID" != 0 ]]; then
  echo 'Please run this script as root.' >&2
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

tmp_container="TMP_gitlab-aws"

set +e
docker create \
    --name "$tmp_container" \
    --entrypoint '/bin/true' \
    --volume '/home/git/data/backups' \
    busybox
set -e

docker run \
  --name "$container" \
  -e              "GITLAB_HOST=$host" \
  -e              "GITLAB_SECRETS_DB_KEY_BASE=${secrets_db_key}" \
  --cpu-shares    "$cpu_share" \
  -m              "$memory" \
  --memory-swap   "$memory_swap" \
  --volumes-from  "$persistence_container" \
  --volumes-from  "$tmp_container" \
  --link          "${postgresql_container}:postgresql" \
  --link          "${redis_container}:redisio" \
  "$image" app:rake gitlab:backup:create

set +e
docker stop "$container"
docker rm "$container"
set -e

docker run -i --rm \
    --name gitlab-aws \
    --volumes-from "$tmp_container" \
    --volumes-from gitlab-aws-credentials \
    --entrypoint bash \
    cgswong/aws -s <<END
set -e
ls /home/git/data/backups/*.tar | xargs -n1 gzip
ls /home/git/data/backups | xargs -n1 -I% aws s3 cp \
    --sse \
    --storage-class STANDARD_IA \
    '/home/git/data/backups/%' 's3://groventure-gitlab-backups/%'
END

set +e
docker rm "$tmp_container"
docker rm gitlab-aws
set -e

lastret="$?"

if [[ "$gitlab_isactive" == 'active' ]]; then
  systemctl start docker-gitlab
fi

set +e
exit "$?"
