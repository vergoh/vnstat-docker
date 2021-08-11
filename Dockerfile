FROM alpine:latest

LABEL author="Teemu Toivola"
LABEL repository.git="https://github.com/vergoh/vnstat-docker"
LABEL repository.docker="https://hub.docker.com/r/vergoh/vnstat"

ENV HTTP_PORT=8586
ENV HTTP_LOG=/dev/stdout
ENV LARGE_FONTS=0
ENV CACHE_TIME=1
ENV RATE_UNIT=1
ENV PAGE_REFRESH=0

RUN apk add --no-cache gcc musl-dev make perl gd gd-dev sqlite-libs sqlite-dev lighttpd && \
  wget https://humdi.net/vnstat/vnstat-latest.tar.gz && \
  tar zxvf vnstat-latest.tar.gz && \
  cd vnstat-*/ && \
  ./configure --prefix=/usr --sysconfdir=/etc && \
  make && make install && \
  cd .. && rm -fr vnstat* && \
  apk del gcc pkgconf gd-dev make musl-dev sqlite-dev

COPY vnstat.cgi /var/www/localhost/htdocs/index.cgi
COPY vnstat-json.cgi /var/www/localhost/htdocs/json.cgi

VOLUME /var/lib/vnstat
EXPOSE ${HTTP_PORT}

COPY start.sh /
CMD /start.sh
