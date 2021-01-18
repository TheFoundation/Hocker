#!/bin/bash
echo "::TOOLKIT"
test -f /var/www/.toolkit || mkdir -p /var/www/.toolkit
test -f /var/www/.toolkit/sql.php || wget -q -O /var/www/.toolkit/sql.php -c $(curl -skLv https://github.com/vrana/adminer/releases/latest|grep php|grep releases/download|grep [0-9]/adminer.*[0-9].php|cut -d\" -f2|sed 's/^/https:\/\/github.com/g' 2>/dev/shm/startlogs/toolkit.sql.version.log ) &>/dev/shm/startlogs/toolkit.sql.log && echo put sql mgmt adminer 


which apk && apk update && apk add git

echo -n "phpmemcached"
cd /var/www/.toolkit; git clone https://github.com/elijaa/phpmemcachedadmin.git /var/www/.toolkit/cache/ |tr -d '\n'
echo "PD9waHAKcmV0dXJuIGFycmF5ICgKICAnc3RhdHNfYXBpJyA9PiAnU2VydmVyJywKICAnc2xhYnNfYXBpJyA9PiAnU2VydmVyJywKICAnaXRlbXNfYXBpJyA9PiAnU2VydmVyJywKICAnZ2V0X2FwaScgPT4gJ1NlcnZlcicsCiAgJ3NldF9hcGknID0+ICdTZXJ2ZXInLAogICdkZWxldGVfYXBpJyA9PiAnU2VydmVyJywKICAnZmx1c2hfYWxsX2FwaScgPT4gJ1NlcnZlcicsCiAgJ2Nvbm5lY3Rpb25fdGltZW91dCcgPT4gJzEnLAogICdtYXhfaXRlbV9kdW1wJyA9PiAnMTAwJywKICAncmVmcmVzaF9yYXRlJyA9PiAyLAogICdtZW1vcnlfYWxlcnQnID0+ICc4MCcsCiAgJ2hpdF9yYXRlX2FsZXJ0JyA9PiAnOTAnLAogICdldmljdGlvbl9hbGVydCcgPT4gJzAnLAogICdmaWxlX3BhdGgnID0+ICdUZW1wLycsCiAgJ3NlcnZlcnMnID0+IAogIGFycmF5ICgKICAgICdEZWZhdWx0JyA9PiAKICAgIGFycmF5ICgKICAgICAgJ21lbWNhY2hlZDoxMTIxMScgPT4gCiAgICAgIGFycmF5ICgKICAgICAgICAnaG9zdG5hbWUnID0+ICdtZW1jYWNoZWQnLAogICAgICAgICdwb3J0JyA9PiAnMTEyMTEnLAogICAgICApLAogICAgKSwKICApLAopOwo=" |base64 -d > /var/www/.toolkit/cache/Config/Memcache.php
chown www-data:www-data /var/www/.toolkit/cache/Temp
chmod g+w /var/www/.toolkit/cache/Temp
