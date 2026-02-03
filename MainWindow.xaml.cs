using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Windows;
using CollegeApp.Models;

namespace CollegeApp
{
    public partial class MainWindow : Window
    {
        private CollegeDBEntities _context = new CollegeDBEntities();

        public MainWindow()
        {
            InitializeComponent();
            LoadData();
        }

        private void LoadData()
        {
            try
            {
                _context.Specialty.Load();
                _context.Discipline.Load();
                _context.Classroom.Load();
                _context.Teacher.Load();
                _context.StudyGroup.Load();
                _context.Student.Load();
                _context.Schedule.Load();
                _context.Equipment.Load();
                _context.LibraryItem.Load();
                _context.Grade.Load();
                _context.StudentMovementHistory.Load();
                _context.LibraryLoan.Load();

                dgSpecialties.ItemsSource = _context.Specialty.Local;
                dgDisciplines.ItemsSource = _context.Discipline.Local;
                dgClassrooms.ItemsSource = _context.Classroom.Local;
                dgTeachers.ItemsSource = _context.Teacher.Local;
                dgGroups.ItemsSource = _context.StudyGroup.Local;
                dgStudents.ItemsSource = _context.Student.Local;
                dgSchedule.ItemsSource = _context.Schedule.Local;
                dgEquipment.ItemsSource = _context.Equipment.Local;
                dgLibrary.ItemsSource = _context.LibraryItem.Local;
                dgGrades.ItemsSource = _context.Grade.Local;
                dgHistory.ItemsSource = _context.StudentMovementHistory.Local;
                dgLoans.ItemsSource = _context.LibraryLoan.Local;

                cbGroup.ItemsSource = _context.StudyGroup.Local;
                cbDiscipline.ItemsSource = _context.Discipline.Local;
                cbTeacher.ItemsSource = _context.Teacher.Local;
                cbClassroom.ItemsSource = _context.Classroom.Local;
                
                colStudentGroup.ItemsSource = _context.StudyGroup.Local;
                colGroupSpecialty.ItemsSource = _context.Specialty.Local;
                colEquipmentClassroom.ItemsSource = _context.Classroom.Local;
                colGradeStudent.ItemsSource = _context.Student.Local;
                colGradeSchedule.ItemsSource = _context.Schedule.Local;

                colHistoryStudent.ItemsSource = _context.Student.Local;
                colHistoryOldGroup.ItemsSource = _context.StudyGroup.Local;
                colHistoryNewGroup.ItemsSource = _context.StudyGroup.Local;

                colLoanStudent.ItemsSource = _context.Student.Local;
                colLoanItem.ItemsSource = _context.LibraryItem.Local;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка загрузки данных: " + ex.Message);
            }
        }

        private void AddSchedule_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (dpDate.SelectedDate == null || cbGroup.SelectedItem == null || cbTeacher.SelectedItem == null ||
                    cbDiscipline.SelectedItem == null || cbClassroom.SelectedItem == null)
                {
                    MessageBox.Show("Заполните все поля!");
                    return;
                }

                DateTime date = dpDate.SelectedDate.Value;
                TimeSpan start = TimeSpan.Parse(txtStart.Text);
                TimeSpan end = TimeSpan.Parse(txtEnd.Text);
                StudyGroup group = (StudyGroup)cbGroup.SelectedItem;
                Teacher teacher = (Teacher)cbTeacher.SelectedItem;
                Classroom classroom = (Classroom)cbClassroom.SelectedItem;
                Discipline discipline = (Discipline)cbDiscipline.SelectedItem;

                var conflicts = _context.Schedule.Local.Where(s => s.LessonDate == date &&
                    ((start >= s.StartTime && start < s.EndTime) || (end > s.StartTime && end <= s.EndTime) || (start <= s.StartTime && end >= s.EndTime))).ToList();

                if (conflicts.Any(c => c.GroupID == group.GroupID))
                {
                    MessageBox.Show("Группа уже занята в это время!");
                    return;
                }
                if (conflicts.Any(c => c.TeacherID == teacher.TeacherID))
                {
                    MessageBox.Show("Преподаватель уже занят в это время!");
                    return;
                }
                if (conflicts.Any(c => c.ClassroomID == classroom.ClassroomID))
                {
                    MessageBox.Show("Аудитория уже занята в это время!");
                    return;
                }

                var newSchedule = new Schedule
                {
                    LessonDate = date,
                    StartTime = start,
                    EndTime = end,
                    GroupID = group.GroupID,
                    TeacherID = teacher.TeacherID,
                    ClassroomID = classroom.ClassroomID,
                    DisciplineID = discipline.DisciplineID,
                    LessonType = "Лекция"
                };

                _context.Schedule.Add(newSchedule);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка: " + ex.Message);
            }
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                _context.SaveChanges();
                MessageBox.Show("Данные успешно сохранены!");
            }
            catch (Exception ex)
            {
                string message = ex.Message;
                if (ex.InnerException != null) message += "\n" + ex.InnerException.Message;
                MessageBox.Show("Ошибка при сохранении: " + message);
            }
        }
    }
}
