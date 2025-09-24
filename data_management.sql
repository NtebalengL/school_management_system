-- school_admission_system.sql
-- DROP and CREATE a database and all tables for a School Admission System
-- Author: ChatGPT (GPT-5 Thinking mini)
-- Date: 2025-09-24

DROP DATABASE IF EXISTS school_admission;
CREATE DATABASE school_admission
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE school_admission;

-- =================================================
-- Table: campuses
-- Stores campus / school locations
-- =================================================
DROP TABLE IF EXISTS campuses;
CREATE TABLE campuses (
    campus_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(30),
    email VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =================================================
-- Table: programs
-- Programs/Grades/Courses the school offers
-- =================================================
DROP TABLE IF EXISTS programs;
CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    campus_id INT NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(200) NOT NULL,
    level ENUM('Primary','Middle','High','Undergraduate','Postgraduate') DEFAULT 'High',
    duration_months INT DEFAULT 12,
    capacity INT DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_program_code UNIQUE (campus_id, code),
    CONSTRAINT fk_programs_campus FOREIGN KEY (campus_id) REFERENCES campuses(campus_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: admission_officers
-- Staff handling applications
-- =================================================
DROP TABLE IF EXISTS admission_officers;
CREATE TABLE admission_officers (
    officer_id INT AUTO_INCREMENT PRIMARY KEY,
    campus_id INT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_officer_email UNIQUE (email),
    CONSTRAINT fk_officer_campus FOREIGN KEY (campus_id) REFERENCES campuses(campus_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: applicants
-- Applicant / student personal data
-- =================================================
DROP TABLE IF EXISTS applicants;
CREATE TABLE applicants (
    applicant_id INT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(50) NULL,
    first_name VARCHAR(120) NOT NULL,
    middle_name VARCHAR(120),
    last_name VARCHAR(120) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('M','F','Other') DEFAULT 'M',
    email VARCHAR(200) NOT NULL,
    phone VARCHAR(30),
    address VARCHAR(255),
    city VARCHAR(100),
    province VARCHAR(100),
    country VARCHAR(100) DEFAULT 'South Africa',
    application_reference VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_applicant_email UNIQUE (email),
    CONSTRAINT uq_applicant_nationalid UNIQUE (national_id),
    CONSTRAINT uq_application_reference UNIQUE (application_reference)
) ENGINE=InnoDB;

-- =================================================
-- Table: guardians
-- Parent/guardian info; one applicant may have many guardians
-- =================================================
DROP TABLE IF EXISTS guardians;
CREATE TABLE guardians (
    guardian_id INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT NOT NULL,
    relation ENUM('Mother','Father','Guardian','Other') DEFAULT 'Parent',
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(150),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_guardian_applicant FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: prior_qualifications
-- Previous schools / qualifications for applicant
-- =================================================
DROP TABLE IF EXISTS prior_qualifications;
CREATE TABLE prior_qualifications (
    qualification_id INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT NOT NULL,
    school_name VARCHAR(200),
    qualification_type VARCHAR(100),
    year_completed YEAR,
    grade_avg DECIMAL(4,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_priorqual_applicant FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: applications
-- Junction table: applicant applies to a program (many apps per applicant, many applicants per program)
-- =================================================
DROP TABLE IF EXISTS applications;
CREATE TABLE applications (
    application_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT NOT NULL,
    program_id INT NOT NULL,
    officer_id INT NULL, -- assigned admission officer
    applied_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    desired_start_date DATE,
    status ENUM('Submitted','Under Review','Interview Scheduled','Offered','Accepted','Rejected','Withdrawn') DEFAULT 'Submitted',
    status_updated_at TIMESTAMP NULL,
    total_fee DECIMAL(12,2) DEFAULT 0.00,
    payment_status ENUM('Unpaid','Partially Paid','Paid','Waived') DEFAULT 'Unpaid',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_applicant_program UNIQUE (applicant_id, program_id),
    CONSTRAINT fk_app_applicant FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_program FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_officer FOREIGN KEY (officer_id) REFERENCES admission_officers(officer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: application_documents
-- Documents uploaded for each application
-- =================================================
DROP TABLE IF EXISTS application_documents;
CREATE TABLE application_documents (
    document_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id BIGINT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_type VARCHAR(100),
    storage_path VARCHAR(500),
    uploaded_by VARCHAR(150),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INT NULL,
    verified_at TIMESTAMP NULL,
    CONSTRAINT fk_doc_application FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_doc_verified_by FOREIGN KEY (verified_by) REFERENCES admission_officers(officer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: interviews
-- Interview scheduling and outcome for an application
-- =================================================
DROP TABLE IF EXISTS interviews;
CREATE TABLE interviews (
    interview_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id BIGINT NOT NULL,
    scheduled_at DATETIME NOT NULL,
    mode ENUM('InPerson','Online','Phone') DEFAULT 'InPerson',
    venue VARCHAR(255),
    officer_id INT,
    result ENUM('Pending','Passed','Failed','Recommend Offer','No Show') DEFAULT 'Pending',
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_interview_app FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_interview_officer FOREIGN KEY (officer_id) REFERENCES admission_officers(officer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: entrance_exams
-- Records for exam results related to applications
-- =================================================
DROP TABLE IF EXISTS entrance_exams;
CREATE TABLE entrance_exams (
    exam_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id BIGINT NOT NULL,
    exam_name VARCHAR(150) NOT NULL,
    exam_date DATE,
    score DECIMAL(6,2),
    max_score DECIMAL(6,2),
    grade VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_app FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: payments
-- Payments made for applications (application fees, deposits, etc.)
-- =================================================
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id BIGINT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) DEFAULT 'ZAR',
    paid_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method ENUM('Card','EFT','Cash','MobileMoney','Cheque','Other') DEFAULT 'EFT',
    reference VARCHAR(200),
    received_by INT,
    notes TEXT,
    CONSTRAINT fk_payment_app FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payment_received_by FOREIGN KEY (received_by) REFERENCES admission_officers(officer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: program_requirements
-- Requirements for each program (one-to-many) and optional relation to a requirement master list
-- =================================================
DROP TABLE IF EXISTS requirement_templates;
CREATE TABLE requirement_templates (
    requirement_template_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(80) UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

DROP TABLE IF EXISTS program_requirements;
CREATE TABLE program_requirements (
    program_requirement_id INT AUTO_INCREMENT PRIMARY KEY,
    program_id INT NOT NULL,
    requirement_template_id INT,
    required BOOLEAN DEFAULT TRUE,
    notes TEXT,
    CONSTRAINT fk_progreq_program FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_progreq_template FOREIGN KEY (requirement_template_id) REFERENCES requirement_templates(requirement_template_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: offers
-- Official offers made to applicants
-- =================================================
DROP TABLE IF EXISTS offers;
CREATE TABLE offers (
    offer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id BIGINT NOT NULL,
    offered_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    offer_deadline DATE,
    amount_due DECIMAL(12,2) DEFAULT 0.00,
    accepted BOOLEAN DEFAULT FALSE,
    accepted_on TIMESTAMP NULL,
    offer_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_offer_app FOREIGN KEY (application_id) REFERENCES applications(application_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =================================================
-- Table: audit_logs
-- Lightweight audit / history for major actions (optional)
-- =================================================
DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(80) NOT NULL,
    entity_id VARCHAR(80) NOT NULL,
    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(150),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
) ENGINE=InnoDB;

-- =================================================
-- Useful Indexes
-- =================================================
CREATE INDEX idx_applicant_name ON applicants(last_name, first_name);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_programs_campus ON programs(campus_id);
CREATE INDEX idx_payments_app ON payments(application_id);

-- =================================================
-- Sample reference data (optional) - uncomment if you'd like
-- =================================================
/*
INSERT INTO campuses (name, address, city, province, postal_code, phone, email)
VALUES 
('Main Campus', '1 Education Road', 'Johannesburg', 'Gauteng', '2000', '+27-11-000-0000', 'info@school.edu'),
('West Campus', '42 Learner Ave', 'Midrand', 'Gauteng', '1685', '+27-11-111-1111', 'west@school.edu');

INSERT INTO programs (campus_id, code, name, level, duration_months, capacity, description)
VALUES
(1, 'KG-01', 'Kindergarten A', 'Primary', 12, 30, 'Reception-level program'),
(1, 'G01', 'Grade 1', 'Primary', 12, 40, 'Grade 1 curriculum'),
(1, 'NSC', 'National Senior Certificate', 'High', 24, 120, 'High school program for NSC');

INSERT INTO admission_officers (campus_id, first_name, last_name, email, phone)
VALUES (1, 'Alice', 'Mthembu', 'alice.m@school.edu', '+27-11-222-3333'),
(1, 'Sipho', 'Dlamini', 'sipho.d@school.edu', '+27-11-222-4444');
*/

-- End of script
