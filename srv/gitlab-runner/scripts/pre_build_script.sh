# pre_build_script.sh

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

