FROM nginx

RUN apt-get update \
  && apt-get install -y supervisor curl
  # && apt-get clean
RUN mkdir -p /var/log/supervisor

# install oauth2_proxy
RUN curl -sSL https://github.com/bitly/oauth2_proxy/releases/download/v2.2/oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz \
  | tar -zxC /usr/local/bin --strip=1

COPY nginx.conf /etc/nginx/nginx.conf
COPY oauth2_proxy.cfg /etc/oauth2_proxy.cfg
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /srv/nginx/pages

RUN echo 'Hello <a href="/test">test</a><br>' \
    '<a href="/oauth2/sign_in">logout</a>' \
    > /srv/nginx/pages/index.html

CMD ["/usr/bin/supervisord"]

