FROM alpine:latest

ENV HTTP_PORT=8586
ENV SERVER_NAME="Some Server"
ENV LARGE_FONTS=0
ENV CACHE_TIME=1

RUN apk add --no-cache gcc musl-dev make perl gd gd-dev sqlite-libs sqlite-dev thttpd && \
  sed -i -e '/chroot/d' -e '/vhost/d' /etc/thttpd.conf && \
  wget https://humdi.net/vnstat/vnstat-latest.tar.gz && \
  tar zxvf vnstat-latest.tar.gz && \
  cd vnstat-*/ && \
  ./configure --prefix=/usr --sysconfdir=/etc && \
  make && make install && \
  cp -v examples/vnstat.cgi /var/www/http/index.cgi && \
  cp -v examples/vnstat-json.cgi /var/www/http/json.cgi && \
  cd .. && rm -fr vnstat* && \
  apk del gcc pkgconf gd-dev make musl-dev sqlite-dev

VOLUME /var/lib/vnstat
EXPOSE ${HTTP_PORT}

COPY start.sh /
CMD /start.sh
