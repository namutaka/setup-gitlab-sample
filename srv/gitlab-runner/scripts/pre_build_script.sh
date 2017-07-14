# pre_build_script.sh


#
# Usage:
#   setup_permission [--access-code] [DEST_DIR]
#
function setup_permission() {
  local requires_access_to_code=false
  if [ "$1" == "--access-code" ]; then
    requires_access_to_code=true
    shift
  fi
  local dest_path=$1

  local dest_dir=/srv/nginx/pages/$CI_PROJECT_PATH_SLUG/$dest_path
  mkdir -p $dest_dir

  cat <<EOS > $dest_dir/.gitlab-info.json
  {
    "project_id": $CI_PROJECT_ID,
    "requires_access_to_code": $requires_access_to_code
  }
EOS

}

function deploy_reviewapp() {
  local src_path=$1
  local dest_path=$2

  if [ -z "$src_path" -o -z "$dest_path" ]; then
    echo "[Error] Usage: deploy_reviewapp SRC_DIR DEST_DIR" >&2
    return 1
  fi

  dest_path=$CI_PROJECT_PATH_SLUG/$dest_path

  local base_path=/srv/nginx/pages
  mkdir -p "$base_path/$(dirname $dest_path)"
  rsync -av --delete "$src_path" "$base_path/$dest_path"

  echo "Deployed to: http://ci-docker1:8080/$dest_path"
}

function undeploy_reviewapp() {
  local dest_path=$1

  if [ -z "$dest_path" ]; then
    echo "[Error] Usage: undeploy_reviewapp DEST_DIR" >&2
    return 1
  fi

  rm -vrf "/srv/nginx/pages/$CI_PROJECT_PATH_SLUG/$dest_path"
}
