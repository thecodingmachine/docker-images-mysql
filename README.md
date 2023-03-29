[![Build Status](https://travis-ci.org/thecodingmachine/docker-images-mysql.svg?branch=master)](https://travis-ci.org/thecodingmachine/docker-images-mysql)

# Highly configurable MySQL images for Docker

This repository contains a set of **developer-friendly** MySQL images for Docker.

 - Built on top of the official MySQL images
 - You can change any MySQL settings using environment variables
 - Improved developer experience
 - With native support for backups in S3 / SSH / ... (TODO)

## Images

| Name                                                                                                                                                                                                                                        | MySQL version | Base distribution | Architectures  |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|-------------------|----------------|
| [thecodingmachine/mysql:5.7-v2](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)<br/>[ghcr.io/thecodingmachine/mysql:5.7-v2](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile) | `5.7.x`       | Oracle Linux      | AMD64          |
| [thecodingmachine/mysql:8.0-v2](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)<br/>[ghcr.io/thecodingmachine/mysql:8.0-v2](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile) | `8.0.x`       | Oracle Linux      | AMD64 / ARM64  |
| [thecodingmachine/mysql:5.7-v1](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)                                                                                                                             | `5.7.x`       | Debian Linux      | AMD64          |
| [thecodingmachine/mysql:8.0-v1](https://github.com/thecodingmachine/docker-images-mysql/blob/master/Dockerfile)                                                                                                                             | `8.0.x`       | Debian Linux      | AMD64          |

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

Out of the box, the mysql clients are configured to connect with the declared user (`MYSQL_USER`) on the declared database (`MYSQL_DATABASE`).

So, inside the container, no need to type:

```bash
$ mysql -uroot -pmypassword somedb
```

Simply type:

```bash
$ mysql
```

## Creating databases and users

This image is based on the official MySQL docker image. Therefore, it accepts the same environment variables to 
create a default user and a default database.

- `MYSQL_ROOT_PASSWORD`: This variable is mandatory and specifies the password that will be set for the MySQL `root` superuser account. In the above example, it was set to `my-secret-pw`.
- `MYSQL_DATABASE`: This variable is optional and allows you to specify the name of a database to be created on image startup. If a user/password was supplied (see below) then that user will be granted superuser access ([corresponding to `GRANT ALL`](http://dev.mysql.com/doc/en/adding-users.html)) to this database.
- `MYSQL_USER`, `MYSQL_PASSWORD`: These variables are optional, used in conjunction to create a new user and to set that user's password. This user will be granted superuser permissions (see above) for the database specified by the `MYSQL_DATABASE` variable. Both variables are required for a user to be created.
  Do note that there is no need to use this mechanism to create the root superuser, that user gets created by default with the password specified by the `MYSQL_ROOT_PASSWORD` variable.
- `MYSQL_ALLOW_EMPTY_PASSWORD`: This is an optional variable. Set to `yes` to allow the container to be started with a blank password for the root user. *NOTE*: Setting this variable to `yes` is not recommended unless you really know what you are doing, since this will leave your MySQL instance completely unprotected, allowing anyone to gain complete superuser access.
- `MYSQL_RANDOM_ROOT_PASSWORD`: This is an optional variable. Set to `yes` to generate a random initial password for the root user (using `pwgen`). The generated root password will be printed to stdout (`GENERATED ROOT PASSWORD: .....`).
- `MYSQL_ONETIME_PASSWORD`: Sets root (*not* the user specified in `MYSQL_USER`!) user as expired once init is complete, forcing a password change on first login.

In addition, this image adds the ability to create any number of users and any number of databases:

- `MYSQL_DATABASE_[XXX]`: These variables allow you to specify the name of a database to be created on image startup. If a matching user/password was supplied (see below) then that user will be granted superuser access ([corresponding to `GRANT ALL`](http://dev.mysql.com/doc/en/adding-users.html)) to this database.
  ```
  MYSQL_DATABASE_1=foo
  MYSQL_DATABASE_2=bar
  ```
  will create 2 databases (`foo` and `bar`)
  ```
  MYSQL_DATABASE_BAZ=baz
  MYSQL_USER_BAZ=fiz
  MYSQL_PASSWORD_BAZ=fiz
  ```
  will create one database `baz` with a user identified by `fiz/fiz`
- `MYSQL_USER_[XXX]`, `MYSQL_PASSWORD_[XXX]`: These variables allow you to create as many users as you want. If the "XXX" part of the environment variable
  matches a database, the user is granted superadmin access to that database.
- `MYSQL_USERGRANT_[XXX]`: These variables give rights to a user over one or many databases.
  ```
  MYSQL_DATABASE_BAZ=baz
  MYSQL_USER_FOO=foo
  MYSQL_PASSWORD_FOO=foo
  MYSQL_USERGRANT_FOO=baz # gives user "foo" admin access to database "baz"
  ```

## Local dumps

The images are shipped with [Supercronic](https://github.com/aptible/supercronic), a `crontab-compatible job runner, designed specifically to run in containers`.

This tool is very useful for dumping your databases in a scheduled way. For instance, you may configure your MySQL service like this in your Docker Compose stack:

```yaml
mysql:
 image: thecodingmachine/mysql:8.0-v1
 restart: unless-stopped
 command: --default-authentication-plugin=mysql_native_password
 environment:
   # Backups
   CRON_SCHEDULE_1: "0 3 * * *"
   CRON_COMMAND_1: "mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > /dumps/backup_$$(date +%Y-%m-%d-%H.%M.%S).sql"
   # MySQL
   MYSQL_ROOT_PASSWORD: "$MYSQL_ROOT_PASSWORD"
   MYSQL_DATABASE: "$MYSQL_DATABASE"
   MYSQL_USER: "$MYSQL_USER"
   MYSQL_PASSWORD: "$MYSQL_PASSWORD"
 volumes:
   - mysql_data:/var/lib/mysql
   - ./dumps:/dumps:rw
```

**Note:** the `$MYSQL_*` environment variables should come from a `.env` file in this case.

Using this configuration, your database `$MYSQL_DATABASE` will be dumped every day at 3 am (UTC) in your host folder `./dumps`.

## Storing dumps in Amazon S3 or a S3 compatible file system

The image comes with AWS CLI installed. This lets you upload images to Amazon S3 (or a compatible system like Google buckets).

In order to connect to S3, the easiest way is to set up these environment variables:

```
AWS_ACCESS_KEY_ID=[your key]
AWS_SECRET_ACCESS_KEY=[your secret]
AWS_DEFAULT_REGION=eu-west-1
```

Then, setting up a backup is as easy as:

```bash
aws s3 /dumps/backup.sql S3://my-s3-bucket/backup.sql
```
