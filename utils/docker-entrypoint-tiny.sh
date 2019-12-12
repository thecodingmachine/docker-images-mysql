#!/bin/bash

set -e

php /usr/local/bin/generate_conf.php server > /etc/mysql/conf.d/z_generated_conf_server.cnf
rm -f /etc/mysql/conf.d/z_generated_conf_client.cnf
touch /etc/mysql/conf.d/z_generated_conf_client.cnf
chown mysql:mysql /etc/mysql/conf.d/z_generated_conf_client.cnf

php /usr/local/bin/generate_cron.php > /tmp/generated_crontab
chmod 0644 /tmp/generated_crontab

# If generated_crontab is not empty, start supercronic
if [[ -s /tmp/generated_crontab ]]; then
    supercronic /tmp/generated_crontab &
fi

php /usr/local/bin/startup_commands.php | bash

# Initialize a RAMDRIVE if CI environment variable is set
#if [[ -n "$CI" ]]; then
#  sudo mount -t tmpfs -o rw,size=2G tmpfs /var/lib/mysql
#fi

/usr/local/bin/docker-entrypoint.sh "$@"
