USE nacos_evoting;
-- Optional sample dataset. Import only into a fresh/test installation.
-- Demo student credentials: student1@nacos.test / NacosDemo2026!
INSERT IGNORE INTO users(full_name,email,matric_no,password_hash,role,department,level,is_verified) VALUES
('Ada Okafor','student1@nacos.test','CSC/2023/001','$2y$12$djDzsfpeLmq3GvX7XivXW.42J1etwaS3PQVPR0UwmAUAXgIKBEJEG','student','Computer Science','300',1),
('Tunde Bello','student2@nacos.test','CSC/2023/002','$2y$12$djDzsfpeLmq3GvX7XivXW.42J1etwaS3PQVPR0UwmAUAXgIKBEJEG','student','Computer Science','300',1),
('Zainab Musa','student3@nacos.test','CSC/2023/003','$2y$12$djDzsfpeLmq3GvX7XivXW.42J1etwaS3PQVPR0UwmAUAXgIKBEJEG','student','Software Engineering','200',1);
INSERT INTO elections(title,description,starts_at,ends_at,status,created_by)
SELECT 'NACOS Chapter Election (Sample)','Sample election for testing the complete voting workflow.',DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_ADD(NOW(),INTERVAL 30 DAY),'open',id FROM users WHERE role='admin' ORDER BY id LIMIT 1;
SET @eid=LAST_INSERT_ID();
INSERT INTO positions(election_id,title,description,sort_order) VALUES(@eid,'President','Chapter President',1),(@eid,'Vice President','Chapter Vice President',2),(@eid,'Secretary General','Administrative Secretary',3);
INSERT INTO candidates(position_id,full_name,department,manifesto)
SELECT id,'Ada Okafor','Computer Science','Prioritise student representation, practical workshops and transparent chapter finances.' FROM positions WHERE election_id=@eid AND title='President';
INSERT INTO candidates(position_id,full_name,department,manifesto)
SELECT id,'Tunde Bello','Information Technology','Build stronger industry partnerships and improve access to peer learning.' FROM positions WHERE election_id=@eid AND title='President';
INSERT INTO candidates(position_id,full_name,department,manifesto)
SELECT id,'Zainab Musa','Software Engineering','Improve communication, documentation and inclusive student participation.' FROM positions WHERE election_id=@eid AND title='Vice President';
INSERT INTO candidates(position_id,full_name,department,manifesto)
SELECT id,'Ibrahim Yusuf','Computer Science','Deliver timely records, clear meeting minutes and accessible announcements.' FROM positions WHERE election_id=@eid AND title='Secretary General';
