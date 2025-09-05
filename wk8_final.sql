-- College Management System

-- 1) Create Database
CREATE DATABASE IF NOT EXISTS college_mgmt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE college_mgmt;

-- 2) Safety settings
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- 3) Core Reference Tables

-- Departments (One Department -> Many Programs, Courses, Instructors)
CREATE TABLE departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Programs (One Program -> Many Students)
CREATE TABLE programs (
  program_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  level ENUM('Certificate','Diploma','Undergraduate','Postgraduate') NOT NULL,
  duration_years TINYINT UNSIGNED NOT NULL DEFAULT 3,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_programs_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Terms/Semesters
CREATE TABLE terms (
  term_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(30) NOT NULL UNIQUE, -- e.g., '2025 Term 1' or '2025-01'
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CONSTRAINT chk_terms_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

-- 4) People

-- Instructors
CREATE TABLE instructors (
  instructor_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  staff_no VARCHAR(30) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  hire_date DATE,
  status ENUM('Active','On Leave','Inactive') NOT NULL DEFAULT 'Active',
  CONSTRAINT fk_instructors_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Students (One Program -> Many Students)
CREATE TABLE students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  program_id INT NOT NULL,
  student_no VARCHAR(30) NOT NULL UNIQUE, -- Admission/Reg No
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  dob DATE,
  gender ENUM('Male','Female','Other','Prefer not to say') DEFAULT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  enrollment_year YEAR NOT NULL,
  status ENUM('Active','Deferred','Graduated','Withdrawn') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_students_program
    FOREIGN KEY (program_id) REFERENCES programs(program_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Student Profile (1-to-1 with Students)
CREATE TABLE student_profiles (
  student_id INT PRIMARY KEY,
  national_id VARCHAR(30) UNIQUE,
  address_line1 VARCHAR(150),
  address_line2 VARCHAR(150),
  city VARCHAR(100),
  postal_code VARCHAR(20),
  guardian_name VARCHAR(150),
  guardian_phone VARCHAR(30),
  emergency_contact VARCHAR(150),
  CONSTRAINT fk_student_profiles_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5) Academic Structure

-- Courses (One Department -> Many Courses)
CREATE TABLE courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  code VARCHAR(20) NOT NULL UNIQUE, -- e.g., CSC101
  title VARCHAR(200) NOT NULL,
  credits TINYINT UNSIGNED NOT NULL,
  description TEXT,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_courses_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Class offerings (a specific course taught in a specific term, possibly multiple sections)
CREATE TABLE class_offerings (
  offering_id INT AUTO_INCREMENT PRIMARY KEY,
  course_id INT NOT NULL,
  term_id INT NOT NULL,
  instructor_id INT NOT NULL,
  section VARCHAR(10) NOT NULL DEFAULT 'A',
  capacity INT NOT NULL DEFAULT 50,
  location VARCHAR(100),
  UNIQUE KEY uq_offering (course_id, term_id, section),
  CONSTRAINT fk_offerings_course
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_offerings_term
    FOREIGN KEY (term_id) REFERENCES terms(term_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_offerings_instructor
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Enrollments (Many-to-Many: Students <-> Class Offerings)
CREATE TABLE enrollments (
  enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  offering_id INT NOT NULL,
  enrolled_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  status ENUM('Enrolled','Dropped','Completed') NOT NULL DEFAULT 'Enrolled',
  UNIQUE KEY uq_student_offering (student_id, offering_id),
  INDEX idx_enrollments_student (student_id),
  INDEX idx_enrollments_offering (offering_id),
  CONSTRAINT fk_enrollments_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_enrollments_offering
    FOREIGN KEY (offering_id) REFERENCES class_offerings(offering_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Grades (1-to-1 with each Enrollment; adjust if multiple graded components are needed)
CREATE TABLE grades (
  grade_id INT AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT NOT NULL UNIQUE,
  grade_letter ENUM('A','B','C','D','E','F','I') NOT NULL,
  grade_points DECIMAL(3,2) NOT NULL, -- e.g., 4.00 for A
  remarks VARCHAR(255),
  graded_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT fk_grades_enrollment
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Attendance (per class session)
CREATE TABLE attendance (
  attendance_id INT AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT NOT NULL,
  session_date DATE NOT NULL,
  status ENUM('Present','Absent','Late','Excused') NOT NULL DEFAULT 'Present',
  notes VARCHAR(255),
  UNIQUE KEY uq_attendance (enrollment_id, session_date),
  INDEX idx_attendance_enrollment (enrollment_id),
  CONSTRAINT fk_attendance_enrollment
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6) Finance (simple billing model)

-- Fee Items (billable items per student per term)
CREATE TABLE fee_items (
  fee_item_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  term_id INT NOT NULL,
  fee_type ENUM('Tuition','Library','Lab','Hostel','Other') NOT NULL,
  description VARCHAR(200),
  amount DECIMAL(10,2) NOT NULL,
  billed_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  due_on DATE,
  INDEX idx_fee_items_student_term (student_id, term_id),
  CONSTRAINT fk_fee_items_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_fee_items_term
    FOREIGN KEY (term_id) REFERENCES terms(term_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Payments
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  term_id INT,
  amount DECIMAL(10,2) NOT NULL,
  paid_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  method ENUM('Cash','Card','Bank Transfer','Mobile Money','Cheque') NOT NULL,
  reference VARCHAR(100) UNIQUE,
  notes VARCHAR(255),
  INDEX idx_payments_student_term (student_id, term_id),
  CONSTRAINT fk_payments_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_payments_term
    FOREIGN KEY (term_id) REFERENCES terms(term_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- 7) Helpful indexes (optional, performance-oriented)
CREATE INDEX idx_students_name ON students(last_name, first_name);
CREATE INDEX idx_instructors_name ON instructors(last_name, first_name);
CREATE INDEX idx_courses_title ON courses(title);


-- =============================================
-- SAMPLE DATASET FOR TESTING
-- =============================================

-- Departments
INSERT INTO departments (code, name) VALUES
('CS', 'Computer Science'),
('BUS', 'Business Administration'),
('ENG', 'Engineering');

-- Programs
INSERT INTO programs (department_id, code, name, level, duration_years)
VALUES
(1, 'BSC-CS', 'B.Sc. Computer Science', 'Undergraduate', 4),
(2, 'MBA', 'Master of Business Administration', 'Postgraduate', 2),
(3, 'BENG', 'Bachelor of Engineering', 'Undergraduate', 4);

-- Terms
INSERT INTO terms (name, start_date, end_date) VALUES
('2025 Term 1', '2025-01-10', '2025-04-30'),
('2025 Term 2', '2025-05-15', '2025-08-30');

-- Instructors
INSERT INTO instructors (department_id, staff_no, first_name, last_name, email, phone, hire_date)
VALUES
(1, 'STF001', 'Alice', 'Johnson', 'alice.johnson@college.edu', '0712345678', '2020-08-15'),
(2, 'STF002', 'Bob', 'Smith', 'bob.smith@college.edu', '0723456789', '2019-01-05');

-- Students
INSERT INTO students (program_id, student_no, first_name, last_name, dob, gender, email, phone, enrollment_year, status)
VALUES
(1, 'STU1001', 'John', 'Doe', '2002-06-15', 'Male', 'john.doe@student.edu', '0791112233', 2021, 'Active'),
(1, 'STU1002', 'Mary', 'Ann', '2003-03-20', 'Female', 'mary.ann@student.edu', '0792223344', 2021, 'Active'),
(2, 'STU2001', 'David', 'Kim', '1998-12-01', 'Male', 'david.kim@student.edu', '0793334455', 2024, 'Active');

-- Student Profiles
INSERT INTO student_profiles (student_id, national_id, address_line1, city, guardian_name, guardian_phone)
VALUES
(1, 'ID12345678', '123 Main Street', 'Nairobi', 'Jane Doe', '0711222333'),
(2, 'ID87654321', '456 Market Road', 'Mombasa', 'Paul Ann', '0722333444');

-- Courses
INSERT INTO courses (department_id, code, title, credits)
VALUES
(1, 'CSC101', 'Introduction to Programming', 3),
(1, 'CSC102', 'Database Systems', 3),
(2, 'BUS201', 'Principles of Management', 3);

-- Class Offerings
INSERT INTO class_offerings (course_id, term_id, instructor_id, section, capacity, location)
VALUES
(1, 1, 1, 'A', 60, 'Room CS1'),
(2, 1, 1, 'A', 50, 'Room CS2'),
(3, 1, 2, 'A', 80, 'Room B1');

-- Enrollments
INSERT INTO enrollments (student_id, offering_id, status)
VALUES
(1, 1, 'Enrolled'),
(1, 2, 'Enrolled'),
(2, 1, 'Enrolled'),
(3, 3, 'Enrolled');

-- Grades
INSERT INTO grades (enrollment_id, grade_letter, grade_points, remarks)
VALUES
(1, 'A', 4.00, 'Excellent'),
(2, 'B', 3.00, 'Good'),
(3, 'C', 2.00, 'Satisfactory'),
(4, 'B', 3.00, 'Good');

-- Attendance
INSERT INTO attendance (enrollment_id, session_date, status)
VALUES
(1, '2025-01-15', 'Present'),
(1, '2025-01-16', 'Absent'),
(2, '2025-01-15', 'Present'),
(3, '2025-01-15', 'Present');

-- Fee Items
INSERT INTO fee_items (student_id, term_id, fee_type, description, amount, due_on)
VALUES
(1, 1, 'Tuition', 'Tuition Fee Term 1', 50000, '2025-02-15'),
(2, 1, 'Tuition', 'Tuition Fee Term 1', 50000, '2025-02-15'),
(3, 1, 'Tuition', 'MBA Fee Term 1', 80000, '2025-02-15');

-- Payments
INSERT INTO payments (student_id, term_id, amount, method, reference)
VALUES
(1, 1, 30000, 'Mobile Money', 'MPESA12345'),
(2, 1, 50000, 'Bank Transfer', 'BT56789'),
(3, 1, 80000, 'Cash', 'CASH001');
