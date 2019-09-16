<?php
/**
 * A very simple script in charge of generating the MySQL configuration based on environment variables.
 * The script is run on each start of the container.
 */

// Reading environment variables from $_SERVER (because $_ENV is not necessarily populated, depending on variables_order directive):

$context = $argv[1];
if ($context !== 'server' && $context !== 'client') {
    throw new \BadFunctionCallException('You must pass server or client as first parameter: generate_conf.php server|client');
}

/** @var array<string, array<int, string>> $params */
$lines = [];

foreach ($_SERVER as $key => $value) {
    if (!is_string($value)) {
        continue;
    }
    $match = preg_match('/([A-Z]*)_INI_(.*)/', $key, $matches);
    if ($match === 1) {
        $section = strtolower($matches[1]);
        $param = strtolower($matches[2]);

        // If MYSQLD_INI_[number]_XXX: let's drop the number part. Some mysql options can be configured several times
        $match = preg_match('/\\d+_.*/', $param);
        if ($match === 1) {
            $pos = strpos($param, '_');
            $param = substr($param, $pos+1);
        }

        $param = str_replace('__', '-', $param);

        // Let's protect the value if this is a string.
        /*if (!is_numeric($value) && $iniParam !== 'error_reporting') {
            $value = '"'.str_replace('"', '\\"', $value).'"';
        }*/
        $lines[$section][] = $param . '=' .$value."\n";
    }
}

if ($context === 'server' && isset($lines['mysqld'])) {
    echo "\n[mysqld]\n";
    echo implode('', $lines['mysqld']);
} elseif ($context === 'client') {
    unset($lines['mysqld']);
    // Let's put "client" first (because it is more generic)
    if (isset($lines['client'])) {
        echo "[client]\n";
        echo implode('', $lines['client']);
        unset($lines['client']);
    }

    foreach ($lines as $section => $options) {
        echo "\n[".$section."]\n";
        echo implode('', $options);
    }
}
