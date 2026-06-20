#!/bin/sh

if [ "${HTTP_PORT}" -eq 0 ] && [ "${RUN_VNSTATD}" -ne 1 ] && [ -z "${APPRISE_URLS}" ]; then
  echo "Error: Invalid configuration, HTTP_PORT cannot be 0 when RUN_VNSTATD is not 1 and APPRISE_URLS is not set"
  exit 1
fi

NOTIFY_CRONTAB="/etc/vnstat-notify.crontab"

notify_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

configure_notification_scheduler() {
  if [ -z "${APPRISE_URLS}" ]; then
    echo "Error: APPRISE_URLS must not be empty"
    exit 1
  fi

  if [ -z "${NOTIFY_CRON}" ]; then
    echo "Error: NOTIFY_CRON must be set when APPRISE_URLS is set"
    exit 1
  fi

  if [ "$(printf '%s' "${NOTIFY_CRON}" | wc -w | tr -d '[:space:]')" -ne 5 ]; then
    echo "Error: NOTIFY_CRON must contain exactly 5 space-separated fields"
    exit 1
  fi

  if [ -z "${NOTIFY_VNSTAT_ARGS}" ]; then
    echo "Error: NOTIFY_VNSTAT_ARGS must be set when APPRISE_URLS is set"
    exit 1
  fi

  {
    printf "APPRISE_URLS=%s\n" "$(notify_quote "${APPRISE_URLS}")"
    printf "NOTIFY_VNSTAT_ARGS=%s\n" "$(notify_quote "${NOTIFY_VNSTAT_ARGS}")"
    printf "NOTIFY_TITLE=%s\n" "$(notify_quote "${NOTIFY_TITLE:-vnStat}")"
    printf "SERVER_NAME=%s\n" "$(notify_quote "${SERVER_NAME:-}")"
  } >/etc/vnstat-notify.env

  chown vnstat:vnstat /etc/vnstat-notify.env
  chmod 600 /etc/vnstat-notify.env

  printf '%s su vnstat -s /bin/sh -c /usr/local/bin/vnstat-notify.sh\n' "${NOTIFY_CRON}" >"${NOTIFY_CRONTAB}"
  supercronic -test "${NOTIFY_CRONTAB}" || exit 1
}

start_notification_scheduler() {
  if [ "${RUN_VNSTATD}" -eq 0 ] && [ "${HTTP_PORT}" -eq 0 ]; then
    echo "Notification scheduler starting (cron-only mode, ${NOTIFY_CRON})"
    exec supercronic -no-reap -split-logs "${NOTIFY_CRONTAB}"
  else
    echo "Notification scheduler starting (${NOTIFY_CRON})"
    supercronic -no-reap -split-logs "${NOTIFY_CRONTAB}" &
  fi
}

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
       -e "s/^my \$indeximagesperrow =.*/my \$indeximagesperrow = \'${INDEX_IMAGES_PER_ROW}\';/g" \
       -e "s/^my \$indeximageoutput =.*/my \$indeximageoutput = \'${INDEX_IMAGE_OUTPUT}\';/g" \
       -e "s/^my \$indexshowninterfaces =.*/my \$indexshowninterfaces = \'${INDEX_SHOWN_INTERFACES}\';/g" \
       -e "s/^my \$indexhiddeninterfaces =.*/my \$indexhiddeninterfaces = \'${INDEX_HIDDEN_INTERFACES}\';/g" \
       -e "s/^my \$usecfglengthonsingleimagepages =.*/my \$usecfglengthonsingleimagepages = \'1\';/g" \
       /var/www/localhost/htdocs/index.cgi

# configure vnStat
test ! -z "${RATE_UNIT}" && {
  echo "Warning: Environment variable RATE_UNIT has been deprecated, please start using VNSTAT_RateUnit instead" ;
  sed -i -e 's/^;RateUnit /RateUnit /g' -e "s/^RateUnit .*/RateUnit ${RATE_UNIT}/g" /etc/vnstat.conf ;
  echo "Configuration 'RateUnit' set with value '${RATE_UNIT}'" ;
}
test ! -z "${INTERFACE_ORDER}" && {
  echo "Warning: Environment variable INTERFACE_ORDER has been deprecated, please start using VNSTAT_InterfaceOrder instead" ;
  sed -i -e 's/^;InterfaceOrder /InterfaceOrder /g' -e "s/^InterfaceOrder .*/InterfaceOrder ${INTERFACE_ORDER}/g" /etc/vnstat.conf ;
  echo "Configuration 'InterfaceOrder' set with value '${INTERFACE_ORDER}'" ;
}
test ! -z "${QUERY_MODE}" && {
  echo "Warning: Environment variable QUERY_MODE has been deprecated, please start using VNSTAT_QueryMode instead" ;
  sed -i -e 's/^;QueryMode /QueryMode /g' -e "s/^QueryMode .*/QueryMode ${QUERY_MODE}/g" /etc/vnstat.conf ;
  echo "Configuration 'QueryMode' set with value '${QUERY_MODE}'" ;
}
test ! -z "${INTERFACE}" && {
  echo "Warning: Environment variable INTERFACE has been deprecated, please start using VNSTAT_Interface instead" ;
  sed -i -e 's/^;Interface /Interface /g' -e "s/^Interface .*/Interface ${INTERFACE}/g" /etc/vnstat.conf ;
  echo "Configuration 'Interface' set with value '${INTERFACE}'" ;
}

sed -i -e "s/^;List5Mins .*/List5Mins 60/g" \
       -e "s/^;ListHours .*/ListHours 48/g" \
       -e "s/^;ListDays .*/ListDays 60/g" \
       -e "s/^;ListMonths .*/ListMonths 24/g" \
       -e "s/^;ListYears .*/ListYears 0/g" \
       -e "s/^;ListTop .*/ListTop 20/g" \
       /etc/vnstat.conf

env | grep -E '^VNSTAT_' | cut -d_ -f2- | while read -r e
do
  key=$(echo "${e}" | cut -d= -f1)
  value=$(echo "${e}" | cut -d= -f2-)
  test -z "${key}" && continue
  test -z "${value}" && continue
  sed -i -e "s/^;${key} /${key} /g" -e "s/^${key} .*/${key} ${value}/g" /etc/vnstat.conf
  grep -qE "^${key} " /etc/vnstat.conf && echo "Configuration '${key}' set with value '${value}'"
done

# configure and start notification scheduler if enabled
if [ -n "${APPRISE_URLS}" ]; then
  configure_notification_scheduler
  start_notification_scheduler
fi

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
  exec vnstatd --nodaemon --timestamp --user vnstat --group vnstat
fi
