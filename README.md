[![Build Status](https://travis-ci.org/thecodingmachine/docker-images-mysql.svg?branch=master)](https://travis-ci.org/thecodingmachine/docker-images-mysql)

# WORK IN PROGRESS - NOT READY FOR USE YET

# Highly configurable MySQL images for Docker

This repository contains a set of **developer-friendly** MySQL images for Docker.

 - Built on top of the official MySQL images
 - You can change any MySQL settings using environment variables
 - Improved developer experience
 - With native support for backups in S3 / SSH / ... (TODO)

## Images



| Name                                                                    | MySQL version                  | type |variant | NodeJS version  | Size 
|-------------------------------------------------------------------------|------------------------------|------|--------|-----------------|------
| [thecodingmachine/mysql:5.7-v1](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)             | `5.7.x` | [![](https://images.microbadger.com/badges/image/thecodingmachine/mysql:5.7-v1.svg)](https://microbadger.com/images/thecodingmachine/mysql:5.7-v1)
| [thecodingmachine/mysql:8.0-v1](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)             | `8.0.x` | [![](https://images.microbadger.com/badges/image/thecodingmachine/mysql:8.0-v1.svg)](https://microbadger.com/images/thecodingmachine/mysql:8.0-v1)

Note: we do not tag patch releases of MySQL, only minor versions. You will find one image for MySQL 5.7, one for MySQL 8.0, 
but no tagged image for MySQL 5.7.12. This is because we believe you have no valid reason to ask explicitly for 5.7.12.
When 5.7.13 is out, you certainly want to upgrade automatically to this patch release since patch releases contain only bugfixes.

Images are automatically updated when a new patch version of MySQL is released, so the MySQL 8.0 image will always contain 
the most up-to-date version of the MySQL 8.0.x branch. If you want to automatically update your images on your production
environment, you can use tools like [watchtower](https://github.com/v2tec/watchtower) that will monitor new versions of
the images and update your environment on the fly.

## Usage

These images are based on the [official MySQL image](https://hub.docker.com/_/mysql/) and can be used in a similar fashion.

Example:

```bash
$ docker run -it --rm --name my-database -v my_data:/var/lib/mysql thecodingmachine/mysql:8.0-v1
```

## Setting MySQL options

You can customize any MySQL options editable in the `my.cnf` using [SECTION]_INI_[OPTION] environment variables.

```yml
version: '3'
services:
  my_app:
    image: thecodingmachine/mysql:8.0-v1
    environment:
      # set the parameter max_allowed_packet=8M in the [mysqld] section
      MYSQLD_INI_MAX_ALLOWED_PACKET: 8M
```

Absolutely all MySQL options can be set.

Internally, the image will map all environment variables starting with `MYSQL_INI_`.

If your `my.cnf` option contains a dash ("-"), you must replace it with a double underscore ("__").

Environment variable name             | Option name in `my.cnf` 
--------------------------------------|------------------------------
MYSQLD_INI_MAX_ALLOWED_PACKET         | max_allowed_packet (in [mysqld] section)
MYSQLD_INI_INNODB__BUFFER__POOL__SIZE | innodb-buffer-pool-size (in [mysqld] section) 

You can set environment variables for client programs (like `mysqldump` or `mysql`) by prefixing the environment variable
with `CLIENT` (or with the program name).

Environment variable name             | Option name in `my.cnf` 
--------------------------------------|------------------------------
CLIENT_INI_MAX_ALLOWED_PACKET         | max_allowed_packet (in [client] section)
MYSQLDUMP_INI_ALL__DATABASES          | all-databases (in [mysqldump] section) 

## Better developer experience

Out of the box, the mysql clients are configured to log with the declared user on the declared database.

So, inside the container, no need to type:

```bash
$ mysql -uroot -pmypassword somedb
```

Simply type:

```bash
$ mysql
```

