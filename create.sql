-- =============================================
-- 1. СПРАВОЧНИКИ (Базовые сущности)
-- =============================================

-- Справочник специальностей
CREATE TABLE Specialty (
    SpecialtyID INT PRIMARY KEY IDENTITY(1,1),
    Code NVARCHAR(20) NOT NULL UNIQUE,          -- Код специальности (напр. 09.02.07)
    Name NVARCHAR(200) NOT NULL,                -- Наименование
    Qualification NVARCHAR(100) NOT NULL,       -- Квалификация (напр. Программист)
    StudyDurationYear DECIMAL(3, 1) NOT NULL    -- Срок обучения в годах (напр. 3.10)
);

-- Справочник учебных дисциплин
CREATE TABLE Discipline (
    DisciplineID INT PRIMARY KEY IDENTITY(1,1),
    Code NVARCHAR(20),                          -- Шифр дисциплины (напр. ОП.05)
    Name NVARCHAR(150) NOT NULL,                -- Название дисциплины
    StandardHours INT NOT NULL DEFAULT 0        -- Часы по ФГОС (общие)
);

-- Справочник преподавателей
CREATE TABLE Teacher (
    TeacherID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Patronymic NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    HireDate DATE DEFAULT GETDATE()
);

-- Справочник аудиторий
CREATE TABLE Classroom (
    ClassroomID INT PRIMARY KEY IDENTITY(1,1),
    Number NVARCHAR(10) NOT NULL UNIQUE,        -- Номер кабинета
    Capacity INT NOT NULL CHECK (Capacity > 0), -- Вместимость
    Type NVARCHAR(50) NOT NULL                  -- Лекционная, Лаборатория, Компьютерный класс
);

-- =============================================
-- 2. МАТЕРИАЛЬНО-ТЕХНИЧЕСКАЯ БАЗА
-- =============================================

-- Оборудование (связь с аудиторией)
CREATE TABLE Equipment (
    EquipmentID INT PRIMARY KEY IDENTITY(1,1),
    ClassroomID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,                -- Название оборудования
    InventoryNumber NVARCHAR(50) UNIQUE,        -- Инвентарный номер
    Condition NVARCHAR(50),                     -- Состояние (Новое, Требует ремонта и т.д.)
    CONSTRAINT FK_Equipment_Classroom FOREIGN KEY (ClassroomID) 
        REFERENCES Classroom(ClassroomID) ON DELETE CASCADE
);

-- Учебные материалы в библиотеке
CREATE TABLE LibraryItem (
    ItemID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100),
    PublicationYear INT,
    TotalQuantity INT NOT NULL DEFAULT 0,       -- Общее количество
    AvailableQuantity INT NOT NULL DEFAULT 0,   -- Доступно для выдачи
    Type NVARCHAR(50)                           -- Учебник, Методичка, Журнал
);

-- =============================================
-- 3. УЧЕБНЫЙ ПРОЦЕСС И КОНТИНГЕНТ
-- =============================================

-- Учебный план (Связь Специальность <-> Дисциплина)
CREATE TABLE Curriculum (
    CurriculumID INT PRIMARY KEY IDENTITY(1,1),
    SpecialtyID INT NOT NULL,
    DisciplineID INT NOT NULL,
    Semester INT NOT NULL CHECK (Semester > 0), -- Семестр изучения
    Hours INT NOT NULL CHECK (Hours > 0),       -- Часы на дисциплину в этом семестре
    CONSTRAINT FK_Curriculum_Specialty FOREIGN KEY (SpecialtyID) REFERENCES Specialty(SpecialtyID),
    CONSTRAINT FK_Curriculum_Discipline FOREIGN KEY (DisciplineID) REFERENCES Discipline(DisciplineID)
);

-- Учебные группы
CREATE TABLE StudyGroup (
    GroupID INT PRIMARY KEY IDENTITY(1,1),
    SpecialtyID INT NOT NULL,
    Name NVARCHAR(20) NOT NULL UNIQUE,          -- Название группы (напр. ИС-31)
    YearOfAdmission INT NOT NULL,               -- Год поступления
    CourseNumber INT NOT NULL DEFAULT 1,        -- Текущий курс
    CONSTRAINT FK_StudyGroup_Specialty FOREIGN KEY (SpecialtyID) REFERENCES Specialty(SpecialtyID)
);

-- Студенты
CREATE TABLE Student (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    GroupID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Patronymic NVARCHAR(50),
    BirthDate DATE NOT NULL,
    StudyForm NVARCHAR(20) NOT NULL,            -- Очная, Заочная
    Status NVARCHAR(20) DEFAULT 'Active',       -- Active, Expelled, Graduated, AcademicLeave
    CONSTRAINT FK_Student_StudyGroup FOREIGN KEY (GroupID) REFERENCES StudyGroup(GroupID)
);

-- История движения студентов (Переводы, отчисления)
CREATE TABLE StudentMovementHistory (
    HistoryID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    OldGroupID INT NULL,                        -- Из какой группы (может быть NULL при приеме)
    NewGroupID INT NULL,                        -- В какую группу (может быть NULL при отчислении)
    OrderNumber NVARCHAR(50),                   -- Номер приказа
    OrderDate DATE NOT NULL DEFAULT GETDATE(),  -- Дата приказа
    Reason NVARCHAR(200),                       -- Причина
    Type NVARCHAR(50) NOT NULL,                 -- Enrollment, Transfer, Expulsion
    CONSTRAINT FK_History_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID)
);

-- Выдача книг студентам
CREATE TABLE LibraryLoan (
    LoanID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    ItemID INT NOT NULL,
    IssueDate DATE NOT NULL DEFAULT GETDATE(),
    ReturnDate DATE,                            -- Дата фактического возврата (NULL если на руках)
    DeadlineDate DATE NOT NULL,                 -- Срок сдачи
    CONSTRAINT FK_Loan_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Loan_LibraryItem FOREIGN KEY (ItemID) REFERENCES LibraryItem(ItemID)
);

-- =============================================
-- 4. РАСПИСАНИЕ И УСПЕВАЕМОСТЬ
-- =============================================

-- Расписание занятий
-- Примечание: Это таблица конкретных занятий. 
-- Для шаблона расписания (по дням недели) структура была бы немного другой.
CREATE TABLE Schedule (
    ScheduleID INT PRIMARY KEY IDENTITY(1,1),
    GroupID INT NOT NULL,
    TeacherID INT NOT NULL,
    DisciplineID INT NOT NULL,
    ClassroomID INT NOT NULL,
    LessonDate DATE NOT NULL,                   -- Дата занятия
    StartTime TIME NOT NULL,                    -- Время начала
    EndTime TIME NOT NULL,                      -- Время конца
    LessonType NVARCHAR(20),                    -- Лекция, Практика
    
    CONSTRAINT FK_Schedule_Group FOREIGN KEY (GroupID) REFERENCES StudyGroup(GroupID),
    CONSTRAINT FK_Schedule_Teacher FOREIGN KEY (TeacherID) REFERENCES Teacher(TeacherID),
    CONSTRAINT FK_Schedule_Discipline FOREIGN KEY (DisciplineID) REFERENCES Discipline(DisciplineID),
    CONSTRAINT FK_Schedule_Classroom FOREIGN KEY (ClassroomID) REFERENCES Classroom(ClassroomID)
);

-- Успеваемость (Журнал оценок)
CREATE TABLE Grade (
    GradeID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    ScheduleID INT NOT NULL,                    -- Ссылка на конкретное занятие в расписании
    GradeValue INT CHECK (GradeValue BETWEEN 2 AND 5), -- Оценка (2,3,4,5). NULL для "Н" (отсутствие)
    IsPresent BIT DEFAULT 1,                    -- Присутствие (1 - был, 0 - не был)
    Comment NVARCHAR(100),                      -- Комментарий преподавателя
    
    CONSTRAINT FK_Grade_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Grade_Schedule FOREIGN KEY (ScheduleID) REFERENCES Schedule(ScheduleID)
);

GO
