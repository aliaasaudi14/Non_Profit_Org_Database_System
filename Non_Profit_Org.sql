create database Non_Profit_Org

use Non_Profit_Org

------------------------------------            ------------------------------------
                          --CREATION OF MAIN RELATION (ENITIES)
------------------------------------            ------------------------------------

create table Employees
(
	SSN varchar (14),
	Name nvarchar(50) not null,
	Phone_No varchar(15) not null,
	Gender nvarchar(10),
	Birht_Date date,
	City nvarchar(20) not null,
	Street nvarchar(50) not null,

	constraint Employee_PK primary key (SSN)
)

GO

create table Departments
(
	Dep_No int,
	Dep_name nvarchar(20) not null,
	Hiring_Date date not null,

	constraint Department_PK primary key (Dep_No)
)

GO

create table Commitees
(
	CO_ID int,
	CO_Name nvarchar(20) not null,
	CO_Purpose nvarchar(100),

	constraint Commitee_PK primary key (CO_ID)
)

GO

create table Loans
(
	Loan_ID int,
	Status nvarchar(20) not null,
	Amount_Needed int,
	Utility_Bill bit not null,
	Lease_Agreement bit not null,
	ID_Copy bit not null,

	constraint Loan_PK primary key (Loan_ID)
)

GO

create table Projects
(
	Proj_ID int identity (1,1),
	Proj_type nvarchar(50) not null,
	Proj_name nvarchar(50) not null,
	Purpose nvarchar(200),

	constraint Project_PK primary key (Proj_ID)
)

GO

create table Beneficiaries
(
	National_ID varchar(14),
	Name nvarchar(50) not null,
	Occupation nvarchar(50) not null,
	Phone varchar(15) not null,
	Males_NO int,
	Femals_NO int,
	Address nvarchar(100) not null,

	constraint Beneficiary_PK primary key (National_ID)
)

GO

create table Relatives
(
	National_ID varchar(14),
	Name nvarchar(50) not null,
	Phone varchar(15) not null,
	Kinship_type nvarchar(20),
	Occupation nvarchar(100) not null,

	constraint Relative_PK primary key (National_ID)
)

GO

create table Support_Services
(
	Support_ID int,
	Amount int,
	Date date not null,
	Notes nvarchar(200) not null,

	constraint Support_Service_PK primary key(Support_ID)
)

GO

create table Support_Types
(
	Type_ID int,
	Name nvarchar(50) not null,

	constraint Support_Type_PK primary key (Type_ID)
)

GO

create table Home_visits
(
	Visit_ID int identity(1,1),
	Visit_Date date not null,
	Notes nvarchar(200) not null,

	constraint Home_Visit_PK primary key (Visit_ID)
)

GO

create table Awareness
(
	Message_ID int,
	Topic nvarchar(50),
	
	constraint Awareness_PK primary key (Message_ID)
)

------------------------------------            ------------------------------------
                   --CREATION OF TABLES BASED ON RELATIONSHIPS
------------------------------------            ------------------------------------

create table Beneficiaries_Benifit_SupportServices
(
	National_ID varchar(14),
	Support_ID int,

	constraint Benifit_Relationship_FK1 foreign key (National_ID)
			   references Beneficiaries (National_ID),
	constraint Benifit_Relationship_FK2 foreign key (Support_ID)
			   references Support_Services (Support_ID)
)

GO

create table HomeVisits_Cover_Awareness
(
	Visit_ID int,
	Message_ID int,

	constraint Cover_Relationship_FK1 foreign key (Visit_ID)
			   references Home_visits (Visit_ID),
	constraint Cover_Relationship_FK2 foreign key (Message_ID)
			   references Awareness (Message_ID)
)

GO

create table Beneficiaries_Recipient_HomeVisits
(
	National_ID varchar(14),
	Visit_ID int,

	constraint Recipient_Relationship_FK1 foreign key (National_ID)
			   references Beneficiaries (National_ID),
	constraint Recipient_Relationship_FK2 foreign key (Visit_ID)
			   references Home_visits (Visit_ID)
)

GO

create table Employees_Make_HomeVisits
(
	Emp_SSN varchar(14),
	Visit_ID int,

	constraint Make_Relationship_FK1 foreign key (Emp_SSN)
		       references Employees (SSN),
	constraint Make_Relationship_FK2 foreign key (Visit_ID)
			   references Home_visits (Visit_ID)
)

------------------------------------            ------------------------------------
                       --TABLES UPDATES (ADD FOREIGN KEY)
------------------------------------            ------------------------------------

alter table Employees 
add 
	Supper_SSN varchar(14) foreign key references Employees (SSN),
	Dep_NO int foreign key references Departments (Dep_No)

GO

alter table Departments 
add 
	Emp_SSN varchar(14) foreign key references Employees (SSN),
	CO_ID int foreign key references Commitees (CO_ID)

GO

alter table Loans
add 
	CO_ID int foreign key references Commitees (CO_ID),
	Proj_ID int foreign key references Projects (Proj_ID)

GO

alter table Projects
add
	Beneficiary_National_ID varchar(14) foreign key references Beneficiaries (National_ID)

GO

alter table Relatives
add 
	Beneficiary_National_ID varchar(14) foreign key references Beneficiaries (National_ID)

GO

alter table Support_Services 
add
	CO_ID int foreign key references Commitees (CO_ID),
	Support_Type_ID int foreign key references Support_Types (Type_ID)

------------------------------------            ------------------------------------
                                 --INSERTING DATA
------------------------------------            ------------------------------------

INSERT INTO Departments (Dep_No, Dep_name, Hiring_Date) VALUES 
(1, N'البحث الاجتماعي', '2020-01-01'),
(2, N'الشؤون المالية', '2020-02-15'),
(3, N'إدارة المشروعات', '2021-03-10'),
(4, N'المتابعة والرقابة', '2022-05-20'),
(5, N'العلاقات العامة', '2023-01-01');

GO

INSERT INTO Commitees (CO_ID, CO_Name, CO_Purpose) VALUES 
(101, N'لجنة القروض', N'مراجعة طلبات التمويل والضمانات'),
(102, N'لجنة كفالة الأيتام', N'تقديم الدعم الدوري للأيتام'),
(103, N'لجنة التوعية', N'تنظيم الندوات والقوافل الطبية'),
(104, N'لجنة الطوارئ', N'التعامل مع حالات الكوارث العاجلة'),
(105, N'لجنة التعليم', N'محو الأمية ودعم الطلاب');

GO

INSERT INTO Employees (SSN, Name, Phone_No, Gender, Birht_Date, City, Street, Dep_NO) VALUES 
('28501012701111', N'هناء محمود', '01012345678', N'أنثى', '1985-05-12', N'قنا', N'شارع المحطة', 1),
('28802022702222', N'منى حداد صديق', '01122334455', N'أنثى', '1988-10-20', N'قنا', N'دندرة', 1),
('29003032703333', N'سامية عبد الرحيم', '01233445566', N'أنثى', '1990-01-01', N'قنا', N'المنشية', 1);



GO

INSERT INTO Beneficiaries (National_ID, Name, Occupation, Phone, Males_NO, Femals_NO, Address) VALUES 
('28395864523442', N'زينب علي', N'طباخة', '01024568796', 3, 1, N'دندرة'),
('27011122701721', N'نصرة أحمد محمد', N'ربة منزل', '01014610836', 3, 2, N'جزيرة دندرة'),
('30009052703605', N'مها صبري عبد الوهاب', N'ربة منزل', '01026317236', 0, 2, N'دندرة'),
('30107222700667', N'ولاء إسماعيل حمزة', N'ربة منزل', '01013928282', 1, 1, N'دندرة'),
('28510150106145', N'نسمة حسين عبد الحميد', N'موظفة', '01152583093', 3, 1, N'دندرة'),
('29802262701288', N'أميمة عبد الفتاح محمود', N'خياطة', '01032851917', 2, 1, N'دندرة');

DECLARE @j INT = 1;
WHILE @j <= 44
BEGIN
    INSERT INTO Beneficiaries (National_ID, Name, Occupation, Phone, Males_NO, Femals_NO, Address)
    VALUES (
        CAST(29000000000000 + @j AS VARCHAR(14)), 
        N'مستفيد رقم ' + CAST(@j AS NVARCHAR), 
        N'أعمال حرة', 
        '012' + CAST(20000000 + @j AS VARCHAR), 
        @j % 5, @j % 4, N'قنا - منطقة ' + CAST(@j AS NVARCHAR)
    );
    SET @j = @j + 1;
END

GO

DECLARE @k INT = 1;
WHILE @k <= 50
BEGIN
    INSERT INTO Home_visits (Visit_Date, Notes)
    VALUES (DATEADD(DAY, -@k, GETDATE()), N'ملاحظات الزيارة رقم ' + CAST(@k AS NVARCHAR));
    SET @k = @k + 1;
END

GO

INSERT INTO Employees_Make_HomeVisits (Emp_SSN, Visit_ID)
SELECT TOP 50 SSN, ROW_NUMBER() OVER (ORDER BY SSN)
FROM Employees CROSS JOIN Home_visits WHERE Home_visits.Visit_ID <= 50;

INSERT INTO Beneficiaries_Recipient_HomeVisits (National_ID, Visit_ID)
SELECT TOP 50 National_ID, ROW_NUMBER() OVER (ORDER BY National_ID)
FROM Beneficiaries CROSS JOIN Home_visits WHERE Home_visits.Visit_ID <= 50;

GO

INSERT INTO Projects (Proj_type, Proj_name, Purpose, Beneficiary_National_ID) 
SELECT TOP 20 N'مشروع صغير', N'مشروع ' + Name, N'تحسين الدخل', National_ID FROM Beneficiaries;

INSERT INTO Support_Types (Type_ID, Name) VALUES (1, N'دعم نقدي'), (2, N'دعم طبي');

INSERT INTO Loans (Loan_ID, Status, Amount_Needed, Utility_Bill, Lease_Agreement, ID_Copy, CO_ID, Proj_ID)
SELECT ROW_NUMBER() OVER (ORDER BY Proj_ID) + 7000, N'مقبول', 5000, 1, 1, 1, 101, Proj_ID FROM Projects;

GO

DELETE FROM Beneficiaries_Benifit_SupportServices;
DELETE FROM Support_Services;
DELETE FROM Support_Types;

INSERT INTO Support_Types (Type_ID, Name) VALUES 
(1, N'دعم نقدي'),
(2, N'دعم طبي'),
(3, N'دعم غذائي'),
(4, N'دعم تعليمي');

DELETE FROM HomeVisits_Cover_Awareness;
DELETE FROM Awareness;
INSERT INTO Awareness (Message_ID, Topic) VALUES 
(1, N'أهمية النظافة الشخصية والوقاية من الأمراض'),
(2, N'تنظيم الأسرة والصحة الإنجابية'),
(3, N'أهمية التعليم ومحو الأمية للكبار'),
(4, N'الوقاية من فيروس كورونا والأمراض المعدية'),
(5, N'تربية الأطفال والتغذية السليمة'),
(6, N'كيفية البدء في مشروع صغير من المنزل'),
(7, N'التعامل مع ذوي الاحتياجات الخاصة في الأسرة'),
(8, N'مخاطر الزواج المبكر'),
(9, N'ترشيد استهلاك المياه والكهرباء'),
(10, N'حقوق المرأة والقوانين المتعلقة بها');


DECLARE @s INT = 1;
WHILE @s <= 50
BEGIN
    INSERT INTO Support_Services (Support_ID, Amount, [Date], Notes, CO_ID, Support_Type_ID)
    VALUES (@s, (ABS(CHECKSUM(NEWID())) % 500) + 100, DATEADD(DAY, -@s, GETDATE()), 
            N'ملاحظات دعم رقم ' + CAST(@s AS NVARCHAR), 101, ((@s - 1) % 4) + 1);
    SET @s = @s + 1;
END


INSERT INTO Beneficiaries_Benifit_SupportServices (National_ID, Support_ID)
SELECT TOP 50 National_ID, ROW_NUMBER() OVER (ORDER BY National_ID)
FROM Beneficiaries CROSS JOIN Support_Services WHERE Support_Services.Support_ID <= 50;

INSERT INTO HomeVisits_Cover_Awareness (Visit_ID, Message_ID)
SELECT Visit_ID, ((Visit_ID - 1) % 10) + 1 FROM Home_visits WHERE Visit_ID <= 50;
GO

UPDATE Employees
SET Supper_SSN = '28501012701111' 
WHERE Dep_NO = 1 AND SSN <> '28501012701111';

UPDATE Employees
SET Supper_SSN = '28802022702222' 
WHERE Dep_NO <> 1 AND SSN <> '28802022702222';
GO


INSERT INTO Relatives (National_ID, Name, Phone, Kinship_type, Occupation, Beneficiary_National_ID) VALUES 
('28001012709991', N'علي جاد الرب', '01258789697', N'زوج', N'عامل', '28395864523442'),
('27005052708882', N'أحمد عبد المجيد بغدادي', '01014610836', N'زوج', N'أعمال حرة', '27011122701721'),
('29003032707773', N'حمادة بركات يوسف', '01026317236', N'زوج', N'موظف', '30009052703605'),
('28504042706664', N'محمد بركات يوسف', '01060548370', N'زوج', N'سائق', '30107222700667'),
('28202022705555', N'علي رشيدي جاد الله', '01152593093', N'زوج', N'عامل مياومة', '28510150106145'),
('29506062704446', N'محمود عبد الصبور', '01032851917', N'زوج', N'ترزي', '29802262701288');

DECLARE @r INT = 1;
WHILE @r <= 44
BEGIN
   
    DECLARE @BenID VARCHAR(14);
    SELECT TOP 1 @BenID = National_ID 
    FROM Beneficiaries 
    WHERE National_ID NOT IN ('28395864523442', '27011122701721', '30009052703605', '30107222700667', '28510150106145', '29802262701288')
    ORDER BY NEWID();

    INSERT INTO Relatives (National_ID, Name, Phone, Kinship_type, Occupation, Beneficiary_National_ID)
    VALUES (
        CAST(25000000000000 + @r AS VARCHAR(14)), 
        N'قريب مستفيدة رقم ' + CAST(@r AS NVARCHAR), 
        '015' + CAST(10000000 + @r AS VARCHAR), 
        N'ابن', 
        N'طالب', 
        @BenID
    );
    SET @r = @r + 1;
END
GO

------------------------------------            ------------------------------------
                                    --QUERIES--
------------------------------------            ------------------------------------

--SELTEC STATMENT FOR ALL TABLES TO SHOW DATA
select *
from Awareness

select *
from Beneficiaries

select *
from Beneficiaries_Benifit_SupportServices

select *
from Beneficiaries_Recipient_HomeVisits

select *
from Commitees

select *
from Employees

select *
from Employees_Make_HomeVisits

select *
from Home_visits

select *
from HomeVisits_Cover_Awareness

select *
from Loans

select *
from Projects

select *
from Relatives

select *
from Support_Services

select *
from Support_Types


