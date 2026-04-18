
-- =============================================================================
-- 0. OPTIONAL DBA BOOTSTRAP (run only as SYS/SYSTEM or a DBA account)
-- =============================================================================
-- CREATE USER kow_admin IDENTIFIED BY "KOW_Password_2026!";
-- NOTE: Do not use deprecated CONNECT/RESOURCE roles. Grant system privileges directly.
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

    -- Tables (most-dependent first; CASCADE CONSTRAINTS drops child FKs automatically)
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE auditTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE syncLogTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE contentVersionTb CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE questionTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE analyticsTb      CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE progressTb       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE timeplTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE scoreTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE customTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE deviceTb         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE adminTb          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE studentTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE teacherTb        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
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

-- Barangay reference
CREATE TABLE barangayTb (
    barangay_id NUMBER(5)    PRIMARY KEY,
    barangay_nm VARCHAR2(60) NOT NULL
);
INSERT INTO barangayTb VALUES (1, 'Barangay Sauyo');

COMMIT;


-- =============================================================================
-- 4. CORE ENTITY TABLES
--    NOTE: No DEFAULT seq.NEXTVAL here — that is Oracle 12c+ syntax.
--          BEFORE INSERT triggers (Section 10) handle auto-increment for 11g.
-- =============================================================================

-- Teachers / Volunteers
CREATE TABLE teacherTb (
    teacher_id  NUMBER(10)   PRIMARY KEY,
    first_name  VARCHAR2(60) NOT NULL,
    last_name   VARCHAR2(60) NOT NULL,
    created_at  DATE         DEFAULT SYSDATE NOT NULL
);

-- Students
CREATE TABLE studentTb (
    stud_id       NUMBER(10)   PRIMARY KEY,
    first_name    VARCHAR2(60) NOT NULL,
    last_name     VARCHAR2(60) NOT NULL,
    nickname      VARCHAR2(40) NOT NULL,
    birthday      DATE         NOT NULL,
    sex_id        NUMBER(2)    REFERENCES sexTb(sex_id),
    teacher_id    NUMBER(10)   REFERENCES teacherTb(teacher_id),
    barangay_id   NUMBER(5)    DEFAULT 1 REFERENCES barangayTb(barangay_id),
    created_at    DATE         DEFAULT SYSDATE NOT NULL,
    updated_at    DATE         DEFAULT SYSDATE NOT NULL,
    device_origin VARCHAR2(40),   -- device_uuid that registered this student
    tmp_local_id  VARCHAR2(50),   -- holds 'TMP-xxxx' until confirmed, then NULL
    CONSTRAINT uq_stud_nickname UNIQUE (nickname, birthday)
);

-- Admin users
CREATE TABLE adminTb (
    admin_id       NUMBER(10)    PRIMARY KEY,
    username       VARCHAR2(60)  NOT NULL UNIQUE,
    password_hash  VARCHAR2(255) NOT NULL,  -- bcrypt hash (10 rounds)
    role           VARCHAR2(20)  DEFAULT 'admin' NOT NULL,
    created_at     DATE          DEFAULT SYSDATE NOT NULL,
    last_login_at  DATE
);

-- Registered devices
CREATE TABLE deviceTb (
    device_id      NUMBER(10)   PRIMARY KEY,
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
    score_id    NUMBER(10)   PRIMARY KEY,
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
    timeplay_id  NUMBER(10)   PRIMARY KEY,
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
    analytics_id   NUMBER(10)  PRIMARY KEY,
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
    question_id  NUMBER(10)    PRIMARY KEY,
    subject_id   NUMBER(3)     NOT NULL REFERENCES subjectTb(subject_id),
    gradelvl_id  NUMBER(3)     NOT NULL REFERENCES gradelvlTb(gradelvl_id),
    diff_id      NUMBER(3)     NOT NULL REFERENCES diffTb(diff_id),
    question_txt VARCHAR2(500) NOT NULL,
    question_image BLOB,
    option_a     VARCHAR2(200) NOT NULL,
    option_b     VARCHAR2(200) NOT NULL,
    option_c     VARCHAR2(200) NOT NULL,
    option_d     VARCHAR2(200) NOT NULL,
    option_a_image BLOB,
    option_b_image BLOB,
    option_c_image BLOB,
    option_d_image BLOB,
    correct_opt  CHAR(1)       NOT NULL,  -- 'A', 'B', 'C', or 'D'
    is_active    NUMBER(1)     DEFAULT 1,
    created_at   DATE          DEFAULT SYSDATE,
    updated_at   DATE          DEFAULT SYSDATE
);

-- Content version tracker (devices compare this to decide if cache needs refresh)
CREATE TABLE contentVersionTb (
    version_id   NUMBER(10)    PRIMARY KEY,
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
    sync_id     NUMBER(10)   PRIMARY KEY,
    device_uuid VARCHAR2(40) NOT NULL,
    stud_id     NUMBER(10)   REFERENCES studentTb(stud_id),
    event_type  VARCHAR2(30) NOT NULL,  -- 'score', 'register', 'timeplay', 'progress'
    payload     CLOB,                   -- raw JSON from device
    received_at DATE         DEFAULT SYSDATE NOT NULL,
    status      VARCHAR2(20) DEFAULT 'processed'
);


-- =============================================================================
-- 8. AUDIT TABLE
-- =============================================================================

CREATE TABLE auditTb (
    audit_id   NUMBER(10)  PRIMARY KEY,
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
    b.barangay_nm,
    t.first_name || ' ' || t.last_name AS teacher_name,
    s.created_at
FROM studentTb   s
JOIN sexTb       x ON s.sex_id      = x.sex_id
JOIN barangayTb  b ON s.barangay_id = b.barangay_id
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
            (stud_id, first_name, last_name, nickname, birthday, sex_id, device_origin, tmp_local_id)
        VALUES
            (seq_stud_id.NEXTVAL, p_first_name, p_last_name, p_nickname, p_birthday, p_sex_id, p_device_uuid, p_tmp_local_id)
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
        (score_id, stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid)
    VALUES
        (seq_score_id.NEXTVAL, p_stud_id, p_subject_id, p_gradelvl_id, p_diff_id,
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
    INSERT INTO contentVersionTb (version_id, version_tag, changed_by, change_note)
    VALUES (v_ver_num, v_new_tag, p_admin_id, p_note);
    COMMIT;
END sp_bump_content_version;
/


-- =============================================================================
-- 11. TRIGGERS
-- =============================================================================
-- Section A: Auto-increment PKs (Oracle 11g replacement for DEFAULT seq.NEXTVAL)
-- Section B: Audit + timestamp triggers
-- NOTE: If your account lacks CREATE TRIGGER privilege, this section will fail
-- with ORA-01031, but the schema and seed data still work because IDs are now
-- assigned using sequences directly in INSERT statements/procedures.

-- A) Auto-increment: teacherTb
CREATE OR REPLACE TRIGGER trg_ai_teacher
BEFORE INSERT ON teacherTb
FOR EACH ROW
BEGIN
    IF :NEW.teacher_id IS NULL THEN
        SELECT seq_teacher_id.NEXTVAL INTO :NEW.teacher_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: studentTb
CREATE OR REPLACE TRIGGER trg_ai_student
BEFORE INSERT ON studentTb
FOR EACH ROW
BEGIN
    IF :NEW.stud_id IS NULL THEN
        SELECT seq_stud_id.NEXTVAL INTO :NEW.stud_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: adminTb
CREATE OR REPLACE TRIGGER trg_ai_admin
BEFORE INSERT ON adminTb
FOR EACH ROW
BEGIN
    IF :NEW.admin_id IS NULL THEN
        SELECT seq_admin_id.NEXTVAL INTO :NEW.admin_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: deviceTb
CREATE OR REPLACE TRIGGER trg_ai_device
BEFORE INSERT ON deviceTb
FOR EACH ROW
BEGIN
    IF :NEW.device_id IS NULL THEN
        SELECT seq_device_id.NEXTVAL INTO :NEW.device_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: scoreTb
CREATE OR REPLACE TRIGGER trg_ai_score
BEFORE INSERT ON scoreTb
FOR EACH ROW
BEGIN
    IF :NEW.score_id IS NULL THEN
        SELECT seq_score_id.NEXTVAL INTO :NEW.score_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: timeplTb
CREATE OR REPLACE TRIGGER trg_ai_timeplay
BEFORE INSERT ON timeplTb
FOR EACH ROW
BEGIN
    IF :NEW.timeplay_id IS NULL THEN
        SELECT seq_timeplay_id.NEXTVAL INTO :NEW.timeplay_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: analyticsTb
CREATE OR REPLACE TRIGGER trg_ai_analytics
BEFORE INSERT ON analyticsTb
FOR EACH ROW
BEGIN
    IF :NEW.analytics_id IS NULL THEN
        SELECT seq_analytics_id.NEXTVAL INTO :NEW.analytics_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: questionTb
CREATE OR REPLACE TRIGGER trg_ai_question
BEFORE INSERT ON questionTb
FOR EACH ROW
BEGIN
    IF :NEW.question_id IS NULL THEN
        SELECT seq_question_id.NEXTVAL INTO :NEW.question_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: contentVersionTb
CREATE OR REPLACE TRIGGER trg_ai_contentver
BEFORE INSERT ON contentVersionTb
FOR EACH ROW
BEGIN
    IF :NEW.version_id IS NULL THEN
        SELECT seq_content_ver.NEXTVAL INTO :NEW.version_id FROM DUAL;
    END IF;
END;
/

-- A) Auto-increment: syncLogTb
CREATE OR REPLACE TRIGGER trg_ai_synclog
BEFORE INSERT ON syncLogTb
FOR EACH ROW
BEGIN
    IF :NEW.sync_id IS NULL THEN
        SELECT seq_sync_id.NEXTVAL INTO :NEW.sync_id FROM DUAL;
    END IF;
END;
/

-- B) Auto-audit trigger for studentTb
--    NOTE: INSERTING/UPDATING/DELETING are PL/SQL boolean predicates — they cannot
--    be used inside SQL expressions (VALUES clause). Use IF/ELSIF instead.
CREATE OR REPLACE TRIGGER trg_student_audit
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
END;
/

-- B) Auto-update updated_at on studentTb
CREATE OR REPLACE TRIGGER trg_student_updated
BEFORE UPDATE ON studentTb
FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
END;
/

-- B) Audit trigger for questionTb
CREATE OR REPLACE TRIGGER trg_question_updated
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
END;
/


-- =============================================================================
-- 13. SYNONYMS (simplify object references)
-- =============================================================================

BEGIN
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM students FOR studentTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM scores FOR scoreTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM subjects FOR subjectTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM questions FOR questionTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM analytics FOR analyticsTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM progress FOR progressTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM devices FOR deviceTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM admins FOR adminTb'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/


-- =============================================================================
-- 14. SAMPLE SEED DATA (for testing admin panel immediately)
-- =============================================================================

-- Sample teacher
INSERT INTO teacherTb (teacher_id, first_name, last_name)
VALUES (seq_teacher_id.NEXTVAL, 'Mary Rose', 'Manandeg');

-- Sample admin user
-- Default password: Admin@KOW2026
-- IMPORTANT: Regenerate this hash with bcryptjs before production:
--   const bcrypt = require('bcryptjs');
--   console.log(bcrypt.hashSync('YourNewPassword', 10));
INSERT INTO adminTb (admin_id, username, password_hash, role)
VALUES (seq_admin_id.NEXTVAL, 'kow_admin', '$2b$10$exampleHashChangeBeforeUse1234567890abcdefgh', 'admin');

-- Sample students
INSERT INTO studentTb (stud_id, first_name, last_name, nickname, birthday, sex_id, teacher_id, barangay_id, device_origin)
VALUES (seq_stud_id.NEXTVAL, 'Maria', 'Santos', 'Mari', TO_DATE('2020-03-15', 'YYYY-MM-DD'), 2, 1, 1, 'DEV-001');

INSERT INTO studentTb (stud_id, first_name, last_name, nickname, birthday, sex_id, teacher_id, barangay_id, device_origin)
VALUES (seq_stud_id.NEXTVAL, 'Jose', 'Reyes', 'Pepe', TO_DATE('2019-07-22', 'YYYY-MM-DD'), 1, 1, 1, 'DEV-001');

-- Sample device
INSERT INTO deviceTb (device_id, device_uuid, device_name, registered_at)
VALUES (seq_device_id.NEXTVAL, 'DEV-001', 'Barangay Sauyo Tablet 1', SYSDATE);

-- Sample scores
INSERT INTO scoreTb (score_id, stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid)
VALUES (
    seq_score_id.NEXTVAL,
    (SELECT stud_id FROM studentTb WHERE nickname = 'Mari' AND birthday = TO_DATE('2020-03-15', 'YYYY-MM-DD')),
    1, 2, 1, 8, 10, 1, SYSDATE - 1, 'DEV-001'
);

INSERT INTO scoreTb (score_id, stud_id, subject_id, gradelvl_id, diff_id, score, max_score, passed, played_at, device_uuid)
VALUES (
    seq_score_id.NEXTVAL,
    (SELECT stud_id FROM studentTb WHERE nickname = 'Pepe' AND birthday = TO_DATE('2019-07-22', 'YYYY-MM-DD')),
    2, 2, 1, 7, 10, 1, SYSDATE, 'DEV-001'
);

-- Sample questions (Mathematics, Punla, Easy)
INSERT INTO questionTb (question_id, subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
VALUES (seq_question_id.NEXTVAL, 1, 1, 1, 'What is 1 + 1?', NULL, '1', '2', '3', '4', 'B');

INSERT INTO questionTb (question_id, subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
VALUES (seq_question_id.NEXTVAL, 1, 1, 1, 'How many fingers on one hand?', NULL, '3', '4', '5', '6', 'C');

-- Sample questions (English, Punla, Easy)
INSERT INTO questionTb (question_id, subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
VALUES (seq_question_id.NEXTVAL, 4, 1, 1, 'What color is the sky?', NULL, 'Red', 'Green', 'Blue', 'Yellow', 'C');

-- Initial content version
INSERT INTO contentVersionTb (version_id, version_tag, change_note)
VALUES (seq_content_ver.NEXTVAL, 'v1', 'Initial schema load');

COMMIT;


-- =============================================================================
-- 15. VERIFY INSTALLATION
-- =============================================================================

SELECT 'Tables:     ' || COUNT(*) AS status FROM user_tables
WHERE table_name IN (
    'STUDENTTB','SCORETB','SUBJECTTB','GRADELVLTB','DIFFTB',
    'BARANGAYTB','SEXTB','TEACHERTB','CUSTOMTB','ANALYTICSTB',
    'TIMEPLTB','PROGRESSTB','QUESTIONTB','CONTENTVERSIONTB',
    'SYNCLOGTB','AUDITTB','DEVICETB','ADMINTB'
);
-- Expected: 18

SELECT 'Sequences:  ' || COUNT(*) AS status FROM user_sequences
WHERE sequence_name IN (
    'SEQ_STUD_ID','SEQ_SCORE_ID','SEQ_TEACHER_ID','SEQ_ANALYTICS_ID','SEQ_TIMEPLAY_ID',
    'SEQ_DEVICE_ID','SEQ_ADMIN_ID','SEQ_QUESTION_ID','SEQ_SYNC_ID','SEQ_CONTENT_VER','SEQ_AUDIT_ID'
);
-- Expected: 11

SELECT 'Views:      ' || COUNT(*) AS status FROM user_views;
-- Expected: 4

SELECT 'Procedures: ' || COUNT(*) AS status FROM user_procedures
WHERE object_type = 'PROCEDURE'
  AND object_name IN (
      'SP_UPSERT_STUDENT','SP_UPLOAD_SCORE','SP_REFRESH_ANALYTICS','SP_BUMP_CONTENT_VERSION'
  );
-- Expected: 4

SELECT 'Triggers:   ' || COUNT(*) AS status FROM user_triggers
WHERE trigger_name IN (
    'TRG_AI_TEACHER','TRG_AI_STUDENT','TRG_AI_ADMIN','TRG_AI_DEVICE','TRG_AI_SCORE',
    'TRG_AI_TIMEPLAY','TRG_AI_ANALYTICS','TRG_AI_QUESTION','TRG_AI_CONTENTVER','TRG_AI_SYNCLOG',
    'TRG_STUDENT_AUDIT','TRG_STUDENT_UPDATED','TRG_QUESTION_UPDATED'
);
-- Expected: 13  (10 auto-increment + trg_student_audit + trg_student_updated + trg_question_updated)

-- =============================================================================
-- END OF SCHEMA
-- Node.js backend .env:
--   DB_USER=kow_admin
--   DB_PASSWORD=KOW_Password_2026!
--   DB_CONNECTION_STRING=localhost:1521/XE
-- =============================================================================
