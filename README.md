# NACOS E-Voting System

A PHP 8 / MySQL application for managing NACOS student elections. Includes role-based access, email verification and password recovery, candidate applications and review, election scheduling, anonymous aggregate vote tallies, participation tracking, results, printable reports and audit history.

## Requirements

- XAMPP with PHP 8.1+ and MySQL/MariaDB
- Apache and MySQL enabled
- PHP `mail()` configured to send mail through the hosting server
- A modern browser; Bootstrap 5.3 is loaded from jsDelivr (internet access is required for the CDN assets)

## XAMPP installation

1. Extract `NACOS_EVoting_Complete.zip` into `C:\xampp\htdocs\NACOS_EVoting_Complete`.
2. Start **Apache** and **MySQL** in the XAMPP Control Panel.
3. Open `config/config.php`. The defaults target XAMPP's common local setup (`127.0.0.1`, database `nacos_evoting`, user `root`, blank password). Set `base_url` to the public application URL and `mail_from` to an address accepted by your mail server. Configure PHP `mail()` in the active `php.ini` / hosting environment.
4. Visit `http://localhost/NACOS_EVoting_Complete/setup.php`.
5. Enter the first administrator name, email and a strong password (minimum 12 characters), then choose **Install application**. The installer creates the database/tables and administrator account.
6. Sign in at `http://localhost/NACOS_EVoting_Complete/index.php?page=login`.
7. **Delete or rename `setup.php` after successful installation.**

Alternatively, import `database/schema.sql` through phpMyAdmin. Then create the initial administrator using the installer (it will detect the existing schema and add the admin account).

## First-use workflow

1. Sign in as administrator.
2. Use **Management** to create an election with its start and end date/time.
3. Open **Positions** for that election, add each office, then add candidates and optional JPG/PNG/WEBP photos (max 2 MB) and manifestos.
4. Students register using their email and matriculation number, then verify their email from the link sent to them. Email verification does not automatically grant voting rights.
5. An administrator or electoral officer verifies each eligible student from the voter list in Management.
6. Verified students can submit a candidate application and manifesto from **Candidate applications**. An administrator approves or declines each application from **Candidate review**; a reason is required for a decline. Students can see their decision and may reapply after a decline.
7. Add any remaining candidates and positions, review all applications, then set the election status to **open**. The system prevents opening an election if a position has no approved candidate or candidate applications are still pending. Ballots include only approved candidates and also enforce the actual election start/end time.
8. Each eligible student submits one complete ballot for the election. Results are hidden until an administrator or officer closes the election, then may be viewed, printed or exported.

### Updating an existing installation

Always back up the database first.

- **Legacy database with the alternate layout previously found in this workspace:** its election/candidate tables use a different layout from the project source. Run `C:\xampp\php\php.exe database\migrate_project_database.php --confirm-after-backup` from the project folder. The script proceeds only when those legacy application tables are empty; it archives them under `legacy_*_pre_project`, creates the project schema, preserves the existing `users` table and password hashes, and marks existing accounts email-verified so their current logins continue to work. It stops rather than guessing if legacy tables contain data.
- **An existing installation already using this project's earlier schema:** run `database/migrate_candidate_approval.sql` once, then `database/migrate_secret_ballots_and_email.sql` once. The second migration preserves aggregate results and participation, then removes the old voter-linked ballot rows. This unlinking cannot be undone. Keep any pre-migration backup access-restricted; it contains the old voter-choice links.
- New accounts must verify their email before signing in. Existing accounts are not asked to re-verify. Password reset and verification links expire and can be requested from the sign-in page.

## Default account

There is no hard-coded universal administrator password. The first admin account is created by `setup.php` from the email and password you choose during installation. This avoids shipping a known privileged credential.

## Security controls

- Passwords use PHP `password_hash()` / `password_verify()`.
- PDO prepared statements with emulated prepares disabled.
- CSRF token validation on all POST requests.
- Session ID rotation after successful login; HttpOnly and SameSite=Lax session cookies.
- Role checks on privileged routes; only administrators can approve or decline candidate applications.
- Single-use, expiring email verification and password-reset tokens are stored as hashes; PHP mail delivery must be configured on the server.
- Matric-number uniqueness and voter verification before voting.
- Candidate eligibility review before ballots open; only approved candidates can appear on ballots and results.
- Voter participation is stored separately from candidate tallies. The `votes` table stores aggregate counts, not individual ballots or voter IDs; a unique `(election_id, voter_id)` participation key prevents repeat submissions.
- Complete ballots are submitted transactionally and results/exports stay hidden until the election is closed.
- Candidate image MIME validation and a 2 MB upload limit.
- Audit records for logins, registrations, election changes, voter verification and ballot submissions.
- HTML output escaping to mitigate stored/reflected XSS.

## Database / configuration

The schema is in `database/schema.sql`. Tables include `users`, `account_tokens`, `elections`, `positions`, `candidates`, `voter_participation`, aggregate `votes`, and `audit_logs`. Candidate applications record their applicant, decision, reviewer, review time, and optional note in `candidates`. Database and mail-link settings are centralized in `config/config.php`. Candidate uploads are stored under `storage/uploads/`.

## Important operational notes

- This is an academic project starter intended for deployment in a controlled institution environment. Before a real high-stakes election, commission an independent security review and penetration test, use HTTPS, configure secure backups, restrict database privileges, harden Apache/PHP, and validate student eligibility against the institution's authoritative records.
- Ballot choices are stored only as aggregate tallies, with voter participation in a separate table. This removes direct voter-to-choice records, but it is not cryptographic ballot secrecy: privileged operators could still tamper with tallies or attempt timing-based inference. It does not provide coercion resistance, independent verifiability, or a formal election dispute process. Do not represent this implementation as certified election infrastructure.
- Tallies update as ballots are submitted but are not shown to users until the election is closed; there is no push/WebSocket update.
- The application intentionally does not permit students to change a submitted selection. Test the complete election lifecycle using test accounts before an actual election.

## Troubleshooting

- **Database connection error:** check that MySQL is running and the values in `config/config.php` match your XAMPP installation.
- **404 / CSS not loading:** ensure the extracted folder name matches the URL path and Apache is serving `htdocs`.
- **Uploads fail:** ensure `storage/uploads` is writable by the Apache/PHP process.
- **PDO MySQL missing:** enable `pdo_mysql` in the active `php.ini`, restart Apache and confirm with `php -m`.
- **Wrong schedule:** election dates are interpreted in `Africa/Lagos` by default; change the timezone in `config/config.php` if needed.

## Project structure

```text
NACOS_EVoting_Complete/
├── app/bootstrap.php
├── config/config.php
├── database/schema.sql
├── public/assets/{style.css,app.js}
├── storage/uploads/
├── index.php
├── setup.php
└── README.md
```

### Optional sample records

After installation, import `database/sample_data.sql` in phpMyAdmin if you want sample verified student accounts and a sample open election. Demo student sign-in: `student1@nacos.test` / `NacosDemo2026!` (the same demo password is used for the other sample students). These are test-only credentials; do not import sample records into a live election database. The sample election is scheduled open immediately and ends 30 days after import.

Election reports include CSV download as well as browser printing.
