#!/bin/sh

# configure web content
sed -i -e "s/^my \$scriptname =.*;/my \$scriptname = \'index.cgi\';/g" \
       -e "s/^my \$servername =.*;/my \$servername = \'${SERVER_NAME}\';/g" \
       -e "s/^my \$largefonts =.*;/my \$largefonts = \'${LARGE_FONTS}\';/g" \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'${CACHE_TIME}\';/g" \
       /var/www/http/index.cgi

# start httpd
thttpd -C /etc/thttpd.conf -p ${HTTP_PORT}
echo "thttpd started in port ${HTTP_PORT}"

# start vnstat daemon
vnstatd -n
