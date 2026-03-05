USE Non_Profit_Org;
GO

/* ============================================================
   (A) Add Column: Visit_Status to Home_visits (if not exists)
   Purpose: store visit evaluation: Eligible / Pending / Not Eligible
   ============================================================ */
IF COL_LENGTH('dbo.Home_visits', 'Visit_Status') IS NULL
BEGIN
    ALTER TABLE dbo.Home_visits
    ADD Visit_Status NVARCHAR(20) NULL;
END
GO

/* Constraint: Allowed values for Visit_Status (if not exists) */
IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_HomeVisits_Status'
      AND parent_object_id = OBJECT_ID('dbo.Home_visits')
)
BEGIN
    ALTER TABLE dbo.Home_visits
    ADD CONSTRAINT CK_HomeVisits_Status
    CHECK (Visit_Status IN (N'Eligible', N'Not Eligible', N'Pending') OR Visit_Status IS NULL);
END
GO


/* ============================================================
   (1) Function: Get Eligibility Status for a Beneficiary
   Returns: YES / NO / PENDING / UNKNOWN based on latest visit
   ============================================================ */
IF OBJECT_ID('dbo.getEligibilityStatus_Beneficiary', 'FN') IS NOT NULL
    DROP FUNCTION dbo.getEligibilityStatus_Beneficiary;
GO

CREATE FUNCTION dbo.getEligibilityStatus_Beneficiary (@National_ID VARCHAR(14))
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @result VARCHAR(10);

    SELECT TOP 1
        @result =
            CASE hv.Visit_Status
                WHEN N'Eligible' THEN 'YES'
                WHEN N'Not Eligible' THEN 'NO'
                WHEN N'Pending' THEN 'PENDING'
                ELSE 'UNKNOWN'
            END
    FROM dbo.Beneficiaries_Recipient_HomeVisits br
    JOIN dbo.Home_visits hv ON hv.Visit_ID = br.Visit_ID
    WHERE br.National_ID = @National_ID
    ORDER BY hv.Visit_Date DESC, hv.Visit_ID DESC;

    RETURN ISNULL(@result, 'UNKNOWN');
END;
GO


/* ============================================================
   (2) Trigger: Prevent Deleting a Beneficiary With Visits
   Blocks delete if beneficiary has related Home Visits
   ============================================================ */
IF OBJECT_ID('dbo.prevent_delete_beneficiary_with_visits', 'TR') IS NOT NULL
    DROP TRIGGER dbo.prevent_delete_beneficiary_with_visits;
GO

CREATE TRIGGER dbo.prevent_delete_beneficiary_with_visits
ON dbo.Beneficiaries
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dbo.Beneficiaries_Recipient_HomeVisits br
        JOIN deleted d ON d.National_ID = br.National_ID
    )
    BEGIN
        RAISERROR (N'Cannot delete beneficiary with visits', 16, 1);
        RETURN;
    END;

    DELETE b
    FROM dbo.Beneficiaries b
    JOIN deleted d ON d.National_ID = b.National_ID;
END;
GO


/* ============================================================
   (3) Function: Get Total Support Amount For a Service
   Input: Support_ID -> Output: total Amount (DECIMAL)
   ============================================================ */
IF OBJECT_ID('dbo.getTotalSupportForService', 'FN') IS NOT NULL
    DROP FUNCTION dbo.getTotalSupportForService;
GO

CREATE FUNCTION dbo.getTotalSupportForService (@Support_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);

    SELECT @total = SUM(CAST(Amount AS DECIMAL(10,2)))
    FROM dbo.Support_Services
    WHERE Support_ID = @Support_ID;

    RETURN ISNULL(@total, 0);
END;
GO


/* ============================================================
   (4) Function: Get Support Type For a Service
   Input: Support_ID -> Output: Support Type Name
   ============================================================ */
IF OBJECT_ID('dbo.getSupportTypeForService', 'FN') IS NOT NULL
    DROP FUNCTION dbo.getSupportTypeForService;
GO

CREATE FUNCTION dbo.getSupportTypeForService (@Support_ID INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @type NVARCHAR(50);

    SELECT TOP 1 @type = st.Name
    FROM dbo.Support_Services ss
    JOIN dbo.Support_Types st ON st.Type_ID = ss.Support_Type_ID
    WHERE ss.Support_ID = @Support_ID;

    RETURN @type;
END;
GO


/* ============================================================
   (5) Inline TVF: Get Support Info For a Service (amount + type)
   ============================================================ */
IF OBJECT_ID('dbo.getSupportInfoForService', 'IF') IS NOT NULL
    DROP FUNCTION dbo.getSupportInfoForService;
GO

CREATE FUNCTION dbo.getSupportInfoForService (@Support_ID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        CAST(ss.Amount AS DECIMAL(10,2)) AS amount,
        st.Name AS [type]
    FROM dbo.Support_Services ss
    JOIN dbo.Support_Types st ON st.Type_ID = ss.Support_Type_ID
    WHERE ss.Support_ID = @Support_ID
);
GO


/* ============================================================
   (6) View: Home Visit Details (Visit + Employee + Beneficiary)
   ============================================================ */
IF OBJECT_ID('dbo.vw_HomeVisitDetails', 'V') IS NOT NULL
    DROP VIEW dbo.vw_HomeVisitDetails;
GO

CREATE VIEW dbo.vw_HomeVisitDetails
AS
SELECT
    hv.Visit_ID,
    hv.Visit_Date,
    hv.Visit_Status,
    hv.Notes AS visit_notes,

    e.SSN AS employee_ssn,
    e.Name AS employee_name,
    e.City AS employee_city,
    e.Phone_No AS employee_phone,

    b.National_ID,
    b.Name AS beneficiary_name,
    b.Phone AS beneficiary_phone,
    b.Occupation,
    b.Males_NO,
    b.Femals_NO,
    b.Address
FROM dbo.Home_visits hv
JOIN dbo.Employees_Make_HomeVisits emhv ON emhv.Visit_ID = hv.Visit_ID
JOIN dbo.Employees e ON e.SSN = emhv.Emp_SSN
JOIN dbo.Beneficiaries_Recipient_HomeVisits brhv ON brhv.Visit_ID = hv.Visit_ID
JOIN dbo.Beneficiaries b ON b.National_ID = brhv.National_ID;
GO


/* ============================================================
   (7) Procedure: Employee Visit Report
   Input: Emp_SSN -> Returns visits done by this employee
   ============================================================ */
IF OBJECT_ID('dbo.sp_EmployeeVisitReport', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_EmployeeVisitReport;
GO

CREATE PROCEDURE dbo.sp_EmployeeVisitReport
    @Emp_SSN VARCHAR(14)
AS
BEGIN
    SELECT
        v.Visit_ID,
        v.Visit_Date,
        v.Visit_Status,
        v.visit_notes,
        v.employee_name,
        v.National_ID,
        v.beneficiary_name,
        v.beneficiary_phone,
        v.Males_NO,
        v.Femals_NO,
        v.Address
    FROM dbo.vw_HomeVisitDetails v
    WHERE v.employee_ssn = @Emp_SSN
    ORDER BY v.Visit_Date DESC, v.Visit_ID DESC;
END;
GO


/* ============================================================
   (8) Inline TVF: Beneficiary Visit Summary
   Total visits + last visit + counts per status
   ============================================================ */
IF OBJECT_ID('dbo.fn_BeneficiaryVisitSummary', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_BeneficiaryVisitSummary;
GO

CREATE FUNCTION dbo.fn_BeneficiaryVisitSummary (@National_ID VARCHAR(14))
RETURNS TABLE
AS
RETURN
(
    SELECT
        b.National_ID,
        b.Name AS beneficiary_name,
        b.Phone,
        b.Occupation,
        b.Males_NO,
        b.Femals_NO,
        b.Address,

        COUNT(hv.Visit_ID) AS total_visits,
        MAX(hv.Visit_Date) AS last_visit_date,

        SUM(CASE WHEN hv.Visit_Status = N'Eligible' THEN 1 ELSE 0 END) AS eligible_count,
        SUM(CASE WHEN hv.Visit_Status = N'Pending' THEN 1 ELSE 0 END) AS pending_count,
        SUM(CASE WHEN hv.Visit_Status = N'Not Eligible' THEN 1 ELSE 0 END) AS not_eligible_count
    FROM dbo.Beneficiaries b
    LEFT JOIN dbo.Beneficiaries_Recipient_HomeVisits br ON br.National_ID = b.National_ID
    LEFT JOIN dbo.Home_visits hv ON hv.Visit_ID = br.Visit_ID
    WHERE b.National_ID = @National_ID
    GROUP BY
        b.National_ID, b.Name, b.Phone, b.Occupation, b.Males_NO, b.Femals_NO, b.Address
);
GO


/* ============================================================
   (9) Function: Beneficiary Priority Score
   Based on: latest Visit_Status + family size (Males_NO + Femals_NO)
   ============================================================ */
IF OBJECT_ID('dbo.fn_BeneficiaryPriorityScore', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_BeneficiaryPriorityScore;
GO

CREATE FUNCTION dbo.fn_BeneficiaryPriorityScore (@National_ID VARCHAR(14))
RETURNS INT
AS
BEGIN
    DECLARE @family_size INT =
        (
            SELECT ISNULL(Males_NO,0) + ISNULL(Femals_NO,0)
            FROM dbo.Beneficiaries
            WHERE National_ID = @National_ID
        );

    DECLARE @last_status NVARCHAR(20) =
        (
            SELECT TOP 1 hv.Visit_Status
            FROM dbo.Beneficiaries_Recipient_HomeVisits br
            JOIN dbo.Home_visits hv ON hv.Visit_ID = br.Visit_ID
            WHERE br.National_ID = @National_ID
            ORDER BY hv.Visit_Date DESC, hv.Visit_ID DESC
        );

    DECLARE @score INT =
        CASE @last_status
            WHEN N'Eligible' THEN 50
            WHEN N'Pending' THEN 20
            WHEN N'Not Eligible' THEN 0
            ELSE 0
        END
        + (ISNULL(@family_size,0) * 5);

    RETURN @score;
END;
GO


/* ============================================================
   (10) Function: Count Employees in a Department
   Input: Dep_No -> Output: employee count
   ============================================================ */
IF OBJECT_ID('dbo.count_employees_in_department', 'FN') IS NOT NULL
    DROP FUNCTION dbo.count_employees_in_department;
GO

CREATE FUNCTION dbo.count_employees_in_department (@Dep_No INT)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;

    SELECT @count = COUNT(*)
    FROM dbo.Employees
    WHERE Dep_NO = @Dep_No;

    RETURN ISNULL(@count, 0);
END;
GO


/* ============================================================
   (11) Function: Get Total Visits for a Beneficiary
   Input: National_ID -> Output: total visits count
   ============================================================ */
IF OBJECT_ID('dbo.get_total_visits_beneficiary', 'FN') IS NOT NULL
    DROP FUNCTION dbo.get_total_visits_beneficiary;
GO

CREATE FUNCTION dbo.get_total_visits_beneficiary (@National_ID VARCHAR(14))
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.Beneficiaries_Recipient_HomeVisits
    WHERE National_ID = @National_ID;

    RETURN ISNULL(@total, 0);
END;
GO


/* ============================================================
   (12) Procedure: Assign Employee to a Department
   Input: SSN + Dep_No -> Updates employee department
   ============================================================ */
IF OBJECT_ID('dbo.assign_employee_department', 'P') IS NOT NULL
    DROP PROCEDURE dbo.assign_employee_department;
GO

CREATE PROCEDURE dbo.assign_employee_department
    @SSN VARCHAR(14),
    @Dep_No INT
AS
BEGIN
    UPDATE dbo.Employees
    SET Dep_NO = @Dep_No
    WHERE SSN = @SSN;
END;
GO


/* ============================================================
   (TEST QUERIES) Run these after the script finishes
   ============================================================ */
-- 1) Eligibility
-- SELECT dbo.getEligibilityStatus_Beneficiary('28395864523442') AS eligibility;

-- 2) Support totals & type
-- SELECT dbo.getTotalSupportForService(1) AS total_amount;
-- SELECT dbo.getSupportTypeForService(1) AS support_type;
-- SELECT * FROM dbo.getSupportInfoForService(1);

-- 3) View preview
-- SELECT TOP 20 * FROM dbo.vw_HomeVisitDetails ORDER BY Visit_Date DESC;

-- 4) Employee report
-- EXEC dbo.sp_EmployeeVisitReport '28501012701111';

-- 5) Summary & priority
-- SELECT * FROM dbo.fn_BeneficiaryVisitSummary('28395864523442');
-- SELECT TOP 20 National_ID, Name, dbo.fn_BeneficiaryPriorityScore(National_ID) AS score
-- FROM dbo.Beneficiaries
-- ORDER BY score DESC;

-- 6) Department count
-- SELECT dbo.count_employees_in_department(1) AS emp_count;

-- 7) Total visits count
-- SELECT dbo.get_total_visits_beneficiary('28395864523442') AS total_visits;

-- 8) Assign department
-- EXEC dbo.assign_employee_department @SSN='29003032703333', @Dep_No=3;