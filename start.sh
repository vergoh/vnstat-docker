#!/bin/sh

# configure web content
sed -i -e '/{ interface =>/d' \
       -e "s/^my \$cachetime =.*/my \$cachetime = \'1\';/g" \
       -e "s/^my \$scriptname =.*;/my \$scriptname = \'index.cgi\';/g" /var/www/http/index.cgi
sed -i -e 's:my @interfaces = (.*:my @interfaces = (\n);:g' /var/www/http/json.cgi

vnstat --iflist 1 | sort -r | while read i
do
  sed -i -e "s:my @graphs = (:my @graphs = (\n\t{ interface => \'$i\' },:g" /var/www/http/index.cgi
  sed -i -e "s:my @interfaces = (:my @interfaces = (\n\t\'$i\':g" /var/www/http/json.cgi
done

# start httpd
thttpd -C /etc/thttpd.conf -p ${HTTP_PORT}

# start vnstat daemon
vnstatd -n
