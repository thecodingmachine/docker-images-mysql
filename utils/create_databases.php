<?php

/**
 * @var array{0: user, 1: password}
 */
$users = [];
$dbs = [];
$grants = [];

foreach ($_SERVER as $key => $value) {
    if (!is_string($value)) {
        continue;
    }
    $match = preg_match('/MYSQL_USER_(.*)/', $key, $matches);
    if ($match === 1) {
        $dbId = $matches[1];

        if (!isset($_SERVER['MYSQL_PASSWORD_'.$dbId])) {
            error_log('Missing environment variable '.'MYSQL_PASSWORD_'.$dbId);
            exit(1);
        }

        $user = $value;
        $password = $_SERVER['MYSQL_PASSWORD_'.$dbId];

        $users[] = [$user, $password];
    }

    $match = preg_match('/MYSQL_DATABASE_(.*)/', $key, $matches);
    if ($match === 1) {
        $dbId = $matches[1];

        $dbs[] = $value;

        if (isset($_SERVER['MYSQL_USER_'.$dbId])) {
            $grants[$_SERVER['MYSQL_USER_'.$dbId]][$value] = $value;
        }
    }

    $match = preg_match('/MYSQL_USERGRANT_(.*)/', $key, $matches);
    if ($match === 1) {
        $dbId = $matches[1];

        $grantedDbs = explode(',', $value);
        $grantedDbs = array_map('trim', $grantedDbs);

        if (!isset($_SERVER['MYSQL_USER_'.$dbId])) {
            error_log('Missing environment variable '.'MYSQL_USER_'.$dbId);
            exit(1);
        }

        foreach ($grantedDbs as $grantDb) {
            $grants[$_SERVER['MYSQL_USER_'.$dbId]][$grantDb] = $grantDb;
        }
    }
}


foreach ($users as [$user, $password]) {
    echo "CREATE USER '$user'@'%' IDENTIFIED BY '".addslashes($password)."' ;\n";
}

foreach ($dbs as $db) {
    echo "CREATE DATABASE IF NOT EXISTS `$db` ;\n";
}

foreach ($grants as $user => $dbsGranted) {
    foreach ($dbsGranted as $db) {
        echo "GRANT ALL ON `$db`.* TO '$user'@'%' ;\n";
    }
}

echo "FLUSH PRIVILEGES;\n";

// TODO: WRITE THIS FILE IN THE STARTUP FILES AUTOMATICALLY
// TODO: WRITE THIS FILE IN THE STARTUP FILES AUTOMATICALLY
// TODO: WRITE THIS FILE IN THE STARTUP FILES AUTOMATICALLY
// TODO: WRITE THIS FILE IN THE STARTUP FILES AUTOMATICALLY
