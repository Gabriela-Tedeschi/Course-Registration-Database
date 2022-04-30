--**********************************************************************************************--
-- Title: ITFnd130Final
-- Author: Gabriela Tedeschi
-- Desc: This file demonstrates how to design and create 
--       tables, views, and stored procedures
-- Change Log: When,Who,What
-- 2021-06-10,G Tedeschi,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'ITFnd130FinalDB_GTedeschi')
	 Begin 
	  Alter Database [ITFnd130FinalDB_GTedeschi] set Single_user With Rollback Immediate;
	  Drop Database ITFnd130FinalDB_GTedeschi;
	 End
	Create Database ITFnd130FinalDB_GTedeschi;
End Try
Begin Catch
	Print Error_Number();
End Catch
go

Use ITFnd130FinalDB_GTedeschi;
GO

-- Create Tables (Module 01)-- 
-- Create Courses table --
CREATE TABLE Courses (
	CourseID int Identity(1,1) NOT NULL,
	CourseName nvarchar(100) NOT NULL,
	CourseStartDate date,
	CourseEndDate date,
	CourseMeetingDays nvarchar(100),
	CourseStartTime time,
	CourseEndTime time,
	CourseCurrentPrice money
);
GO

-- Create Students table --
CREATE TABLE Students (
	StudentID int Identity(1,1) NOT NULL,
	StudentFirstName nvarchar(100) NOT NULL,
	StudentLastName nvarchar(100) NOT NULL,
	StudentEmail nvarchar(100) NOT NULL,
	StudentPhone nvarchar(100),
	StudentAddress nvarchar(100) NOT NULL,
	StudentCity nvarchar(100) NOT NULL,
	StudentState char(2) NOT NULL,
	StudentZipCode int NOT NULL
);
GO

-- Create Registration table --
CREATE TABLE Registration (
	RegistrationID int Identity(1,1) NOT NULL,
	StudentID int NOT NULL,
	CourseID int NOT NULL,
	RegistrationDate date NOT NULL,
	RegistrationPrice money NOT NULL
);
GO

-- Add Constraints (Module 02) --
-- Add constraints to Courses table --
BEGIN
ALTER TABLE Courses
	ADD CONSTRAINT Pk_Courses
	Primary Key Clustered (CourseID);

ALTER TABLE Courses
	ADD CONSTRAINT Unq_CourseName
	Unique (CourseName);

ALTER TABLE Courses
	ADD CONSTRAINT Ck_CourseCurrentPriceZeroOrHigher
	Check(CourseCurrentPrice >= 0);
END
GO

-- Add constraints to Students table --
BEGIN
ALTER TABLE Students
	ADD CONSTRAINT Pk_Students
	Primary Key Clustered (StudentID);

ALTER TABLE Students
	ADD CONSTRAINT Unq_StudentEmail
	Unique (StudentEmail);

ALTER TABLE Students
	ADD CONSTRAINT Ck_StudentEmail
	Check (StudentEmail LIKE '%_@%_.%_');

ALTER TABLE Students
	ADD CONSTRAINT Ck_StudentPhone
	Check (StudentPhone LIKE '([0-9][0-9][0-9])-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]');
END
GO

-- Add constraints to Registration table --
-- Create a UDF I will use for RegistrationDate check constraint --
CREATE FUNCTION dbo.fGetCourseStartDate (@CourseID int)
RETURNS date
AS
BEGIN
	RETURN (SELECT CourseStartDate
			FROM Courses
			WHERE CourseID = @CourseID);
END
GO

-- Add constraints --
BEGIN
ALTER TABLE Registration
	ADD CONSTRAINT Pk_Registration
	Primary Key Clustered (RegistrationID);

ALTER TABLE Registration
	ADD CONSTRAINT Fk_RegistrationToStudents
	Foreign Key (StudentID) References Students(StudentID);

ALTER TABLE Registration
	ADD CONSTRAINT Fk_RegistrationToCourses
	Foreign Key (CourseID) References Courses(CourseID);

ALTER TABLE Registration
	ADD CONSTRAINT Default_RegistrationDate
	Default GetDate() For RegistrationDate;

ALTER TABLE Registration
	ADD CONSTRAINT Ck_RegistrationDate
	Check (RegistrationDate <= dbo.fGetCourseStartDate(CourseID));

ALTER TABLE Registration
	ADD CONSTRAINT Ck_RegistrationPrice
	Check (RegistrationPrice >=0);
END
GO

-- Add Views (Module 03 and 06) --
-- Create base views --
-- Create Courses base view --
CREATE VIEW vCourses
WITH SCHEMABINDING
AS
	SELECT
		CourseID,
		CourseName,
		CourseStartDate,
		CourseEndDate,
		CourseMeetingDays,
		CourseStartTime,
		CourseEndTime,
		CourseCurrentPrice
	FROM dbo.Courses;
GO

-- Create Students base view --
CREATE VIEW vStudents
WITH SCHEMABINDING
AS
	SELECT
		StudentID,
		StudentFirstName,
		StudentLastName,
		StudentEmail,
		StudentPhone,
		StudentAddress,
		StudentCity,
		StudentState,
		StudentZipCode
	FROM dbo.Students;
GO

-- Create Registration base view --
CREATE VIEW vRegistration
WITH SCHEMABINDING
AS
	SELECT
		RegistrationID,
		StudentID,
		CourseID,
		RegistrationDate,
		RegistrationPrice
	FROM dbo.Registration;
GO

-- Create reporting views --
-- Create view to show number of students per course --
CREATE VIEW vCourseEnrollment
AS
	SELECT
		c.CourseName,
		[NumberOfStudents] = Count(r.StudentID)
	FROM Courses AS c
	JOIN Registration AS r
		ON c.CourseID = r.CourseID
	GROUP BY c.CourseName;
GO

-- Create view to show number of courses each student registered for --
CREATE VIEW vStudentCourseload
AS
	SELECT
		[StudentName] = s.StudentFirstName + ' ' + s.StudentLastName,
		[NumberOfCourses] = Count(r.CourseID)
	FROM Students AS s
	JOIN Registration as r
		ON s.StudentID = r.StudentID
	GROUP BY s.StudentFirstName + ' ' + s.StudentLastName;
GO

-- Create view to show students' Winter 2017 tuition --
CREATE VIEW vStudentWinter2017Tuition
AS
	SELECT
		[StudentName] = s.StudentFirstName + ' ' + s.StudentLastName,
		[TotalTuition] = Sum(r.RegistrationPrice)
	FROM Students AS s
	JOIN Registration AS r
		ON s.StudentID = r.StudentID
	JOIN Courses AS c
		ON r.CourseID = c.CourseID
	WHERE c.CourseStartDate BETWEEN '2017-01-01' AND '2017-03-31'
	GROUP BY s.StudentFirstName + ' ' + s.StudentLastName;
GO

--< Test Tables by adding Sample Data >-- 
-- Testing Courses table --
BEGIN TRY
BEGIN TRAN
	INSERT INTO Courses (
		CourseName, 
		CourseStartDate, 
		CourseEndDate, 
		CourseMeetingDays, 
		CourseStartTime,
		CourseEndTime,
		CourseCurrentPrice)
	Values (
		'SQL1 - Winter 2017',
		'2017-01-10',
		'2017-01-24',
		'Tues',
		'18:00:00',
		'20:50:00',
		399.00),
			(
		'SQL2 - Winter 2017',
		'2017-01-31',
		'2017-02-14',
		'Tues',
		'18:00:00',
		'20:50:00',
		399.00);
COMMIT TRAN
END TRY
BEGIN CATCH
	PRINT Error_Message()
	PRINT 'Check data types and table constraints'
END CATCH;
GO

-- Testing Students Table --
BEGIN TRY
BEGIN TRAN
	INSERT INTO Students (
		StudentFirstName,
		StudentLastName,
		StudentEmail,
		StudentPhone,
		StudentAddress,
		StudentCity,
		StudentState,
		StudentZipCode)
	Values (
		'Bob',
		'Smith',
		'Bsmith@HipMail.com',
		'(206)-111-2222',
		'123 Main St.',
		'Seattle',
		'WA',
		98001),
			(
		'Sue',
		'Jones',
		'SueJones@YaYou.com',
		'(206)-231-4321',
		'333 1st Ave.',
		'Seattle',
		'WA',
		98001);
COMMIT TRAN
END TRY
BEGIN CATCH
	PRINT Error_Message()
	PRINT 'Check data types and table constraints'
END CATCH;
GO

-- Testing Registration Table --
BEGIN TRY
BEGIN TRAN
	INSERT INTO Registration (
		StudentID,
		CourseID,
		RegistrationDate,
		RegistrationPrice)
	Values	(
		1,
		1,
		'2017-01-03',
		399.00),
			(
		1,
		2,
		'2017-01-12',
		399.00),
			(
		2,
		1,
		'2016-12-14',
		349.00),
			(
		2,
		2,
		'2016-12-14',
		349.00);
COMMIT TRAN
END TRY
BEGIN CATCH
	Print Error_Message()
	Print 'Check data types and table constraints'
END CATCH;
GO

-- Add Stored Procedures (Module 04, 08, and 09) --
-- Create Sprocs for Courses table --
-- Create pInsCourses --
CREATE PROC pInsCourses (
	@CourseName nvarchar(100),
	@CourseStartDate date,
	@CourseEndDate date,
	@CourseMeetingDays nvarchar(100),
	@CourseStartTime time,
	@CourseEndTime time,
	@CourseCurrentPrice money)
 -- Author: G Tedeschi
 -- Desc: Processes inserts into Courses
 -- Change Log: When,Who,What
 -- 2021-06-10,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		INSERT INTO Courses (
			CourseName,
			CourseStartDate,
			CourseEndDate,
			CourseMeetingDays,
			CourseStartTime,
			CourseEndTime,
			CourseCurrentPrice)
		Values (
			@CourseName,
			@CourseStartDate,
			@CourseEndDate,
			@CourseMeetingDays,
			@CourseStartTime,
			@CourseEndTime,
			@CourseCurrentPrice);
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pUpdCourses --
CREATE PROC pUpdCourses (
	@CourseID int,
	@CourseName nvarchar(100),
	@CourseStartDate date,
	@CourseEndDate date,
	@CourseMeetingDays nvarchar(100),
	@CourseStartTime time,
	@CourseEndTime time,
	@CourseCurrentPrice money)
 -- Author: G Tedeschi
 -- Desc: Processes updates to Courses
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		UPDATE Courses
		SET CourseName = @CourseName,
			CourseStartDate = @CourseStartDate,
			CourseEndDate = @CourseEndDate,
			CourseMeetingDays = @CourseMeetingDays,
			CourseStartTime = @CourseStartTime,
			CourseEndTime = @CourseEndTime,
			CourseCurrentPrice = @CourseCurrentPrice
		WHERE CourseID = @CourseID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pDelCourses --
CREATE PROC pDelCourses (@CourseID int)
 -- Author: G Tedeschi
 -- Desc: Processes deletes from Courses
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		DELETE FROM Courses
		WHERE CourseID = @CourseID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create Sprocs for Students table --
-- Create pInsStudents --
CREATE PROC pInsStudents (
	@StudentFirstName nvarchar(100),
	@StudentLastName nvarchar(100),
	@StudentEmail nvarchar(100),
	@StudentPhone nvarchar(100),
	@StudentAddress nvarchar(100),
	@StudentCity nvarchar(100),
	@StudentState char(2),
	@StudentZipCode int)
 -- Author: G Tedeschi
 -- Desc: Processes inserts into Students
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		INSERT INTO Students (
			StudentFirstName,
			StudentLastName,
			StudentEmail,
			StudentPhone,
			StudentAddress,
			StudentCity,
			StudentState,
			StudentZipCode)
		Values (
			@StudentFirstName,
			@StudentLastName,
			@StudentEmail,
			@StudentPhone,
			@StudentAddress,
			@StudentCity,
			@StudentState,
			@StudentZipCode);
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pUpdStudents --
CREATE PROC pUpdStudents (
	@StudentID int,
	@StudentFirstName nvarchar(100),
	@StudentLastName nvarchar(100),
	@StudentEmail nvarchar(100),
	@StudentPhone nvarchar(100),
	@StudentAddress nvarchar(100),
	@StudentCity nvarchar(100),
	@StudentState char(2),
	@StudentZipCode int)
 -- Author: G Tedeschi
 -- Desc: Processes updates to Students
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		UPDATE Students
		SET StudentFirstName = @StudentFirstName,
			StudentLastName = @StudentLastName,
			StudentEmail = @StudentEmail,
			StudentPhone = @StudentPhone,
			StudentAddress = @StudentAddress,
			StudentCity = @StudentCity,
			StudentState = @StudentState,
			StudentZipCode = @StudentZipCode
		WHERE StudentID = @StudentID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pDelStudents --
CREATE PROC pDelStudents (@StudentID int)
 -- Author: G Tedeschi
 -- Desc: Processes deletes from Students
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		DELETE FROM Students
		WHERE StudentID = @StudentID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create Sprocs for Registration table --
-- Create pInsRegistration --
CREATE PROC pInsRegistration (
	@StudentID int,
	@CourseID int,
	@RegistrationDate date,
	@RegistrationPrice money)
 -- Author: G Tedeschi
 -- Desc: Processes inserts into Registration
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		INSERT INTO Registration (
			StudentID,
			CourseID,
			RegistrationDate,
			RegistrationPrice)
		Values (
			@StudentID,
			@CourseID,
			@RegistrationDate,
			@RegistrationPrice);
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pUpdRegistration --
CREATE PROC pUpdRegistration (
	@RegistrationID int,
	@StudentID int,
	@CourseID int,
	@RegistrationDate date,
	@RegistrationPrice money)
 -- Author: G Tedeschi
 -- Desc: Processes updates to Registration
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		UPDATE Registration
		SET StudentID = @StudentID,
			CourseID = @CourseID,
			RegistrationDate = @RegistrationDate,
			RegistrationPrice = @RegistrationPrice
		WHERE RegistrationID = @RegistrationID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Create pDelRegistration --
CREATE PROC pDelRegistration (@RegistrationID int)
 -- Author: G Tedeschi
 -- Desc: Processes deletes from Registration
 -- Change Log: When,Who,What
 -- 2021-06-11,G Tedeschi,Created Sproc.
AS
BEGIN
	DECLARE @RC int = 0
	BEGIN TRY
	BEGIN TRAN;
		DELETE FROM Registration
		WHERE RegistrationID = @RegistrationID;
	COMMIT TRAN;
		SET @RC = +1
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		PRINT Error_Message()
		SET @RC = -1
	END CATCH
	RETURN @RC;
END
GO

-- Set Permissions --
-- Deny Public access to tables --
DENY SELECT ON Courses to Public;
GO

DENY SELECT ON Students to Public;
GO

DENY SELECT ON Registration to Public;
GO

-- Grant Public access to base views and reporting views --
GRANT SELECT ON vCourses to Public;
GO

GRANT SELECT ON vStudents to Public;
GO

GRANT SELECT ON vRegistration to Public;
GO

GRANT SELECT ON vCourseEnrollment to Public;
GO

GRANT SELECT ON vStudentCourseload to Public;
GO

GRANT SELECT ON vStudentWinter2017Tuition to Public;
GO

--< Test Sprocs >-- 
-- Test Insert Sprocs --
-- Test pInsCourses --
DECLARE @Status int;
EXEC @Status = pInsCourses
				@CourseName = 'SQL3 - Winter 2017',
				@CourseStartDate = '2017-02-21',
				@CourseEndDate = '2017-03-07',
				@CourseMeetingDays = 'Tues',
				@CourseStartTime = NULL,
				@CourseEndTime = NULL,
				@CourseCurrentPrice = 399.000
SELECT Case @Status
  When +1 Then 'Courses Insert was successful!'
  When -1 Then 'Courses Insert failed! Common Issues: duplicate data, violating constraints'
  End as [Status];
GO

SELECT * FROM vCourses;
GO

-- Test pInsStudents --
DECLARE @Status int;
EXEC @Status = pInsStudents
				@StudentFirstName = 'Emma',
				@StudentLastName = 'Singh',
				@StudentEmail = 'Esingh@test.com',
				@StudentPhone = NULL,
				@StudentAddress = '444 2nd Ave.',
				@StudentCity = 'Seattle',
				@StudentState = 'WA',
				@StudentZipCode = 98001
SELECT Case @Status
	When +1 Then 'Students Insert was successful!'
	When -1 Then 'Student Insert failed! Common Issues: duplicate data, violating constraints'
	End as [Status];
GO

SELECT * FROM vStudents;
GO

-- Test pInsRegistration
DECLARE @Status int;
EXEC @Status = pInsRegistration
				@StudentID = 3,
				@CourseID = 3,
				@RegistrationDate = '2017-02-01',
				@RegistrationPrice = 399.00
SELECT Case @Status
	When +1 Then 'Registration Insert was successful!'
	When -1 Then 'Registration Insert failed! Common Issues: duplicate data, violating constraints'
	End as [Status]
GO

SELECT * FROM vRegistration;
GO

-- Test Update Sprocs --
-- Test pUpdCourses --
DECLARE @Status int;
EXEC @Status = pUpdCourses
				@CourseID = 3,
				@CourseName = 'SQL3 - Winter 2017',
				@CourseStartDate = '2017-02-21',
				@CourseEndDate = '2017-03-07',
				@CourseMeetingDays = 'Tues',
				@CourseStartTime = '18:00:00',
				@CourseEndTime = '20:50:00',
				@CourseCurrentPrice = 399.00
SELECT Case @Status
  When +1 Then 'Courses Update was successful!'
  When -1 Then 'Courses Update failed! Common Issues: duplicate data, violating constraints'
  End as [Status];
GO

SELECT * FROM vCourses;
GO

-- Test pUpdStudents --
DECLARE @Status int;
EXEC @Status = pUpdStudents
				@StudentID = 3,
				@StudentFirstName = 'Emily',
				@StudentLastName = 'Singh',
				@StudentEmail = 'Esingh@test.com',
				@StudentPhone = '(206)-555-1234',
				@StudentAddress = '444 2nd Ave.',
				@StudentCity = 'Renton',
				@StudentState = 'WA',
				@StudentZipCode = 98055
SELECT Case @Status
  When +1 Then 'Students Update was successful!'
  When -1 Then 'Students Update failed! Common Issues: duplicate data, violating constraints'
  End as [Status];
GO

SELECT * FROM vStudents;
GO

-- Test pUpdRegistration --
DECLARE @Status int;
EXEC @Status = pUpdRegistration
				@RegistrationID = 5,
				@StudentID = 3,
				@CourseID = 3,
				@RegistrationDate = '2017-01-25',
				@RegistrationPrice = 349.00
SELECT Case @Status
  When +1 Then 'Registration Update was successful!'
  When -1 Then 'Registration Update failed! Common Issues: duplicate data, violating constraints'
  End as [Status];
GO


SELECT * FROM vRegistration;
GO

-- Test Delete Sprocs --
-- Test pDelRegistration --
	-- Must delete rows from child table Registration 
	-- before deleting referenced rows in parent tables Courses and Students
DECLARE @Status int;
EXEC @Status = pDelRegistration
				@RegistrationID = 5
SELECT Case @Status
	When +1 Then 'Registration Delete was successful!'
	When -1 Then 'Registration Delete failed!'
	End as [Status];
GO

SELECT * FROM vRegistration;
GO

-- Test pDelCourses --
DECLARE @Status int;
EXEC @Status = pDelCourses
				@CourseID = 3
SELECT Case @Status
	When +1 Then 'Courses Delete was successful!'
	When -1 Then 'Courses Delete failed! Common Issues: foreign key constraint in child table'
	End as [Status];
GO

SELECT * FROM vCourses;
GO

-- Test pDelStudents --
DECLARE @Status int;
EXEC @Status = pDelStudents
				@StudentID = 3
SELECT Case @Status
	When +1 Then 'Students Delete was successful!'
	When -1 Then 'Students Delete failed! Common Issues: foreign key constraint in child table'
	End as [Status];
GO

SELECT * FROM vStudents;
GO


--{ IMPORTANT!!! }--
-- To get full credit, your script must run without having to highlight individual statements!!!  
/**************************************************************************************************/