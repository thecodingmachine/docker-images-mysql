ARG MYSQL_VERSION
FROM mysql:${MYSQL_VERSION}

LABEL authors="David Négrier <d.negrier@thecodingmachine.com>"


# |--------------------------------------------------------------------------
# | Install PHP
# |--------------------------------------------------------------------------
# |
# | Installs PHP (for the script handling environment variables)
# |

RUN apt-get update && apt-get install -y --no-install-recommends php-cli openssh-client

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
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# |--------------------------------------------------------------------------
# | Supercronic
# |--------------------------------------------------------------------------
# |
# | Supercronic is a drop-in replacement for cron (for containers).
# |

RUN if [ -n "$INSTALL_CRON" ]; then \
 SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.9/supercronic-linux-amd64 \
 && SUPERCRONIC=supercronic-linux-amd64 \
 && SUPERCRONIC_SHA1SUM=5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85 \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && sudo mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && sudo ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic; \
 fi;


COPY utils/generate_cron.php /usr/local/bin/generate_cron.php
COPY utils/startup_commands.php /usr/local/bin/startup_commands.php
COPY utils/tcm-docker-entrypoint.sh /usr/local/bin/tcm-docker-entrypoint.sh
COPY utils/docker-entrypoint-tiny.sh /usr/local/bin/docker-entrypoint-tiny.sh

RUN mv /usr/sbin/mysqld /usr/sbin/mysqld_orig
COPY utils/mysqld /usr/sbin/mysqld

RUN touch /var/lib/mysql/you_forgot_to_mount_var_lib_mysql

# TODO: even with tini, we cannot kill the process with ctrl-c!
ENTRYPOINT ["/tini", "-g", "-s", "--", "/usr/local/bin/docker-entrypoint-tiny.sh"]
CMD ["mysqld"]
