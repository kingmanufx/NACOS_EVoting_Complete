<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
if (!in_array('--confirm-after-backup', $argv, true)) {
    fwrite(STDERR, "Back up the database, then rerun with --confirm-after-backup.\n");
    exit(1);
}

$config = require __DIR__.'/../config/config.php';
$db = $config['db'];
foreach ($argv as $argument) {
    if (str_starts_with($argument, '--database=')) {
        $database = substr($argument, strlen('--database='));
        if (!preg_match('/\A[a-zA-Z0-9_]+\z/', $database)) throw new RuntimeException('Invalid database name.');
        $db['name'] = $database;
    }
}
$pdo = new PDO(
    "mysql:host={$db['host']};dbname={$db['name']};charset={$db['charset']}",
    $db['user'],
    $db['pass'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$legacyTables = ['admins','audit_logs','candidates','elections','positions','students','voter_status','votes'];
$existingTables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
$existingTables = array_fill_keys($existingTables, true);
$requiredUserColumns = ['id','full_name','email','matric_no','password_hash','role','is_verified','is_active'];
$userColumns = $pdo->query('SHOW COLUMNS FROM users')->fetchAll(PDO::FETCH_COLUMN);
if (array_diff($requiredUserColumns, $userColumns)) {
    throw new RuntimeException('The existing users table does not match the project account schema; migration stopped without changing it.');
}

$backupTables = [];
$hasLegacyBackup = false;
foreach ($legacyTables as $table) {
    $backup = 'legacy_'.$table.'_pre_project';
    if (isset($existingTables[$backup])) $hasLegacyBackup = true;
    if (isset($existingTables[$table])) $backupTables[$table] = $backup;
}

if (!$hasLegacyBackup) {
    if (!isset($existingTables['admins'], $existingTables['students'], $existingTables['voter_status'])) {
        throw new RuntimeException('This database is not the detected legacy layout; use the project-schema migration instead.');
    }
    if (in_array('email_verified_at', $userColumns, true)) {
        throw new RuntimeException('This database appears partially migrated; inspect it before continuing.');
    }
    foreach ($backupTables as $table => $backup) {
        if (isset($existingTables[$backup])) throw new RuntimeException("Archive table {$backup} already exists.");
        $count = (int)$pdo->query("SELECT COUNT(*) FROM `{$table}`")->fetchColumn();
        if ($count !== 0) {
            throw new RuntimeException("Table {$table} contains {$count} rows. Migration stopped to avoid losing or mis-mapping data.");
        }
    }

    $foreignKeys = $pdo->prepare(
        'SELECT TABLE_NAME,CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
         WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL'
    );
    $foreignKeys->execute();
    foreach ($foreignKeys->fetchAll(PDO::FETCH_ASSOC) as $foreignKey) {
        if (!isset($backupTables[$foreignKey['TABLE_NAME']])) continue;
        $table = str_replace('`','``',$foreignKey['TABLE_NAME']);
        $constraint = str_replace('`','``',$foreignKey['CONSTRAINT_NAME']);
        $pdo->exec("ALTER TABLE `{$table}` DROP FOREIGN KEY `{$constraint}`");
    }
    $renames = [];
    foreach ($backupTables as $table => $backup) {
        $renames[] = '`'.str_replace('`','``',$table).'` TO `'.str_replace('`','``',$backup).'`';
    }
    if ($renames) $pdo->exec('RENAME TABLE '.implode(', ',$renames));
} elseif ($backupTables) {
    throw new RuntimeException('Both legacy and project tables are present; migration stopped to avoid overwriting data.');
}

$schema = file_get_contents(__DIR__.'/schema.sql');
if ($schema === false) throw new RuntimeException('Unable to read database/schema.sql.');
foreach (array_filter(array_map('trim', explode(';', $schema))) as $statement) {
    if (preg_match('/^(CREATE DATABASE|USE)\b/i', $statement)) continue;
    $pdo->exec($statement);
}

$userColumns = $pdo->query('SHOW COLUMNS FROM users')->fetchAll(PDO::FETCH_COLUMN);
if (!in_array('email_verified_at', $userColumns, true)) {
    $pdo->exec('ALTER TABLE users ADD COLUMN email_verified_at DATETIME NULL AFTER is_active');
    $pdo->exec('UPDATE users SET email_verified_at=NOW() WHERE email_verified_at IS NULL');
}

$accountCount = (int)$pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
fwrite(STDOUT, "Migration complete. Preserved {$accountCount} user accounts and their password hashes; existing accounts are email-verified.\n");
fwrite(STDOUT, "Legacy empty tables were retained with the legacy_*_pre_project prefix. Remove setup.php after checking the application.\n");
