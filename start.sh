#!/bin/sh

# configure web content
sed -i -e '/{ interface =>/d' \
       -e "s/^my \$scriptname =.*;/my \$scriptname = \'index.cgi\';/g" \
       -e "s/^my \$servername =.*;/my \$servername = \'${SERVER_NAME}\';/g" \
       -e "s/^my \$largefonts =.*;/my \$largefonts = \'${LARGE_FONTS}\';/g" \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'${CACHE_TIME}\';/g" \
       /var/www/http/index.cgi
sed -i -e 's:my @interfaces = (.*:my @interfaces = (\n);:g' /var/www/http/json.cgi

IFLIST_CMD="vnstat --iflist 1"
test -f /var/lib/vnstat/vnstat.db && IFLIST_CMD="vnstat --dbiflist 1"

$IFLIST_CMD | sort -r | while read i
do
  sed -i -e "s:my @graphs = (:my @graphs = (\n\t{ interface => \'$i\' },:g" /var/www/http/index.cgi
  sed -i -e "s:my @interfaces = (:my @interfaces = (\n\t\'$i\':g" /var/www/http/json.cgi
done

# start httpd
thttpd -C /etc/thttpd.conf -p ${HTTP_PORT}

# start vnstat daemon
vnstatd -n
