
-- =============================================================================
-- 0. OPTIONAL DBA BOOTSTRAP (run only as SYS/SYSTEM or a DBA account)
-- =============================================================================
-- CREATE USER kow_admin IDENTIFIED BY "KOW_Password_2026!";
-- GRANT CONNECT TO kow_admin;
-- GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
--       CREATE PROCEDURE, CREATE TRIGGER, CREATE SYNONYM TO kow_admin;
-- ALTER USER kow_admin QUOTA UNLIMITED ON USERS;



-- =============================================================================
-- 1. CLEANUP EXISTING OBJECTS
-- =============================================================================

BEGIN

    -- Triggers
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_question_updated'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_student_updated';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_student_audit';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_adminsession';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_synclog';       EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_contentver';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_question';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_analytics';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_timeplay';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_score';         EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_device';        EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_admin';         EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_student';       EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_teacher';       EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_custom';        EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_progress';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ai_audit';         EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Views
    BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_device_status';        EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_age_group_progress';   EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_score_summary';        EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_student_profile';      EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Procedures
    BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_bump_content_version'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_refresh_analytics';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_upload_score';         EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_upsert_student';       EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Synonyms
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM admins';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM devices';   EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM progress';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM analytics'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM questions'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM subjects';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM scores';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM students';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM admin_sessions'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM activity_logs';  EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Tables (most-dependent first; CASCADE CONSTRAINTS drops child FKs automatically)
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE auditTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE activityLogTb    CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE syncLogTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE contentVersionTb CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE questionTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE analyticsTb      CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE progressTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE timeplTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE scoreTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE customTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE deviceTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE adminSessionTb   CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE adminTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE studentTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE teacherTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE areaTb           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE barangayTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE subjectTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE gradelvlTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE diffTb           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE sexTb            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Sequences
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_stud_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_score_id';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_teacher_id';   EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_analytics_id'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_timeplay_id';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_device_id';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_admin_id';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_question_id';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_sync_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_content_ver';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_audit_id';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_admin_session_id'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_activity_log_id';  EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Roles (may fail if kow_admin lacks DROP ROLE privilege — that is fine)
    BEGIN EXECUTE IMMEDIATE 'DROP ROLE kow_admin_role';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP ROLE kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP ROLE kow_device_role';   EXCEPTION WHEN OTHERS THEN NULL; END;

END;
/


-- =============================================================================
-- 2. SEQUENCES
-- =============================================================================

CREATE SEQUENCE seq_stud_id      START WITH 1001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_score_id     START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_teacher_id   START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_analytics_id START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_timeplay_id  START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_device_id    START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_admin_id     START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_question_id  START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sync_id      START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_content_ver  START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_audit_id     START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_admin_session_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_activity_log_id  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- =============================================================================
-- 3. REFERENCE / LOOKUP TABLES
-- =============================================================================

-- Sex reference
CREATE TABLE sexTb (
    sex_id   NUMBER(2)    PRIMARY KEY,
    sex      VARCHAR2(10) NOT NULL
);
INSERT INTO sexTb VALUES (1, 'Male');
INSERT INTO sexTb VALUES (2, 'Female');

-- Difficulty levels
CREATE TABLE diffTb (
    diff_id    NUMBER(3)    PRIMARY KEY,
    difficulty VARCHAR2(20) NOT NULL
);
INSERT INTO diffTb VALUES (1, 'Easy');
INSERT INTO diffTb VALUES (2, 'Average');
INSERT INTO diffTb VALUES (3, 'Hard');

-- Grade / age group levels
CREATE TABLE gradelvlTb (
    gradelvl_id NUMBER(3)    PRIMARY KEY,
    gradelvl    VARCHAR2(20) NOT NULL,
    age_min     NUMBER(2),
    age_max     NUMBER(2)
);
INSERT INTO gradelvlTb VALUES (1, 'Punla', 3, 5);
INSERT INTO gradelvlTb VALUES (2, 'Binhi', 6, 8);

-- Subjects
CREATE TABLE subjectTb (
    subject_id NUMBER(3)    PRIMARY KEY,
    subject    VARCHAR2(30) NOT NULL
);
INSERT INTO subjectTb VALUES (1, 'Mathematics');
INSERT INTO subjectTb VALUES (2, 'Science');
INSERT INTO subjectTb VALUES (3, 'Filipino');
INSERT INTO subjectTb VALUES (4, 'English');
INSERT INTO subjectTb VALUES (5, 'Writing');

-- Barangay reference
CREATE TABLE barangayTb (
    barangay_id NUMBER(5)    PRIMARY KEY,
    barangay_nm VARCHAR2(60) NOT NULL
);
INSERT INTO barangayTb VALUES (1, 'Barangay Sauyo');

-- Area reference
CREATE TABLE areaTb (
    area_id NUMBER(5)    PRIMARY KEY,
    area_nm VARCHAR2(60) NOT NULL
);

INSERT INTO areaTb VALUES (1, 'LAW STREET');
INSERT INTO areaTb VALUES (2, 'KIMCO VILLAGE');
INSERT INTO areaTb VALUES (3, 'WALING-WALING STREET');
INSERT INTO areaTb VALUES (4, 'VICTORIA SUBDIVISION');
INSERT INTO areaTb VALUES (5, 'SAMPAGUITA STREET');
INSERT INTO areaTb VALUES (6, 'DRJ VILLAGE');
INSERT INTO areaTb VALUES (7, 'LOWER SAUYO');
INSERT INTO areaTb VALUES (8, 'SPAZIO BERNARDO CONDOMINIUM');
INSERT INTO areaTb VALUES (9, 'VICTORIA STREET');
INSERT INTO areaTb VALUES (10, 'RICHLAND SUBDIVISION');
INSERT INTO areaTb VALUES (11, 'PASCUAL STREET');
INSERT INTO areaTb VALUES (12, 'GREENVILLE SUBDIVISION');
INSERT INTO areaTb VALUES (13, 'TEODORO COMPOUND');
INSERT INTO areaTb VALUES (14, 'DEL NACIA VILLE 4');
INSERT INTO areaTb VALUES (15, 'AREA 85');
INSERT INTO areaTb VALUES (16, 'NIA VILLAGE');
INSERT INTO areaTb VALUES (17, 'AREA 99');
INSERT INTO areaTb VALUES (18, 'OCEAN PARK');
INSERT INTO areaTb VALUES (19, 'AREA 135');
INSERT INTO areaTb VALUES (20, 'GREENVIEW ROYALE');
INSERT INTO areaTb VALUES (21, 'BISTEKVILLE 15');
INSERT INTO areaTb VALUES (22, 'GREENVIEW EXECUTIVE');
INSERT INTO areaTb VALUES (23, 'MARIAN EXTENSION');
INSERT INTO areaTb VALUES (24, 'BIR VILLAGE');
INSERT INTO areaTb VALUES (25, 'MARIAN SUBDIVISION');
INSERT INTO areaTb VALUES (26, 'VICTORIAN HEIGHTS');
INSERT INTO areaTb VALUES (27, 'MOZART EXTENSION');
INSERT INTO areaTb VALUES (28, 'VILLA HERMANO 1');
INSERT INTO areaTb VALUES (29, 'COMMERCIO');
INSERT INTO areaTb VALUES (30, 'VILLA HERMANO 2');
INSERT INTO areaTb VALUES (31, 'UPPER GULOD');
INSERT INTO areaTb VALUES (32, 'PRIVADA HOMES');
INSERT INTO areaTb VALUES (33, 'LOWER GULOD');
INSERT INTO areaTb VALUES (34, 'MERRY HOMES');
INSERT INTO areaTb VALUES (35, 'AREA 169');
INSERT INTO areaTb VALUES (36, 'ATHERTON');
INSERT INTO areaTb VALUES (37, 'AREA 160-168');
INSERT INTO areaTb VALUES (38, 'LAGKITAN');
INSERT INTO areaTb VALUES (39, 'DEL MUNDO COMPOUND');
INSERT INTO areaTb VALUES (40, 'HERMINIGILDO COMPOUND');
INSERT INTO areaTb VALUES (41, 'MABUHAY COMPOUND');
INSERT INTO areaTb VALUES (42, 'AREA 5A');
INSERT INTO areaTb VALUES (43, 'AREA 5B');
INSERT INTO areaTb VALUES (44, 'AREA 6A');
INSERT INTO areaTb VALUES (45, 'NAVAL');
INSERT INTO areaTb VALUES (46, 'VILLA ROSARIO');
INSERT INTO areaTb VALUES (47, 'LIPTON STREET');
INSERT INTO areaTb VALUES (48, 'OLD CABUYAO');
INSERT INTO areaTb VALUES (49, 'BALUYOT 1');
INSERT INTO areaTb VALUES (50, 'BALUYOT 2A');
INSERT INTO areaTb VALUES (51, 'BALUYOT 2B');
INSERT INTO areaTb VALUES (52, 'MONTINOLA');
INSERT INTO areaTb VALUES (53, 'BALUYOT PARK');
INSERT INTO areaTb VALUES (54, 'PAPELAN');
INSERT INTO areaTb VALUES (55, 'DAANG NAWASA');

COMMIT;


-- =============================================================================
-- 4. CORE ENTITY TABLES
--    NOTE: This script uses DEFAULT seq.NEXTVAL for PK auto-numbering.
--          This avoids hard dependency on CREATE TRIGGER privilege.
-- =============================================================================

-- Teachers / Volunteers
CREATE TABLE teacherTb (
    teacher_id  NUMBER(10)   DEFAULT seq_teacher_id.NEXTVAL PRIMARY KEY,
    first_name  VARCHAR2(60) NOT NULL,
    middle_initial VARCHAR2(5),
    last_name   VARCHAR2(60) NOT NULL,
    created_at  DATE         DEFAULT SYSDATE NOT NULL,
    updated_at  DATE         DEFAULT SYSDATE NOT NULL
);

-- Students
CREATE TABLE studentTb (
    stud_id       NUMBER(10)   DEFAULT seq_stud_id.NEXTVAL PRIMARY KEY,
    first_name    VARCHAR2(60) NOT NULL,
    last_name     VARCHAR2(60) NOT NULL,
    nickname      VARCHAR2(40) NOT NULL,
    birthday      DATE         NOT NULL,
    sex_id        NUMBER(2)    REFERENCES sexTb(sex_id),
    teacher_id    NUMBER(10)   REFERENCES teacherTb(teacher_id),
    area_id       NUMBER(5)    DEFAULT 1 REFERENCES areaTb(area_id),
    barangay_id   NUMBER(5)    DEFAULT 1 REFERENCES barangayTb(barangay_id),
    created_at    DATE         DEFAULT SYSDATE NOT NULL,
    updated_at    DATE         DEFAULT SYSDATE NOT NULL,
    device_origin VARCHAR2(40),   -- device_uuid that registered this student
    tmp_local_id  VARCHAR2(50),   -- holds 'TMP-xxxx' until confirmed, then NULL
    CONSTRAINT uq_stud_nickname UNIQUE (nickname, birthday)
);

-- Admin users
CREATE TABLE adminTb (
    admin_id       NUMBER(10)    DEFAULT seq_admin_id.NEXTVAL PRIMARY KEY,
    username       VARCHAR2(60)  NOT NULL UNIQUE,
    password_hash  VARCHAR2(255) NOT NULL,  -- bcrypt hash (10 rounds)
    role           VARCHAR2(20)  DEFAULT 'admin' NOT NULL,
    teacher_id     NUMBER(10)    REFERENCES teacherTb(teacher_id),
    is_active      NUMBER(1)     DEFAULT 1 NOT NULL,
    must_change_password NUMBER(1) DEFAULT 0 NOT NULL,
    mfa_enabled    NUMBER(1)     DEFAULT 0 NOT NULL,
    mfa_secret_enc VARCHAR2(2000),
    failed_login_count NUMBER(10) DEFAULT 0 NOT NULL,
    locked_until   DATE,
    created_at     DATE          DEFAULT SYSDATE NOT NULL,
    updated_at     DATE          DEFAULT SYSDATE,
    last_login_at  DATE
);

-- Admin web cookie/session records
CREATE TABLE adminSessionTb (
    session_id         NUMBER(10) DEFAULT seq_admin_session_id.NEXTVAL PRIMARY KEY,
    admin_id           NUMBER(10) NOT NULL REFERENCES adminTb(admin_id),
    session_token_hash VARCHAR2(64 CHAR) NOT NULL,
    csrf_token_hash    VARCHAR2(64 CHAR) NOT NULL,
    expires_at         DATE NOT NULL,
    ip_address         VARCHAR2(64 CHAR),
    user_agent         VARCHAR2(500 CHAR),
    last_seen_at       DATE DEFAULT SYSDATE NOT NULL,
    revoked_at         DATE,
    created_at         DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_adminsession_token UNIQUE (session_token_hash)
);

-- Registered devices
CREATE TABLE deviceTb (
    device_id      NUMBER(10)   DEFAULT seq_device_id.NEXTVAL PRIMARY KEY,
    device_uuid    VARCHAR2(40) NOT NULL UNIQUE,  -- UUID from Flutter app
    device_name    VARCHAR2(80),
    registered_at  DATE         DEFAULT SYSDATE NOT NULL,
    last_synced_at DATE
);

-- User preferences / customization
CREATE TABLE customTb (
    custom_id   NUMBER(10)   PRIMARY KEY,
    stud_id     NUMBER(10)   REFERENCES studentTb(stud_id),
    sound       NUMBER(3)    DEFAULT 80,        -- 0-100 volume
    theme       VARCHAR2(20) DEFAULT 'Classroom',
    updated_at  DATE         DEFAULT SYSDATE
);


-- =============================================================================
-- 5. GAME DATA TABLES
-- =============================================================================

-- Score records (one row per game session attempt — always INSERT, never UPDATE)
CREATE TABLE scoreTb (
    score_id    NUMBER(10)   DEFAULT seq_score_id.NEXTVAL PRIMARY KEY,
    stud_id     NUMBER(10)   NOT NULL REFERENCES studentTb(stud_id),
    subject_id  NUMBER(3)    NOT NULL REFERENCES subjectTb(subject_id),
    gradelvl_id NUMBER(3)    NOT NULL REFERENCES gradelvlTb(gradelvl_id),
    diff_id     NUMBER(3)    NOT NULL REFERENCES diffTb(diff_id),
    score       NUMBER(5,2)  NOT NULL,
    max_score   NUMBER(5,2)  DEFAULT 10 NOT NULL,
    passed      NUMBER(1)    DEFAULT 0 NOT NULL,  -- 1=passed (score>=7), 0=failed
    played_at   DATE         NOT NULL,             -- timestamp from device
    synced_at   DATE         DEFAULT SYSDATE,
    device_uuid VARCHAR2(40)
);

-- Time played per student per session
CREATE TABLE timeplTb (
    timeplay_id  NUMBER(10)   DEFAULT seq_timeplay_id.NEXTVAL PRIMARY KEY,
    stud_id      NUMBER(10)   NOT NULL REFERENCES studentTb(stud_id),
    subject_id   NUMBER(3)    REFERENCES subjectTb(subject_id),
    time_played  NUMBER(10)   NOT NULL,  -- in seconds
    session_date DATE         NOT NULL,
    device_uuid  VARCHAR2(40)
);

-- Progress tracker (highest difficulty passed per student/subject/level)
CREATE TABLE progressTb (
    progress_id         NUMBER(10) PRIMARY KEY,
    stud_id             NUMBER(10) NOT NULL REFERENCES studentTb(stud_id),
    subject_id          NUMBER(3)  NOT NULL REFERENCES subjectTb(subject_id),
    gradelvl_id         NUMBER(3)  NOT NULL REFERENCES gradelvlTb(gradelvl_id),
    highest_diff_passed NUMBER(3)  DEFAULT 0 REFERENCES diffTb(diff_id),
    total_time_played   NUMBER(10) DEFAULT 0,  -- cumulative seconds
    last_played_at      DATE,
    CONSTRAINT uq_progress UNIQUE (stud_id, subject_id, gradelvl_id)
);

-- Analytics summary (computed/refreshed by sp_refresh_analytics)
CREATE TABLE analyticsTb (
    analytics_id   NUMBER(10)  DEFAULT seq_analytics_id.NEXTVAL PRIMARY KEY,
    stud_id        NUMBER(10)  NOT NULL REFERENCES studentTb(stud_id),
    subject_id     NUMBER(3)   REFERENCES subjectTb(subject_id),
    gradelvl_id    NUMBER(3)   REFERENCES gradelvlTb(gradelvl_id),
    lowest_score   NUMBER(5,2),
    average_score  NUMBER(5,2),
    highest_score  NUMBER(5,2),
    total_attempts NUMBER(5)   DEFAULT 0,
    computed_at    DATE        DEFAULT SYSDATE,
    CONSTRAINT uq_analytics UNIQUE (stud_id, subject_id, gradelvl_id)
);


-- =============================================================================
-- 6. QUESTION BANK (Admin-managed, synced down to devices)
-- =============================================================================

CREATE TABLE questionTb (
    question_id  NUMBER(10)    DEFAULT seq_question_id.NEXTVAL PRIMARY KEY,
    subject_id   NUMBER(3)     NOT NULL REFERENCES subjectTb(subject_id),
    gradelvl_id  NUMBER(3)     NOT NULL REFERENCES gradelvlTb(gradelvl_id),
    diff_id      NUMBER(3)     NOT NULL REFERENCES diffTb(diff_id),
    question_txt VARCHAR2(500) NOT NULL,
    image_url    VARCHAR2(500),
    fun_fact     VARCHAR2(1000),
    word_type    VARCHAR2(100),
    sub_prompt   VARCHAR2(500),
    option_a     VARCHAR2(200) NOT NULL,
    option_b     VARCHAR2(200) NOT NULL,
    option_c     VARCHAR2(200) NOT NULL,
    option_d     VARCHAR2(200) NOT NULL,
    correct_opt  CHAR(1)       NOT NULL,  -- 'A', 'B', 'C', or 'D'
    is_active    NUMBER(1)     DEFAULT 1,
    created_at   DATE          DEFAULT SYSDATE,
    updated_at   DATE          DEFAULT SYSDATE,
    created_by_admin_id NUMBER(10) REFERENCES adminTb(admin_id),
    updated_by_admin_id NUMBER(10) REFERENCES adminTb(admin_id)
);

-- Content version tracker (devices compare this to decide if cache needs refresh)
CREATE TABLE contentVersionTb (
    version_id   NUMBER(10)    DEFAULT seq_content_ver.NEXTVAL PRIMARY KEY,
    version_tag  VARCHAR2(20)  NOT NULL,  -- e.g. 'v42'
    changed_by   NUMBER(10)    REFERENCES adminTb(admin_id),
    changed_at   DATE          DEFAULT SYSDATE NOT NULL,
    change_note  VARCHAR2(200)
);


-- =============================================================================
-- 7. SYNC INFRASTRUCTURE
-- =============================================================================

-- Server-side log of all sync events received from devices
CREATE TABLE syncLogTb (
    sync_id     NUMBER(10)   DEFAULT seq_sync_id.NEXTVAL PRIMARY KEY,
    device_uuid VARCHAR2(40) NOT NULL,
    stud_id     NUMBER(10)   REFERENCES studentTb(stud_id),
    event_type  VARCHAR2(30) NOT NULL,  -- 'score', 'register', 'timeplay', 'progress'
    payload     CLOB,                   -- raw JSON from device
    received_at DATE         DEFAULT SYSDATE NOT NULL,
    status      VARCHAR2(20) DEFAULT 'processed'
);

-- Admin-side action log used by security hardening and monitoring screens
CREATE TABLE activityLogTb (
    log_id         NUMBER(10) DEFAULT seq_activity_log_id.NEXTVAL PRIMARY KEY,
    admin_id       NUMBER(10) REFERENCES adminTb(admin_id),
    actor_username VARCHAR2(60),
    actor_role     VARCHAR2(20),
    action         VARCHAR2(80) NOT NULL,
    target_type    VARCHAR2(80),
    target_id      VARCHAR2(80),
    status         VARCHAR2(20) DEFAULT 'success' NOT NULL,
    ip_address     VARCHAR2(64),
    user_agent     VARCHAR2(500),
    metadata       CLOB,
    created_at     DATE DEFAULT SYSDATE NOT NULL
);


-- =============================================================================
-- 8. AUDIT TABLE
-- =============================================================================

CREATE TABLE auditTb (
    audit_id   NUMBER(10)  DEFAULT seq_audit_id.NEXTVAL PRIMARY KEY,
    table_name VARCHAR2(40),
    operation  VARCHAR2(10),  -- INSERT / UPDATE / DELETE
    record_id  NUMBER(10),
    changed_by VARCHAR2(60),
    changed_at DATE DEFAULT SYSDATE
);


-- =============================================================================
-- 9. VIEWS
-- =============================================================================

-- Student full profile view
CREATE OR REPLACE VIEW vw_student_profile AS
SELECT
    s.stud_id,
    s.first_name,
    s.last_name,
    s.nickname,
    s.birthday,
    TRUNC(MONTHS_BETWEEN(SYSDATE, s.birthday) / 12) AS age,
    x.sex,
    COALESCE(a.area_nm, b.barangay_nm) AS area_nm,
    t.first_name || ' ' || t.last_name AS teacher_name,
    s.created_at
FROM studentTb   s
JOIN sexTb       x ON s.sex_id      = x.sex_id
LEFT JOIN areaTb  a ON s.area_id     = a.area_id
LEFT JOIN barangayTb  b ON s.barangay_id = b.barangay_id
LEFT JOIN teacherTb t ON s.teacher_id = t.teacher_id;

-- Score summary per student per subject/level/difficulty
CREATE OR REPLACE VIEW vw_score_summary AS
SELECT
    s.stud_id,
    s.nickname,
    sub.subject,
    gl.gradelvl,
    d.difficulty,
    COUNT(sc.score_id)      AS total_attempts,
    ROUND(AVG(sc.score), 2) AS avg_score,
    MAX(sc.score)           AS best_score,
    MIN(sc.score)           AS lowest_score,
    SUM(sc.passed)          AS total_passed
FROM studentTb  s
JOIN scoreTb    sc  ON s.stud_id      = sc.stud_id
JOIN subjectTb  sub ON sc.subject_id  = sub.subject_id
JOIN gradelvlTb gl  ON sc.gradelvl_id = gl.gradelvl_id
JOIN diffTb     d   ON sc.diff_id     = d.diff_id
GROUP BY s.stud_id, s.nickname, sub.subject, gl.gradelvl, d.difficulty;

-- Age group progress (for admin dashboard)
CREATE OR REPLACE VIEW vw_age_group_progress AS
SELECT
    gl.gradelvl,
    sub.subject,
    COUNT(DISTINCT sc.stud_id)    AS active_students,
    ROUND(AVG(sc.score), 2)       AS avg_score,
    ROUND(AVG(sc.passed) * 100, 1) AS pass_rate_pct
FROM scoreTb    sc
JOIN gradelvlTb gl  ON sc.gradelvl_id = gl.gradelvl_id
JOIN subjectTb  sub ON sc.subject_id  = sub.subject_id
GROUP BY gl.gradelvl, sub.subject;

-- Device sync status
CREATE OR REPLACE VIEW vw_device_status AS
SELECT
    d.device_uuid,
    d.device_name,
    d.registered_at,
    d.last_synced_at,
    COUNT(DISTINCT sl.stud_id) AS students_on_device
FROM deviceTb   d
LEFT JOIN syncLogTb sl ON d.device_uuid = sl.device_uuid
GROUP BY d.device_uuid, d.device_name, d.registered_at, d.last_synced_at;


-- =============================================================================
-- 10. STORED PROCEDURES
-- =============================================================================

-- Register or lookup a student (called by sync service on first sync)
CREATE OR REPLACE PROCEDURE sp_upsert_student (
    p_tmp_local_id  IN  VARCHAR2,
    p_first_name    IN  VARCHAR2,
    p_last_name     IN  VARCHAR2,
    p_nickname      IN  VARCHAR2,
    p_birthday      IN  DATE,
    p_sex_id        IN  NUMBER,
    p_device_uuid   IN  VARCHAR2,
    p_new_stud_id   OUT NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM studentTb
    WHERE nickname = p_nickname AND birthday = p_birthday;

    IF v_count = 0 THEN
        INSERT INTO studentTb
            (first_name, last_name, nickname, birthday, sex_id, device_origin, tmp_local_id)
        VALUES
            (p_first_name, p_last_name, p_nickname, p_birthday, p_sex_id, p_device_uuid, p_tmp_local_id)
        RETURNING stud_id INTO p_new_stud_id;
    ELSE
        SELECT stud_id INTO p_new_stud_id
        FROM studentTb
        WHERE nickname = p_nickname AND birthday = p_birthday;
    END IF;

    -- Register device if not already registered
    MERGE INTO deviceTb d
    USING (SELECT p_device_uuid AS duuid FROM DUAL) src
    ON (d.device_uuid = src.duuid)
    WHEN NOT MATCHED THEN
        INSERT (device_uuid, registered_at) VALUES (p_device_uuid, SYSDATE);

    COMMIT;
END sp_upsert_student;
/

-- Upload a score record from device sync
CREATE OR REPLACE PROCEDURE sp_upload_score (
    p_stud_id      IN NUMBER,
    p_subject_id   IN NUMBER,
    p_gradelvl_id  IN NUMBER,
    p_diff_id      IN NUMBER,
    p_score        IN NUMBER,
    p_max_score    IN NUMBER,
    p_passed       IN NUMBER,
    p_played_at    IN DATE,
    p_device_uuid  IN VARCHAR2
) AS
BEGIN
    INSERT INTO scoreTb
        (stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid)
    VALUES
        (p_stud_id, p_subject_id, p_gradelvl_id, p_diff_id,
         p_score, p_max_score, p_passed, p_played_at, p_device_uuid);

    -- Update progress: only advance if this attempt passed a higher difficulty
    MERGE INTO progressTb pr
    USING (SELECT p_stud_id AS sid, p_subject_id AS subj, p_gradelvl_id AS glvl FROM DUAL) src
    ON (pr.stud_id = src.sid AND pr.subject_id = src.subj AND pr.gradelvl_id = src.glvl)
    WHEN MATCHED THEN
        UPDATE SET
            highest_diff_passed = CASE
                WHEN p_passed = 1 AND p_diff_id > pr.highest_diff_passed THEN p_diff_id
                ELSE pr.highest_diff_passed
            END,
            last_played_at = CASE
                WHEN p_played_at > pr.last_played_at THEN p_played_at
                ELSE pr.last_played_at
            END
    WHEN NOT MATCHED THEN
        INSERT (progress_id, stud_id, subject_id, gradelvl_id, highest_diff_passed, last_played_at)
        VALUES (seq_score_id.NEXTVAL, p_stud_id, p_subject_id, p_gradelvl_id,
                CASE WHEN p_passed = 1 THEN p_diff_id ELSE 0 END, p_played_at);

    COMMIT;
END sp_upload_score;
/

-- Recompute analytics for a student after score batch upload
CREATE OR REPLACE PROCEDURE sp_refresh_analytics (
    p_stud_id     IN NUMBER,
    p_subject_id  IN NUMBER,
    p_gradelvl_id IN NUMBER
) AS
BEGIN
    MERGE INTO analyticsTb a
    USING (
        SELECT
            p_stud_id     AS sid,
            p_subject_id  AS subj,
            p_gradelvl_id AS glvl,
            MIN(score)           AS lo,
            ROUND(AVG(score), 2) AS av,
            MAX(score)           AS hi,
            COUNT(*)             AS cnt
        FROM scoreTb
        WHERE stud_id     = p_stud_id
          AND subject_id  = p_subject_id
          AND gradelvl_id = p_gradelvl_id
    ) src
    ON (a.stud_id = src.sid AND a.subject_id = src.subj AND a.gradelvl_id = src.glvl)
    WHEN MATCHED THEN
        UPDATE SET lowest_score   = src.lo,
                   average_score  = src.av,
                   highest_score  = src.hi,
                   total_attempts = src.cnt,
                   computed_at    = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (analytics_id, stud_id, subject_id, gradelvl_id,
                lowest_score, average_score, highest_score, total_attempts)
        VALUES (seq_analytics_id.NEXTVAL, src.sid, src.subj, src.glvl,
                src.lo, src.av, src.hi, src.cnt);

    COMMIT;
END sp_refresh_analytics;
/

-- Bump content version after admin saves question changes
CREATE OR REPLACE PROCEDURE sp_bump_content_version (
    p_admin_id IN NUMBER,
    p_note     IN VARCHAR2
) AS
    v_new_tag VARCHAR2(20);
    v_ver_num NUMBER;
BEGIN
    SELECT seq_content_ver.NEXTVAL INTO v_ver_num FROM DUAL;
    v_new_tag := 'v' || TO_CHAR(v_ver_num);
    INSERT INTO contentVersionTb (version_tag, changed_by, change_note)
    VALUES (v_new_tag, p_admin_id, p_note);
    COMMIT;
END sp_bump_content_version;
/


-- =============================================================================
-- 11. TRIGGERS
-- =============================================================================
-- Optional: create triggers if account has CREATE TRIGGER privilege.
BEGIN
    BEGIN EXECUTE IMMEDIATE q'[CREATE OR REPLACE TRIGGER trg_student_audit
AFTER INSERT OR UPDATE OR DELETE ON studentTb
FOR EACH ROW
DECLARE
    v_op VARCHAR2(6);
    v_id NUMBER;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT'; v_id := :NEW.stud_id;
    ELSIF UPDATING THEN
        v_op := 'UPDATE'; v_id := :NEW.stud_id;
    ELSE
        v_op := 'DELETE'; v_id := :OLD.stud_id;
    END IF;
    INSERT INTO auditTb (audit_id, table_name, operation, record_id, changed_by, changed_at)
    VALUES (seq_audit_id.NEXTVAL, 'studentTb', v_op, v_id,
            SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
END;]'; EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN EXECUTE IMMEDIATE q'[CREATE OR REPLACE TRIGGER trg_student_updated
BEFORE UPDATE ON studentTb
FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
END;]'; EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN EXECUTE IMMEDIATE q'[CREATE OR REPLACE TRIGGER trg_question_updated
AFTER INSERT OR UPDATE OR DELETE ON questionTb
FOR EACH ROW
DECLARE
    v_op VARCHAR2(6);
    v_id NUMBER;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT'; v_id := :NEW.question_id;
    ELSIF UPDATING THEN
        v_op := 'UPDATE'; v_id := :NEW.question_id;
    ELSE
        v_op := 'DELETE'; v_id := :OLD.question_id;
    END IF;
    INSERT INTO auditTb (audit_id, table_name, operation, record_id, changed_by, changed_at)
    VALUES (seq_audit_id.NEXTVAL, 'questionTb', v_op, v_id,
            SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
END;]'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/


-- =============================================================================
-- 12. ROLE-BASED ACCESS CONTROL (RBAC)
-- =============================================================================

-- NOTE: CREATE ROLE requires the CREATE ROLE system privilege which is NOT
-- included in CONNECT+RESOURCE. All statements run via EXECUTE IMMEDIATE
-- so they are silently skipped if kow_admin lacks the privilege.
-- For production: grant CREATE ROLE to kow_admin as SYSTEM, then re-run.
BEGIN
    -- Create roles
    BEGIN EXECUTE IMMEDIATE 'CREATE ROLE kow_admin_role';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE ROLE kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE ROLE kow_device_role';   EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Admin role: full access
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON studentTb        TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON scoreTb          TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON questionTb       TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON analyticsTb      TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON progressTb       TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON timeplTb         TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON customTb         TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON deviceTb         TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON adminTb          TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON adminSessionTb   TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON activityLogTb    TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON areaTb           TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON contentVersionTb TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON syncLogTb TO kow_admin_role';                        EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON auditTb TO kow_admin_role';                                  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_student_profile    TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_score_summary      TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_age_group_progress TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_device_status      TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_upsert_student       TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_upload_score         TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_refresh_analytics    TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_bump_content_version TO kow_admin_role'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Device sync role: limited write access (used by Node.js API)
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON studentTb        TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON scoreTb          TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON timeplTb         TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON progressTb       TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON syncLogTb        TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON deviceTb         TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON subjectTb        TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON gradelvlTb       TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON diffTb           TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON areaTb           TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON questionTb       TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON contentVersionTb TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_upsert_student    TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_upload_score      TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT EXECUTE ON sp_refresh_analytics TO kow_device_role'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Read-only role: for reporting/monitoring
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_student_profile    TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_score_summary      TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_age_group_progress TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON vw_device_status      TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON analyticsTb           TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON areaTb                TO kow_readonly_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/


-- =============================================================================
-- 13. SYNONYMS (simplify object references)
-- =============================================================================

BEGIN
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM students  FOR studentTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM scores    FOR scoreTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM subjects  FOR subjectTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM questions FOR questionTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM analytics FOR analyticsTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM progress  FOR progressTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM devices   FOR deviceTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM admins    FOR adminTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM admin_sessions FOR adminSessionTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM activity_logs  FOR activityLogTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/


-- =============================================================================
-- 14. SAMPLE SEED DATA (for testing admin panel immediately)
-- =============================================================================

-- Sample teacher (idempotent - won't duplicate on re-execution)
MERGE INTO teacherTb t
USING (SELECT 'Mary Rose' first_name, 'Manandeg' last_name FROM DUAL) s
ON (t.first_name = s.first_name AND t.last_name = s.last_name)
WHEN NOT MATCHED THEN
  INSERT (first_name, last_name) VALUES (s.first_name, s.last_name);

-- Sample admin user
-- Default password: Admin@KOW2026
MERGE INTO adminTb a
USING (SELECT 'kow_admin' username FROM DUAL) s
ON (a.username = s.username)
WHEN NOT MATCHED THEN
  INSERT (username, password_hash, role) 
  VALUES ('kow_admin', '$2a$10$VOd87aY8CP4Cm2IebNDIQuLeVY9/cp1Q1fitE0zS6AYcDGsIi3bwO', 'admin');

-- Sample students (idempotent)
MERGE INTO studentTb s
USING (SELECT 'Maria' first_name, 'Santos' last_name, 'Mari' nickname, TO_DATE('2020-03-15', 'YYYY-MM-DD') birthday, 2 sex_id, 1 teacher_id, 1 barangay_id, 'DEV-001' device_origin FROM DUAL) d
ON (s.first_name = d.first_name AND s.last_name = d.last_name AND s.nickname = d.nickname)
WHEN NOT MATCHED THEN
  INSERT (first_name, last_name, nickname, birthday, sex_id, teacher_id, barangay_id, device_origin) 
  VALUES (d.first_name, d.last_name, d.nickname, d.birthday, d.sex_id, d.teacher_id, d.barangay_id, d.device_origin);

MERGE INTO studentTb s
USING (SELECT 'Jose' first_name, 'Reyes' last_name, 'Pepe' nickname, TO_DATE('2019-07-22', 'YYYY-MM-DD') birthday, 1 sex_id, 1 teacher_id, 1 barangay_id, 'DEV-001' device_origin FROM DUAL) d
ON (s.first_name = d.first_name AND s.last_name = d.last_name AND s.nickname = d.nickname)
WHEN NOT MATCHED THEN
  INSERT (first_name, last_name, nickname, birthday, sex_id, teacher_id, barangay_id, device_origin) 
  VALUES (d.first_name, d.last_name, d.nickname, d.birthday, d.sex_id, d.teacher_id, d.barangay_id, d.device_origin);

-- Sample device (idempotent)
MERGE INTO deviceTb d
USING (SELECT 'DEV-001' device_uuid FROM DUAL) s
ON (d.device_uuid = s.device_uuid)
WHEN NOT MATCHED THEN
  INSERT (device_uuid, device_name, registered_at) 
  VALUES ('DEV-001', 'Barangay Sauyo Tablet 1', SYSDATE);

-- Sample scores (idempotent - using unique constraint on stud_id, subject_id, gradelvl_id, diff_id, played_at)
MERGE INTO scoreTb s
USING (SELECT 1001 stud_id, 1 subject_id, 2 gradelvl_id, 1 diff_id, 8 score, 10 max_score, 1 passed, TRUNC(SYSDATE - 1) played_at, 'DEV-001' device_uuid FROM DUAL) d
ON (s.stud_id = d.stud_id AND s.subject_id = d.subject_id AND s.gradelvl_id = d.gradelvl_id AND s.device_uuid = d.device_uuid AND TRUNC(s.played_at) = d.played_at)
WHEN NOT MATCHED THEN
  INSERT (stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid) 
  VALUES (d.stud_id, d.subject_id, d.gradelvl_id, d.diff_id, d.score, d.max_score, d.passed, SYSDATE - 1, d.device_uuid);

MERGE INTO scoreTb s
USING (SELECT 1002 stud_id, 2 subject_id, 2 gradelvl_id, 1 diff_id, 7 score, 10 max_score, 1 passed, TRUNC(SYSDATE) played_at, 'DEV-001' device_uuid FROM DUAL) d
ON (s.stud_id = d.stud_id AND s.subject_id = d.subject_id AND s.gradelvl_id = d.gradelvl_id AND s.device_uuid = d.device_uuid AND TRUNC(s.played_at) = d.played_at)
WHEN NOT MATCHED THEN
  INSERT (stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid) 
  VALUES (d.stud_id, d.subject_id, d.gradelvl_id, d.diff_id, d.score, d.max_score, d.passed, SYSDATE, d.device_uuid);

-- Sample questions (idempotent - won't insert same question twice)
-- Punla: 5 questions
MERGE INTO questionTb q
USING (SELECT 1 subject_id, 1 gradelvl_id, 1 diff_id, 'What is 1 + 1?' question_txt, '1' option_a, '2' option_b, '3' option_c, '4' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 3 subject_id, 1 gradelvl_id, 1 diff_id, 'Which word rhymes with cat?' question_txt, 'Dog' option_a, 'Hat' option_b, 'Tree' option_c, 'Sun' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 4 subject_id, 1 gradelvl_id, 1 diff_id, 'What color is the sky?' question_txt, 'Red' option_a, 'Green' option_b, 'Blue' option_c, 'Yellow' option_d, 'C' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 2 subject_id, 1 gradelvl_id, 2 diff_id, 'How many sides does a triangle have?' question_txt, '2' option_a, '3' option_b, '4' option_c, '5' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 4 subject_id, 1 gradelvl_id, 2 diff_id, 'Which letter comes after B?' question_txt, 'A' option_a, 'D' option_b, 'C' option_c, 'E' option_d, 'C' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 3 subject_id, 1 gradelvl_id, 2 diff_id, 'Which word means the same as small?' question_txt, 'Tiny' option_a, 'Big' option_b, 'Hot' option_c, 'Fast' option_d, 'A' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

-- Binhi: 3 questions
MERGE INTO questionTb q
USING (SELECT 1 subject_id, 2 gradelvl_id, 1 diff_id, 'What is 2 + 2?' question_txt, '3' option_a, '4' option_b, '5' option_c, '6' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 2 subject_id, 2 gradelvl_id, 2 diff_id, 'What shape has 4 equal sides?' question_txt, 'Circle' option_a, 'Square' option_b, 'Triangle' option_c, 'Star' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

MERGE INTO questionTb q
USING (SELECT 4 subject_id, 2 gradelvl_id, 2 diff_id, 'Which word is written correctly?' question_txt, 'Frend' option_a, 'Friend' option_b, 'Freand' option_c, 'Frined' option_d, 'B' correct_opt FROM DUAL) s
ON (q.subject_id = s.subject_id AND q.gradelvl_id = s.gradelvl_id AND q.diff_id = s.diff_id AND q.question_txt = s.question_txt AND q.correct_opt = s.correct_opt)
WHEN NOT MATCHED THEN
    INSERT (subject_id, gradelvl_id, diff_id, question_txt, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (s.subject_id, s.gradelvl_id, s.diff_id, s.question_txt, s.option_a, s.option_b, s.option_c, s.option_d, s.correct_opt);

-- Initial content version (idempotent)
MERGE INTO contentVersionTb c
USING (SELECT 'v1' version_tag FROM DUAL) s
ON (c.version_tag = s.version_tag)
WHEN NOT MATCHED THEN
  INSERT (version_tag, change_note) VALUES (s.version_tag, 'Initial schema load');

COMMIT;


-- =============================================================================
-- 15. VERIFY INSTALLATION
-- =============================================================================

SELECT 'Tables:     ' || COUNT(*) AS status FROM user_tables
WHERE table_name IN (
    'STUDENTTB','SCORETB','SUBJECTTB','GRADELVLTB','DIFFTB',
    'AREATB','BARANGAYTB','SEXTB','TEACHERTB','CUSTOMTB','ANALYTICSTB',
    'TIMEPLTB','PROGRESSTB','QUESTIONTB','CONTENTVERSIONTB',
    'SYNCLOGTB','ACTIVITYLOGTB','AUDITTB','DEVICETB','ADMINTB','ADMINSESSIONTB'
);
-- Expected: 21

SELECT 'Sequences:  ' || COUNT(*) AS status FROM user_sequences;
-- Expected: 13

SELECT 'Sequences(KOW): ' || COUNT(*) AS status FROM user_sequences
WHERE sequence_name IN (
    'SEQ_STUD_ID','SEQ_SCORE_ID','SEQ_TEACHER_ID','SEQ_ANALYTICS_ID','SEQ_TIMEPLAY_ID',
    'SEQ_DEVICE_ID','SEQ_ADMIN_ID','SEQ_QUESTION_ID','SEQ_SYNC_ID','SEQ_CONTENT_VER','SEQ_AUDIT_ID',
    'SEQ_ADMIN_SESSION_ID','SEQ_ACTIVITY_LOG_ID'
);
-- Expected: 13

SELECT 'Views:      ' || COUNT(*) AS status FROM user_views;
-- Expected: 4

SELECT 'Procedures: ' || COUNT(*) AS status FROM user_procedures
WHERE object_type = 'PROCEDURE'
    AND object_name IN ('SP_UPSERT_STUDENT','SP_UPLOAD_SCORE','SP_REFRESH_ANALYTICS','SP_BUMP_CONTENT_VERSION');
-- Expected: 4

SELECT 'Triggers(KOW): ' || COUNT(*) AS status FROM user_triggers
WHERE trigger_name IN ('TRG_STUDENT_AUDIT','TRG_STUDENT_UPDATED','TRG_QUESTION_UPDATED');
-- Expected: 3 if CREATE TRIGGER is granted; otherwise 0

-- =============================================================================
-- END OF SCHEMA
-- Node.js backend .env:
--   DB_USER=kow_admin
--   DB_PASSWORD=KOW_Password_2026!
--   DB_CONNECTION_STRING=localhost:1521/XE
-- =============================================================================
