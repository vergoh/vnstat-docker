#!/bin/sh

if [ "${HTTP_PORT}" -eq 0 ] && [ "${RUN_VNSTATD}" -ne 1 ]; then
  echo "Error: Invalid configuration, HTTP_PORT cannot be 0 when RUN_VNSTATD is not 1"
  exit 1
fi

# configure web content
test ! -z "$SERVER_NAME" && \
  sed -i -e "s/^my \$servername =.*;/my \$servername = \'${SERVER_NAME}\';/g" \
    /var/www/localhost/htdocs/index.cgi

test -d "/dev/shm" && \
  sed -i -e "s/^my \$tmp_dir =.*/my \$tmp_dir = \'\/dev\/shm\/vnstatcgi\';/g" \
    /var/www/localhost/htdocs/index.cgi

sed -i -e "s/^my \$largefonts =.*;/my \$largefonts = \'${LARGE_FONTS}\';/g" \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'${CACHE_TIME}\';/g" \
       -e "s/^my \$darkmode =.*/my \$darkmode = \'${DARK_MODE}\';/g" \
       -e "s/^my \$pagerefresh =.*/my \$pagerefresh = \'${PAGE_REFRESH}\';/g" \
       /var/www/localhost/htdocs/index.cgi

# configure vnStat
sed -i -e 's/^;RateUnit /RateUnit /g' -e "s/^RateUnit .*/RateUnit ${RATE_UNIT}/g" \
       -e 's/^;Interface /Interface /g' -e "s/^Interface .*/Interface \"${INTERFACE}\"/g" \
       -e 's/^;InterfaceOrder /InterfaceOrder /g' -e "s/^InterfaceOrder .*/InterfaceOrder ${INTERFACE_ORDER}/g" \
       -e 's/^;QueryMode /QueryMode /g' -e "s/^QueryMode .*/QueryMode ${QUERY_MODE}/g" \
       /etc/vnstat.conf

# configure and start httpd if port > 0
if [ "${HTTP_PORT}" -gt 0 ]; then

  echo 'server.compat-module-load = "disable"
server.modules = ("mod_indexfile", "mod_cgi", "mod_staticfile", "mod_accesslog", "mod_rewrite")
server.username      = "lighttpd"
server.groupname     = "lighttpd"
server.document-root = "/var/www/localhost/htdocs"
server.pid-file      = "/run/lighttpd.pid"
server.indexfiles = ("index.cgi")
url.rewrite-once = ("^/metrics" => "/metrics.cgi")
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

  if [ "${RUN_VNSTATD}" -eq 1 ]; then
    lighttpd-angel -f /etc/lighttpd/lighttpd.conf && \
      echo "lighttpd started on ${HTTP_BIND:-*}:${HTTP_PORT}"
  else
    echo "lighttpd starting on ${HTTP_BIND:-*}:${HTTP_PORT}"
    exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
  fi
fi

if [ -n "${EXCLUDE_PATTERN}" ]; then
  if [ "${RUN_VNSTATD}" -eq 1 ]; then
    echo "Interface exclude pattern: ${EXCLUDE_PATTERN}"

    # if database doesn't exist, create and populate it with interfaces not matching the pattern
    vnstat --dbiflist 1 >/dev/null 2>&1 || \
      { vnstatd --user vnstat --group vnstat --initdb ; vnstat --iflist ; vnstat --iflist 1 | grep -vE "${EXCLUDE_PATTERN}" | xargs -r -n 1 vnstat --add -i ; }

    # if database exists, remove possible excluded interfaces
    vnstat --dbiflist 1 | grep -E "${EXCLUDE_PATTERN}" | xargs -r -n 1 vnstat --remove --force -i
  fi
fi

# start vnStat daemon
if [ "${RUN_VNSTATD}" -eq 1 ]; then
  exec vnstatd -n -t --user vnstat --group vnstat
fi
