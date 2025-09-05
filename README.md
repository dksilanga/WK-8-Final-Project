# College Management System Database

## 📘 Overview
This project is a **College Management System** implemented using **MySQL**.  
It provides a relational database schema to manage students, instructors, departments, courses, enrollments, grades, attendance, and finance.

The schema is designed with **normalization** (up to 3NF/BCNF) to reduce redundancy and ensure data integrity.

---

## 📂 Files Included
- **college_management.sql** → Contains the full schema (CREATE DATABASE, CREATE TABLEs, constraints, indexes) and a sample dataset (INSERT statements).
- **README.md** → This documentation file.

---

## 🏗️ Database Structure

### Core Entities
- **departments** → Manages academic departments (e.g., Computer Science, Business).
- **programs** → Programs under each department (BSc, MBA, BEng, etc.).
- **terms** → Academic terms/semesters.

### People
- **students** → Student records linked to programs.
- **student_profiles** → Extra details for students (1:1 relationship).
- **instructors** → Teaching staff, linked to departments.

### Academics
- **courses** → Courses offered under departments.
- **class_offerings** → Specific course sections taught in a term by instructors.
- **enrollments** → Links students to class offerings (many-to-many relationship).
- **grades** → Stores student performance per enrollment.
- **attendance** → Tracks daily attendance per class session.

### Finance
- **fee_items** → Bills raised per student per term.
- **payments** → Payments made by students.

---

## ⚙️ Relationships
- One **Department → Many Programs, Courses, Instructors**  
- One **Program → Many Students**  
- One **Student → One Student Profile**  
- Many-to-Many **Students ↔ Class Offerings** (via enrollments)  
- One-to-One **Enrollment → Grade**  
- One-to-Many **Enrollment → Attendance Records**  

---

## ▶️ How to Use
1. Open **MySQL Workbench** or **phpMyAdmin**.
2. Run the script:
   ```sql
   SOURCE path/to/college_management.sql;
   ```
3. The database `college_mgmt` will be created with all tables and sample data.

---

## 🧪 Sample Queries

### 1. List all students with their program
```sql
SELECT s.student_no, s.first_name, s.last_name, p.name AS program
FROM students s
JOIN programs p ON s.program_id = p.program_id;
```

### 2. Get student grades with course names
```sql
SELECT s.first_name, s.last_name, c.title AS course, g.grade_letter
FROM grades g
JOIN enrollments e ON g.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN class_offerings o ON e.offering_id = o.offering_id
JOIN courses c ON o.course_id = c.course_id;
```

### 3. Find outstanding fees per student
```sql
SELECT s.student_no, s.first_name, s.last_name,
       SUM(f.amount) - IFNULL(SUM(p.amount), 0) AS balance
FROM students s
JOIN fee_items f ON s.student_id = f.student_id
LEFT JOIN payments p ON s.student_id = p.student_id AND f.term_id = p.term_id
GROUP BY s.student_id;
```

---

## 👨‍💻 Author
Generated for **Assignment: Build a Complete Database Management System**  
Language: **MySQL 8.x Compatible**
