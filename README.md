# NACOS E-Voting System

A PHP 8 / MySQL application for managing NACOS student elections. Includes role-based access (administrator, electoral officer, student), matric-number voter registration and verification, election scheduling/status management, positions and candidates, ballot submission, database-enforced one-vote-per-position rules, results, printable reports and audit history.

## Requirements

- XAMPP with PHP 8.1+ and MySQL/MariaDB
- Apache and MySQL enabled
- A modern browser; Bootstrap 5.3 is loaded from jsDelivr (internet access is required for the CDN assets)

## XAMPP installation

1. Extract `NACOS_EVoting_Complete.zip` into `C:\xampp\htdocs\NACOS_EVoting_Complete`.
2. Start **Apache** and **MySQL** in the XAMPP Control Panel.
3. Open `config/config.php`. The defaults target XAMPP's common local setup (`127.0.0.1`, database `nacos_evoting`, user `root`, blank password). Change these values if your MySQL credentials differ.
4. Visit `http://localhost/NACOS_EVoting_Complete/setup.php`.
5. Enter the first administrator name, email and a strong password (minimum 12 characters), then choose **Install application**. The installer creates the database/tables and administrator account.
6. Sign in at `http://localhost/NACOS_EVoting_Complete/index.php?page=login`.
7. **Delete or rename `setup.php` after successful installation.**

Alternatively, import `database/schema.sql` through phpMyAdmin. Then create the initial administrator using the installer (it will detect the existing schema and add the admin account).

## First-use workflow

1. Sign in as administrator.
2. Use **Management** to create an election with its start and end date/time.
3. Open **Positions** for that election, add each office, then add candidates and optional JPG/PNG/WEBP photos (max 2 MB) and manifestos.
4. Students register using their email and matriculation number. Registration does not automatically grant voting rights.
5. An administrator or electoral officer verifies each eligible student from the voter list in Management.
6. Verified students can submit a candidate application and manifesto from **Candidate applications**. An administrator approves or declines each application from **Candidate review**; a reason is required for a decline. Students can see their decision and may reapply after a decline.
7. Add any remaining candidates and positions, review all applications, then set the election status to **open**. The system prevents opening an election if a position has no approved candidate or candidate applications are still pending. Ballots include only approved candidates and also enforce the actual election start/end time.
8. Set the election to **closed** after voting ends, then view results and print or export reports. Student-facing results are available only after the election is closed.

### Updating an existing installation

The candidate-review feature adds fields and indexes to the `candidates` table only; it does not change user accounts, passwords, or login behavior. Before using this feature on an existing installation, back up the database and run `database/migrate_candidate_approval.sql` once in phpMyAdmin with `nacos_evoting` selected. Existing candidates are treated as approved so current elections keep their candidate list. New student applications start as pending.

## Default account

There is no hard-coded universal administrator password. The first admin account is created by `setup.php` from the email and password you choose during installation. This avoids shipping a known privileged credential.

## Security controls

- Passwords use PHP `password_hash()` / `password_verify()`.
- PDO prepared statements with emulated prepares disabled.
- CSRF token validation on all POST requests.
- Session ID rotation after successful login; HttpOnly and SameSite=Lax session cookies.
- Role checks on privileged routes; only administrators can approve or decline candidate applications.
- Matric-number uniqueness and voter verification before voting.
- Candidate eligibility review before ballots open; only approved candidates can appear on ballots and results.
- A unique database constraint on `(voter_id, position_id)` plus transaction-based ballot submission prevents duplicate votes for a position.
- Candidate image MIME validation and a 2 MB upload limit.
- Audit records for logins, registrations, election changes, voter verification and ballot submissions.
- HTML output escaping to mitigate stored/reflected XSS.

## Database / configuration

The schema is in `database/schema.sql`. Tables: `users`, `elections`, `positions`, `candidates`, `votes`, and `audit_logs`. Candidate applications record their applicant, decision, reviewer, review time, and optional note in the `candidates` table. Database connection settings are centralized in `config/config.php`. Candidate uploads are stored under `storage/uploads/`.

## Important operational notes

- This is an academic project starter intended for deployment in a controlled institution environment. Before a real high-stakes election, commission an independent security review and penetration test, use HTTPS, configure secure backups, restrict database privileges, harden Apache/PHP, and validate student eligibility against the institution's authoritative records.
- The application does not implement cryptographic ballot secrecy, coercion resistance, independent verifiability, or a formal election dispute process. The current audit trail records administrative actions and does not store ballot choices in the audit log; vote rows necessarily associate voter and position for duplicate enforcement. Do not represent this implementation as certified election infrastructure.
- “Real-time” tallies are computed from current vote records on each report request; there is no push/WebSocket update.
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
