
function setup_runners() {

# GitlabのRunnersページのRegistration Token
TOKEN=3F_o4XgJ8x4n_Nj5oVfB
docker-compose exec gitlab-runner \
  gitlab-runner register \
  --non-interactive \
  --name docker-runner \
  --url http://gitlab/ci \
  --registration-token ${TOKEN} \
  --executor docker \
  --limit 3 \
  --docker-image maven \
  --tag-list docker

docker-compose exec gitlab-runner \
  gitlab-runner register \
  --non-interactive \
  --name docker-shell-runner \
  --url http://gitlab/ci \
  --registration-token ${TOKEN} \
  --executor shell \
  --limit 3 \
  --tag-list shell

}


function setup_nginx() {

local cont_id=$(docker-compose ps -q gitlab-runner)
docker cp $0 ${cont_id}:/
docker-compose exec gitlab-runner \
  bash /gitlab_setup.sh setup_nginx_innser

}


function setup_nginx_innser() {

sudo apt-get update
sudo apt-get install -y nginx
sudo mkdir -p /srv/nginx/pages
sudo chown -R gitlab-runner /srv/nginx/pages

cat <<"EOF" | sudo tee /etc/nginx/sites-available/dynamic-pages
server {
    listen 8080;
    #server_name ~^(www\.)?(?<sname>.+?).my.domain.com$;
    #root /srv/nginx/pages/$sname/public;
    root /srv/nginx/pages/;

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.html;
    }

    access_log /var/log/nginx/pages-access.log;
    error_log  /var/log/nginx/pages-error.log debug;
}
EOF
sudo ln -s /etc/nginx/sites-{available,enabled}/dynamic-pages
sudo service nginx restart

}


$1

