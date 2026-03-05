--1) View: تفاصيل الدعم (Support) لكل مستفيد + نوع الدعم + اللجنة
CREATE OR ALTER VIEW dbo.vw_SupportDetails
AS
SELECT
    ss.Support_ID,
    ss.Amount,
    ss.[Date]        AS Support_Date,
    ss.Notes         AS Support_Notes,

    st.Type_ID,
    st.[Name]        AS Support_Type_Name,

    c.[CO_ID],
    c.CO_Name        AS Committee_Name,

    b.National_ID,
    b.[Name]         AS Beneficiary_Name,
    b.Phone          AS Beneficiary_Phone,
    b.Address        AS Beneficiary_Address,
    b.Males_NO,
    b.Femals_NO
FROM dbo.Support_Services ss
JOIN dbo.Support_Types st
    ON st.Type_ID = ss.Support_Type_ID
JOIN [dbo].[Commitees] c
    ON c.CO_ID = ss.CO_ID
JOIN dbo.Beneficiaries_Benifit_SupportServices bbs
    ON bbs.Support_ID = ss.Support_ID
JOIN dbo.Beneficiaries b
    ON b.National_ID = bbs.National_ID;
GO

SELECT * FROM dbo.vw_SupportDetails;

--1.1) إجمالي عدد مرات الدعم + إجمالي المبالغ + آخر دعم لكل مستفيد (زي Total Visits)
SELECT
    National_ID,
    Beneficiary_Name,
    COUNT(Support_ID)           AS total_support_times,
    SUM(Amount)                 AS total_amount,
    MAX(Support_Date)           AS last_support_date
FROM dbo.vw_SupportDetails
GROUP BY National_ID, Beneficiary_Name
ORDER BY total_amount DESC, last_support_date DESC;

--1.2) دعم حسب النوع (مين أخد “دعم غذائي/مادي…” وإجمالي كل نوع)
SELECT
    Support_Type_Name,
    COUNT(*)          AS total_cases,
    SUM(Amount)       AS total_amount
FROM dbo.vw_SupportDetails
GROUP BY Support_Type_Name
ORDER BY total_amount DESC;

--1.3) آخر دعم لكل مستفيد + نوعه (آخر قرار/حالة)
WITH x AS
(
    SELECT
        National_ID,
        Beneficiary_Name,
        Support_ID,
        Support_Date,
        Support_Type_Name,
        Amount,
        ROW_NUMBER() OVER
        (
            PARTITION BY National_ID
            ORDER BY Support_Date DESC, Support_ID DESC
        ) AS rn
    FROM dbo.vw_SupportDetails
)
SELECT
    National_ID,
    Beneficiary_Name,
    Support_Date,
    Support_Type_Name,
    Amount
FROM x
WHERE rn = 1
ORDER BY Support_Date DESC;

--2)  المستفيدين اللي عندهم أقارب كتير (تفاصيل “عيلة” زي شغلك)
SELECT
    b.National_ID,
    b.[Name] AS Beneficiary_Name,
    COUNT(r.National_ID) AS relatives_count
FROM dbo.Beneficiaries b
LEFT JOIN dbo.Relatives r
    ON r.Beneficiary_National_ID = b.National_ID
GROUP BY b.National_ID, b.[Name]
ORDER BY relatives_count DESC;

--3) View: تفاصيل القروض + المشروع + المستفيد + اللجنة
CREATE OR ALTER VIEW dbo.vw_LoanDetails
AS
SELECT
    l.Loan_ID,
    l.Status,
    l.Amount_Needed,
    l.Utility_Bill,
    l.Lease_Agreement,
    l.ID_Copy,

    c.CO_ID,
    c.CO_Name AS Committee_Name,

    p.Proj_ID,
    p.Proj_type,
    p.Proj_name,
    p.Purpose,
    p.Beneficiary_National_ID,

    b.[Name]  AS Beneficiary_Name,
    b.Phone   AS Beneficiary_Phone,
    b.Address AS Beneficiary_Address
FROM dbo.Loans l
JOIN dbo.Commitees c
    ON c.CO_ID = l.CO_ID
JOIN dbo.Projects p
    ON p.Proj_ID = l.Proj_ID
JOIN dbo.Beneficiaries b
    ON b.National_ID = p.Beneficiary_National_ID;
GO

SELECT * FROM dbo.vw_LoanDetails;

--3.1 الناس المستحقة الدعم المالي 
SELECT
    Status,
    COUNT(*)        AS total_loans,
    SUM(Amount_Needed) AS total_amount
FROM dbo.vw_LoanDetails
GROUP BY Status
ORDER BY total_amount DESC;

--4) Stored Procedure: تقرير كامل لمستفيد واحد 
CREATE OR ALTER PROCEDURE dbo.sp_BeneficiaryFullReport
    @National_ID VARCHAR(14)
AS
BEGIN
    -- 1) بيانات المستفيد
    SELECT * 
    FROM dbo.Beneficiaries
    WHERE National_ID = @National_ID;

    -- 2) الدعم
    SELECT
        Support_ID, Support_Date, Support_Type_Name, Amount, Committee_Name, Support_Notes
    FROM dbo.vw_SupportDetails
    WHERE National_ID = @National_ID
    ORDER BY Support_Date DESC, Support_ID DESC;

    -- 3) المشاريع
    SELECT
        Proj_ID, Proj_type, Proj_name, Purpose
    FROM dbo.Projects
    WHERE Beneficiary_National_ID = @National_ID
    ORDER BY Proj_ID DESC;

    -- 4) القروض
    SELECT
        Loan_ID, Status, Amount_Needed, Proj_name, Committee_Name
    FROM dbo.vw_LoanDetails
    WHERE Beneficiary_National_ID = @National_ID
    ORDER BY Loan_ID DESC;
END;
GO

EXEC dbo.sp_BeneficiaryFullReport '29000000000001';  -- مثال
--5) Function: Summary سريع لمستفيد  fn_FamilyVisitSummary)
CREATE OR ALTER FUNCTION dbo.fn_BeneficiarySummary (@National_ID VARCHAR(14))
RETURNS TABLE
AS
RETURN
(
    SELECT
        b.National_ID,
        b.[Name],
        b.Phone,
        b.Address,
        b.Males_NO,
        b.Femals_NO,

        -- Support summary
        (SELECT COUNT(*) FROM dbo.vw_SupportDetails s WHERE s.National_ID = b.National_ID) AS support_times,
        (SELECT ISNULL(SUM(Amount),0) FROM dbo.vw_SupportDetails s WHERE s.National_ID = b.National_ID) AS support_total_amount,
        (SELECT MAX(Support_Date) FROM dbo.vw_SupportDetails s WHERE s.National_ID = b.National_ID) AS last_support_date,

        -- Projects / Loans summary
        (SELECT COUNT(*) FROM dbo.Projects p WHERE p.Beneficiary_National_ID = b.National_ID) AS projects_count,
        (SELECT COUNT(*) FROM dbo.vw_LoanDetails l WHERE l.Beneficiary_National_ID = b.National_ID) AS loans_count,
        (SELECT COUNT(*) FROM dbo.vw_LoanDetails l WHERE l.Beneficiary_National_ID = b.National_ID AND l.Status IN (N'Pending', N'قيد', N'قيد المراجعة')) AS pending_loans
    FROM dbo.Beneficiaries b
    WHERE b.National_ID = @National_ID
);
GO

SELECT * FROM dbo.fn_BeneficiarySummary('29000000000001');

/*6) Priority Score جديدة

فكرة السكور هنا:

دعم أكتر = سكور أعلى

Pending loans = سكور أعلى (عشان في حالة متابعة)

حجم الأسرة (Males+Females) = سكور أعلى
*/
CREATE OR ALTER FUNCTION dbo.fn_BeneficiaryPriorityScore (@National_ID VARCHAR(14))
RETURNS INT
AS
BEGIN
    DECLARE @family_size INT =
        (SELECT ISNULL(Males_NO,0) + ISNULL(Femals_NO,0)
         FROM dbo.Beneficiaries
         WHERE National_ID = @National_ID);

    DECLARE @support_total INT =
        (SELECT ISNULL(SUM(Amount),0)
         FROM dbo.vw_SupportDetails
         WHERE National_ID = @National_ID);

    DECLARE @pending_loans INT =
        (SELECT COUNT(*)
         FROM dbo.vw_LoanDetails
         WHERE Beneficiary_National_ID = @National_ID
           AND Status IN (N'Pending', N'قيد', N'قيد المراجعة'));

    DECLARE @score INT =
        (@family_size * 5)
        + CASE 
            WHEN @support_total >= 1000 THEN 30
            WHEN @support_total >= 500  THEN 15
            WHEN @support_total >  0    THEN 5
            ELSE 0
          END
        + (@pending_loans * 20);

    RETURN @score;
END;
GO

SELECT
    National_ID,
    [Name],
    dbo.fn_BeneficiaryPriorityScore(National_ID) AS priority_score
FROM dbo.Beneficiaries
ORDER BY priority_score DESC;