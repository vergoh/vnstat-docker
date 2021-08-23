#!/bin/sh

# configure web content
test ! -z "$SERVER_NAME" && \
  sed -i -e "s/^my \$servername =.*;/my \$servername = \'${SERVER_NAME}\';/g" \
    /var/www/localhost/htdocs/index.cgi

test -d "/dev/shm" && \
  sed -i -e "s/^my \$tmp_dir =.*/my \$tmp_dir = \'\/dev\/shm\/vnstatcgi\';/g" \
    /var/www/localhost/htdocs/index.cgi

sed -i -e "s/^my \$largefonts =.*;/my \$largefonts = \'${LARGE_FONTS}\';/g" \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'${CACHE_TIME}\';/g" \
       -e "s/^my \$pagerefresh =.*/my \$pagerefresh = \'${PAGE_REFRESH}\';/g" \
       /var/www/localhost/htdocs/index.cgi

# configure vnStat
sed -i -e "s/^RateUnit .*/RateUnit ${RATE_UNIT}/g" /etc/vnstat.conf

# configure and start httpd if port > 0
if [ "${HTTP_PORT}" -gt 0 ]; then

  echo 'server.compat-module-load = "disable"
server.modules = ("mod_indexfile", "mod_cgi", "mod_staticfile", "mod_accesslog")
server.username      = "lighttpd"
server.groupname     = "lighttpd"
server.document-root = "/var/www/localhost/htdocs"
server.pid-file      = "/run/lighttpd.pid"
server.indexfiles = ("index.cgi")
cgi.assign = (".cgi" => "/usr/bin/perl")' >/etc/lighttpd/lighttpd.conf
  echo "server.port = ${HTTP_PORT}" >>/etc/lighttpd/lighttpd.conf
  if [ -n "${HTTP_BIND}" ] && [ "${HTTP_BIND}" != "*" ]; then
    echo "server.bind = \"${HTTP_BIND}\"" >>/etc/lighttpd/lighttpd.conf
  fi

  if [ "${HTTP_LOG}" = "/dev/stdout" ]; then
    exec 3>&1
    chmod a+rwx /dev/fd/3
    echo 'accesslog.filename = "/dev/fd/3"' >>/etc/lighttpd/lighttpd.conf
    echo 'server.errorlog = "/dev/fd/3"' >>/etc/lighttpd/lighttpd.conf
  else
    echo "accesslog.filename = \"${HTTP_LOG}\"" >>/etc/lighttpd/lighttpd.conf
    echo "server.errorlog = \"${HTTP_LOG}\"" >>/etc/lighttpd/lighttpd.conf
  fi

  lighttpd-angel -f /etc/lighttpd/lighttpd.conf && \
    echo "lighttpd started on ${HTTP_BIND:-*}:${HTTP_PORT}"
fi

# start vnStat daemon
exec vnstatd -n --user vnstat --group vnstat
