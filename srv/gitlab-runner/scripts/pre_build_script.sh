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
function deploy_review() {
  local src_path=$1

  mkdir -p /srv/nginx/pages/$CI_PROJECT_PATH_SLUG
  rsync -av --delete $src_path \
    /srv/nginx/pages/$CI_PROJECT_PATH_SLUG/$CI_BUILD_REF_SLUG
}

function undeploy_review() {
  local src_path=$1

  rm -rf \
    /srv/nginx/pages/$CI_PROJECT_PATH_SLUG/$CI_BUILD_REF_SLUG
}


#export REVIEW_APP_URL=http://127.0.0.1:8080/$CI_PROJECT_PATH_SLUG-$CI_BUILD_REF_SLUG

