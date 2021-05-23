#!/bin/sh

# configure web content
test ! -z "$SERVER_NAME" && \
  sed -i -e "s/^my \$servername =.*;/my \$servername = \'${SERVER_NAME}\';/g" \
    /var/www/http/index.cgi

sed -i -e "s/^my \$largefonts =.*;/my \$largefonts = \'${LARGE_FONTS}\';/g" \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'${CACHE_TIME}\';/g" \
       /var/www/http/index.cgi

# configure vnStat
sed -i -e "s/^RateUnit .*/RateUnit ${RATE_UNIT}/g" /etc/vnstat.conf

# start httpd
thttpd -C /etc/thttpd.conf -p ${HTTP_PORT}
echo "thttpd started in port ${HTTP_PORT}"

# start vnStat daemon
vnstatd -n
