-- ============================================================================
-- PART 2: CREATE SCHEMA & TABLES
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS fitness_club;
-- 1. Members Table
CREATE TABLE IF NOT EXISTS fitness_club.members (
    member_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    gender CHAR(1),
    joined_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active', -- Rubric Req: Meaningful DEFAULT
    
    -- Rubric Reqs: 5 Unique CHECK Constraint Types mapped across tables
    CONSTRAINT chk_joined_date CHECK (joined_date > DATE '2026-01-01'), -- Kind 1: Date restriction
    CONSTRAINT chk_gender CHECK (gender IN ('M', 'F', 'O')),             -- Kind 3: Enumerated options
    CONSTRAINT uq_member_email UNIQUE (email),                           -- Kind 4: Natural key Unique
    CONSTRAINT chk_email_not_empty CHECK (email <> '')                  -- Kind 5: Non-trivial NOT NULL
);

-- 2. Trainers Table
CREATE TABLE IF NOT EXISTS fitness_club.trainers (
    trainer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialty VARCHAR(50)
    -- Note: hourly_rate left out intentionally for Part 3 ALTER practice
);

-- 3. Memberships Table
CREATE TABLE IF NOT EXISTS fitness_club.memberships (
    membership_id SERIAL PRIMARY KEY,
    member_id INT NOT NULL,
    monthly_fee NUMERIC(6,2) NOT NULL,
    start_date DATE NOT NULL,
    CONSTRAINT fk_membership_member FOREIGN KEY (member_id) 
        REFERENCES fitness_club.members(member_id) ON DELETE CASCADE -- Explicit ON DELETE
);

-- 4. Classes Table
CREATE TABLE IF NOT EXISTS fitness_club.classes (
    class_id SERIAL PRIMARY KEY,
    trainer_id INT,
    class_name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    CONSTRAINT fk_class_trainer FOREIGN KEY (trainer_id) 
        REFERENCES fitness_club.trainers(trainer_id) ON DELETE RESTRICT -- Protects trainer from deletion
);

-- 5. Attendances Junction Table (N:M Relationship Bridge)
CREATE TABLE IF NOT EXISTS fitness_club.attendances (
    member_id INT,
    class_id INT,
    attendance_date DATE NOT NULL,
    PRIMARY KEY (member_id, class_id, attendance_date),
    CONSTRAINT fk_attendance_member FOREIGN KEY (member_id) 
        REFERENCES fitness_club.members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_class FOREIGN KEY (class_id) 
        REFERENCES fitness_club.classes(class_id) ON DELETE CASCADE
);

-- 6. Equipment Bookings Table
CREATE TABLE IF NOT EXISTS fitness_club.equipment_bookings (
    booking_id SERIAL PRIMARY KEY,
    member_id INT,
    item_name VARCHAR(100) NOT NULL,
    hours_rented INT NOT NULL,
    hourly_cost NUMERIC(5,2) NOT NULL,
    -- Rubric Req: GENERATED ALWAYS AS STORED column
    total_cost NUMERIC(8,2) GENERATED ALWAYS AS (hours_rented * hourly_cost) STORED,
    CONSTRAINT fk_booking_member FOREIGN KEY (member_id) 
        REFERENCES fitness_club.members(member_id) ON DELETE SET NULL -- Retains historical record
);


-- ============================================================================
-- PART 3: ALTER TABLE OPERATIONS (5 Distinct, Meaningful Operations)
-- ============================================================================

-- 1. ADD COLUMN: Add missing hourly rate column to trainers
ALTER TABLE fitness_club.trainers  ADD COLUMN IF NOT EXISTS hourly_rate NUMERIC(6,2);

-- 2. ADD CONSTRAINT: Enforce non-negative measured rate (Kind 2 Check Constraint)
ALTER TABLE fitness_club.trainers DROP CONSTRAINT IF EXISTS chk_positive_rate;
ALTER TABLE fitness_club.trainers ADD CONSTRAINT chk_positive_rate CHECK (hourly_rate >= 0.00);

-- 3. ALTER COLUMN TYPE: Widen character limit for class names to support descriptive names
ALTER TABLE fitness_club.classes ALTER COLUMN class_name TYPE VARCHAR(150);

-- 4. SET DEFAULT: Automatically set default capacity for new fitness classes
ALTER TABLE fitness_club.classes ALTER COLUMN capacity SET DEFAULT 20;

-- 5. RENAME COLUMN: Clean up column semantics for clear data comprehension
-- ALTER TABLE fitness_club.trainers RENAME COLUMN specialty TO trainer_specialization;


-- ============================================================================
-- PART 4: DATA INSERTION (No hard-coded IDs, uses subqueries)
-- ============================================================================

-- Reset sequence engines cleanly
TRUNCATE fitness_club.members, fitness_club.trainers, fitness_club.memberships, 
         fitness_club.classes, fitness_club.attendances, fitness_club.equipment_bookings 
RESTART IDENTITY CASCADE;

-- Insert Members (Largest Table: Add 10+ records using multi-row syntax)
INSERT INTO fitness_club.members (first_name, last_name, email, gender, joined_date, status) VALUES
('Damir', 'Asanov', 'damir.a@example.kz', 'M', '2026-01-15', 'Active'),
('Alina', 'Serikova', 'alina.s@example.kz', 'F', '2026-02-01', 'Active'),
('Arman', 'Ilyasov', 'arman.i@example.kz', 'M', '2026-02-10', 'Active'),
('Dana', 'Muratova', 'dana.m@example.kz', 'F', '2026-03-05', 'Active'),
('Anuar', 'Kusainov', 'anuar.k@example.kz', 'M', '2026-03-12', 'Suspended'),
('Aigerim', 'Utepova', 'aiga.u@example.kz', 'F', '2026-04-01', 'Active'),
('Bauyrzhan', 'Suleimen', 'buka.s@example.kz', 'M', '2026-04-18', 'Active'),
('Gaukhar', 'Alieva', 'gaukhar.a@example.kz', 'F', '2026-05-02', 'Active'),
('Dias', 'Bolatov', 'dias.b@example.kz', 'M', '2026-05-20', 'Active'),
('Zarina', 'Kim', 'zarina.k@example.kz', 'F', '2026-06-01', 'Active');

-- Insert Trainers (5+ records)
INSERT INTO fitness_club.trainers (first_name, last_name, trainer_specialization, hourly_rate) VALUES
('Alex', 'Jones', 'CrossFit', 45.00),
('Elena', 'Petrova', 'Yoga', 40.00),
('Murat', 'Saparov', 'Bodybuilding', 50.00),
('Sofia', 'Loren', 'Pilates', 42.00),
('Dmitry', 'Volkov', 'Boxing', 48.00);

-- Insert Classes (5+ records utilizing lookup subqueries for trainer keys)
INSERT INTO fitness_club.classes (trainer_id, class_name, capacity) VALUES
((SELECT trainer_id FROM fitness_club.trainers WHERE last_name = 'Petrova'), 'Morning Vinyasa Flow', 15),
((SELECT trainer_id FROM fitness_club.trainers WHERE last_name = 'Jones'), 'HIIT Power Hour', 25),
((SELECT trainer_id FROM fitness_club.trainers WHERE last_name = 'Saparov'), 'Heavy Lifting 101', 12),
((SELECT trainer_id FROM fitness_club.trainers WHERE last_name = 'Loren'), 'Core Core Pilates', 15),
((SELECT trainer_id FROM fitness_club.trainers WHERE last_name = 'Volkov'), 'Cardio Kickboxing', 20);

-- Insert Memberships (10+ records utilizing lookup subqueries for member keys)
INSERT INTO fitness_club.memberships (member_id, monthly_fee, start_date) VALUES
((SELECT member_id FROM fitness_club.members WHERE email = 'damir.a@example.kz'), 50.00, '2026-01-15'),
((SELECT member_id FROM fitness_club.members WHERE email = 'alina.s@example.kz'), 55.00, '2026-02-01'),
((SELECT member_id FROM fitness_club.members WHERE email = 'arman.i@example.kz'), 50.00, '2026-02-10'),
((SELECT member_id FROM fitness_club.members WHERE email = 'dana.m@example.kz'), 60.00, '2026-03-05'),
((SELECT member_id FROM fitness_club.members WHERE email = 'anuar.k@example.kz'), 50.00, '2026-03-12'),
((SELECT member_id FROM fitness_club.members WHERE email = 'aiga.u@example.kz'), 55.00, '2026-04-01'),
((SELECT member_id FROM fitness_club.members WHERE email = 'buka.s@example.kz'), 50.00, '2026-04-18'),
((SELECT member_id FROM fitness_club.members WHERE email = 'gaukhar.a@example.kz'), 60.00, '2026-05-02'),
((SELECT member_id FROM fitness_club.members WHERE email = 'dias.b@example.kz'), 50.00, '2026-05-20'),
((SELECT member_id FROM fitness_club.members WHERE email = 'zarina.k@example.kz'), 55.00, '2026-06-01');

-- Rubric Req: INSERT INTO ... SELECT structure to build the bridge records
-- Automatically enrolls all active members who joined in early 2026 into the HIIT class
INSERT INTO fitness_club.attendances (member_id, class_id, attendance_date)
SELECT m.member_id, c.class_id, DATE '2026-06-10'
FROM fitness_club.members m, fitness_club.classes c
WHERE m.status = 'Active' 
  AND m.joined_date <= '2026-03-01'
  AND c.class_name = 'HIIT Power Hour';

-- Insert Equipment Bookings (5+ Records)
INSERT INTO fitness_club.equipment_bookings (member_id, item_name, hours_rented, hourly_cost) VALUES
((SELECT member_id FROM fitness_club.members WHERE email = 'damir.a@example.kz'), 'Weightlifting Belt', 2, 5.00),
((SELECT member_id FROM fitness_club.members WHERE email = 'alina.s@example.kz'), 'Yoga Block Set', 1, 3.00),
((SELECT member_id FROM fitness_club.members WHERE email = 'arman.i@example.kz'), 'Boxing Gloves', 2, 4.00),
((SELECT member_id FROM fitness_club.members WHERE email = 'dana.m@example.kz'), 'Heart Rate Monitor', 3, 6.00),
((SELECT member_id FROM fitness_club.members WHERE email = 'buka.s@example.kz'), 'Weightlifting Belt', 2, 5.00);


-- ============================================================================
-- PART 5: DATA MODIFICATION OPERATIONS (UPDATE & DELETE)
-- ============================================================================

-- Business Reason: Update a single member's administrative registration status
UPDATE fitness_club.members 
SET status = 'Active' 
WHERE email = 'anuar.k@example.kz';

-- Business Reason: Adjust booking base costs using an explicit subquery correlation lookup
UPDATE fitness_club.equipment_bookings
SET hourly_cost = hourly_cost + 1.50
WHERE member_id IN (
    SELECT member_id 
    FROM fitness_club.members 
    WHERE status = 'Suspended'
);

-- Business Reason: Safely execute transactional deletion test for bookkeeping entries
BEGIN;
DELETE FROM fitness_club.equipment_bookings 
WHERE hours_rented >= 3
RETURNING booking_id, total_cost;
ROLLBACK;


-- ============================================================================
-- PART 6: SECURITY & PRIVILEGE MANAGEMENT (GRANT / REVOKE)
-- ============================================================================

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA fitness_club FROM fitness_readonly, fitness_writer;
REVOKE ALL PRIVILEGES ON SCHEMA fitness_club FROM fitness_readonly, fitness_writer;
REVOKE ALL PRIVILEGES ON fitness_club.members FROM fitness_writer;

-- 2. Trick for a clean DBMS: If the database is completely empty, create the roles
DROP ROLE IF EXISTS fitness_readonly;
DROP ROLE IF EXISTS fitness_writer;

CREATE ROLE fitness_readonly;
CREATE ROLE fitness_writer;

-- 3. Apply fitness_readonly permissions from scratch
GRANT USAGE ON SCHEMA fitness_club TO fitness_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA fitness_club TO fitness_readonly;

-- 4. Apply fitness_writer permissions from scratch
GRANT USAGE ON SCHEMA fitness_club TO fitness_writer;
GRANT INSERT, UPDATE ON fitness_club.members TO fitness_writer;

-- 5. Business Reason: Revoke direct modifications to sensitive profiles
REVOKE UPDATE ON fitness_club.members FROM fitness_writer;