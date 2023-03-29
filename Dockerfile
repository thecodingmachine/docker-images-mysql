ARG MYSQL_VERSION
FROM mysql:${MYSQL_VERSION}-oracle

LABEL authors="David Négrier <d.negrier@thecodingmachine.com>"


# |--------------------------------------------------------------------------
# | Install PHP
# |--------------------------------------------------------------------------
# |
# | Installs PHP (for the script handling environment variables)
# |

# MySQL 5.7 is using Oracle Linux 7 that uses yum.
# MySQL 8.0 is using Oracle Linux 8 that uses microdnf.
RUN if command -v yum &> /dev/null; then \
      yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
      && yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
      && yum -y install openssh-client unzip netcat tini yum-utils  \
      && yum install -y --enablerepo=remi-php80 php-cli \
      && yum -y clean all  \
      && rm -rf /var/cache;  \
    fi \
 && if command -v microdnf &> /dev/null; then  \
    microdnf --nodocs --setopt=install_weak_deps=0 install -y php-cli openssh-clients unzip nc  \
    && microdnf -y clean all  \
    && rm -rf /var/cache; \
  fi

COPY utils/generate_conf.php /usr/local/bin/generate_conf.php

# |--------------------------------------------------------------------------
# | SSH client
# |--------------------------------------------------------------------------
# |
# | Let's set-up the SSH client (for SSH backups)
# | We create an empty known_host file and we launch the ssh-agent
# |

RUN mkdir ~/.ssh && touch ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts && eval $(ssh-agent -s)

# |--------------------------------------------------------------------------
# | .bashrc updating
# |--------------------------------------------------------------------------
# |
# | Let's update the .bashrc to add nice aliases
# |

RUN { \
        echo "alias ls='ls --color=auto'"; \
        echo "alias ll='ls --color=auto -alF'"; \
        echo "alias la='ls --color=auto -A'"; \
        echo "alias l='ls --color=auto -CF'"; \
    } >> ~/.bashrc

# |--------------------------------------------------------------------------
# | Entrypoint
# |--------------------------------------------------------------------------
# |
# | Defines the entrypoint.
# |

# Add Tini (to be able to stop the container with ctrl-c.
# See: https://github.com/krallin/tini
#ENV TINI_VERSION v0.19.0
#RUN if [ "$(arch)" = "x86_64" ]; then architecture="amd64"; fi \
# && if [ "$(arch)" = "arm64" ]; then architecture="arm64"; fi \
# && curl https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${architecture} -o /tini
#RUN chmod +x /tini

# |--------------------------------------------------------------------------
# | Supercronic
# |--------------------------------------------------------------------------
# |
# | Supercronic is a drop-in replacement for cron (for containers).
# |

RUN if [ "$(arch)" = "x86_64" ]; then architecture="amd64"; fi \
 && if [ "$(arch)" = "aarch64" ]; then architecture="arm64"; fi \
 && SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-${architecture} \
 && SUPERCRONIC=supercronic-linux-${architecture} \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# |--------------------------------------------------------------------------
# | AWS CLI
# |--------------------------------------------------------------------------
# |
# | Useful for S3 uploads of backups
# |

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf aws \
 && rm awscliv2.zip

COPY utils/generate_cron.php /usr/local/bin/generate_cron.php
COPY utils/startup_commands.php /usr/local/bin/startup_commands.php
COPY utils/create_databases.php /usr/local/bin/create_databases.php
COPY utils/tcm-docker-entrypoint.sh /usr/local/bin/tcm-docker-entrypoint.sh
COPY utils/docker-entrypoint-tiny.sh /usr/local/bin/docker-entrypoint-tiny.sh

RUN mv /usr/sbin/mysqld /usr/sbin/mysqld_orig
COPY utils/mysqld /usr/sbin/mysqld

#RUN touch /var/lib/mysql/you_forgot_to_mount_var_lib_mysql

HEALTHCHECK --interval=10s --retries=12 CMD ["mysqladmin", "ping"]

# TODO: even with tini, we cannot kill the process with ctrl-c!
#ENTRYPOINT ["/tini", "-g", "-s", "--", "/usr/local/bin/docker-entrypoint-tiny.sh"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-tiny.sh"]
CMD ["mysqld"]
