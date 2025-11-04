import 'dart:io';
import '../domain/hospital.dart';
import '../data/hospital_repository.dart';

void runConsoleUI() {
  final repo = HospitalRepository();

  repo.addDepartment(Department(id: 1, name: 'Pediatrics'));
  repo.addDepartment(Department(id: 2, name: 'Cardiology'));
  repo.addDepartment(Department(id: 3, name: 'Neurology'));

  repo.addDoctor(
    Doctor(
      name: 'Dr. Heng',
      id: 1,
      gender: 'M',
      age: 40,
      specialization: 'Cardiology',
      department: repo.departments[1],
    ),
  );
  repo.addDoctor(
    Doctor(
      name: 'Dr. Chan',
      id: 2,
      gender: 'M',
      age: 38,
      specialization: 'Neurology',
      department: repo.departments[2],
    ),
  );

  while (true) {
    stdout.write('\x1B[2J\x1B[0;0H');
    print('\n==========================================');
    print('     PATIENT MANAGEMENT SYSTEM (TERMINAL)');
    print('==========================================');
    print('\nMAIN MENU');
    print('------------------------------------------');
    print('1. Admin Login');
    print('2. Doctor Login');
    print('3. Patient Login');
    print('4. Exit');
    print('------------------------------------------');
    stdout.write('Enter your choice: ');
    final input = stdin.readLineSync();

    if (input == '1') {
      adminMenu(repo);
    } else if (input == '2') {
      doctorMenu(repo);
    } else if (input == '3') {
      patientMenu(repo);
    } else if (input == '4') {
      break;
    }
  }
}

void adminMenu(HospitalRepository repo) {
  while (true) {
    stdout.write('\x1B[2J\x1B[0;0H');
    print('\n==========================================');
    print('ADMIN MENU');
    print('==========================================');
    print('1. View Departments');
    print('2. Add Department');
    print('3. Add Doctor to Department');
    print('4. View All Doctors');
    print('5. View System Summary');
    print('6. Back to Main Menu');
    print('------------------------------------------');
    stdout.write('Enter your choice: ');
    final input = stdin.readLineSync();

    if (input == '1') {
      print('\nDepartments:');
      for (var i = 0; i < repo.departments.length; i++) {
        print('${i + 1}. ${repo.departments[i].name}');
      }
    } else if (input == '2') {
      stdout.write('Enter Department Name: ');
      final name = stdin.readLineSync() ?? '';
      final dep = Department(id: repo.departments.length + 1, name: name);
      repo.addDepartment(dep);
      print('Department added!');
    } else if (input == '3') {
      stdout.write('Enter Doctor Name: ');
      final name = stdin.readLineSync() ?? '';
      stdout.write('Enter Specialization: ');
      final spec = stdin.readLineSync() ?? '';
      print('Select Department:');
      for (var i = 0; i < repo.departments.length; i++) {
        print('${i + 1}. ${repo.departments[i].name}');
      }
      final depIdx = int.tryParse(stdin.readLineSync() ?? '') ?? 1;
      final dep = repo.getDepartmentByIndex(depIdx - 1);
      if (dep == null) {
        print('Invalid department.');
        continue;
      }
      final doc = Doctor(
        name: name,
        id: repo.doctors.length + 1,
        gender: 'N/A',
        age: 0,
        specialization: spec,
        department: dep,
      );
      repo.addDoctor(doc);
      print('Doctor added successfully to ${dep.name} Department!');
    } else if (input == '4') {
      print('\nAll Doctors:');
      for (var d in repo.doctors) {
        print('${d.name} (${d.specialization}) - Dept: ${d.department.name}');
      }
    } else if (input == '5') {
      print('\n------------------------------------------');
      print('Departments: ${repo.departmentCount}');
      print('Doctors: ${repo.doctorCount}');
      print('Patients: ${repo.patientCount}');
      print('Appointments: ${repo.appointmentCount}');
      print('------------------------------------------');
      print('[Upcoming Appointments]');
      for (var a in repo.appointments.where(
        (a) => a.status == AppointmentStatus.scheduled,
      )) {
        print(
          '- ${a.date.toLocal()} | ${a.doctor.name} → ${a.patient.name} (${a.status.name})',
        );
      }
      print('------------------------------------------');
      stdout.write('Press Enter to return...');
      stdin.readLineSync();
    } else if (input == '6') {
      break;
    }
  }
}

void doctorMenu(HospitalRepository repo) {
  stdout.write('\x1B[2J\x1B[0;0H');
  print('\nEnter Doctor ID: ');
  final did = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
  final doctor = repo.findDoctorById(did);
  if (doctor == null) {
    print('Doctor not found.');
    return;
  }
  while (true) {
    stdout.write('\x1B[2J\x1B[0;0H');
    print('\n==========================================');
    print('DOCTOR MENU');
    print('==========================================');
    print('1. View My Appointments');
    print('2. Complete Appointment');
    print('3. Check My Availability');
    print('4. Update Appointment Status');
    print('5. Back to Main Menu');
    print('------------------------------------------');
    stdout.write('Enter your choice: ');
    final input = stdin.readLineSync();

    if (input == '1') {
      print('Your Appointments:');
      for (var i = 0; i < doctor.appointments.length; i++) {
        final a = doctor.appointments[i];
        print(
          '${i + 1}. Patient: ${a.patient.name} | Date: ${a.date} | Status: ${a.status.name}',
        );
      }
    } else if (input == '2') {
      print('Select appointment index to complete: ');
      for (var i = 0; i < doctor.appointments.length; i++) {
        final a = doctor.appointments[i];
        print(
          '${i + 1}. Patient: ${a.patient.name} | Date: ${a.date} | Status: ${a.status.name}',
        );
      }
      final idx = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      if (idx < 1 || idx > doctor.appointments.length) {
        print('Invalid index.');
        continue;
      }
      doctor.appointments[idx - 1].complete();
      print(' Appointment marked as COMPLETED.');
    } else if (input == '3') {
      stdout.write('Enter date (YYYY-MM-DD HH:MM): ');
      final dateStr = stdin.readLineSync() ?? '';
      DateTime? date;
      try {
        date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      } catch (_) {
        print('Invalid date format.');
        continue;
      }
      if (doctor.isAvailable(date)) {
        print(' Available.');
      } else {
        print(' Not available — Appointment already scheduled.');
      }
    } else if (input == '4') {
      print('Select appointment index to update: ');
      for (var i = 0; i < doctor.appointments.length; i++) {
        final a = doctor.appointments[i];
        print(
          '${i + 1}. Patient: ${a.patient.name} | Date: ${a.date} | Status: ${a.status.name}',
        );
      }
      final idx = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      if (idx < 1 || idx > doctor.appointments.length) {
        print('Invalid index.');
        continue;
      }
      print('Select new status:\n1. Scheduled\n2. Completed\n3. Canceled');
      final statusIdx = int.tryParse(stdin.readLineSync() ?? '') ?? 1;
      final appointment = doctor.appointments[idx - 1];
      if (statusIdx == 1) {
        appointment.schedule();
      } else if (statusIdx == 2) {
        appointment.complete();
      } else if (statusIdx == 3) {
        appointment.cancel();
      }
      print('Appointment status updated successfully!');
    } else if (input == '5') {
      break;
    }
  }
}

void patientMenu(HospitalRepository repo) {
  stdout.write('\x1B[2J\x1B[0;0H');
  print('\nEnter Patient ID: ');
  final pid = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
  var patient = repo.findPatientById(pid);
  if (patient == null) {
    print('Patient not found. Registering new patient...');
    stdout.write('Enter patient name: ');
    final name = stdin.readLineSync() ?? '';
    stdout.write('Enter gender: ');
    final gender = stdin.readLineSync() ?? '';
    stdout.write('Enter age: ');
    final age = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
    patient = Patient(name: name, id: pid, gender: gender, age: age);
    repo.addPatient(patient);
    print('Patient registered.');
  }
  while (true) {
    stdout.write('\x1B[2J\x1B[0;0H'); // ai generate on clear screen finction
    print('\n==========================================');
    print('PATIENT MENU');
    print('==========================================');
    print('1. View Available Doctors');
    print('2. Book Appointment');
    print('3. Cancel Appointment');
    print('4. View My Appointments');
    print('5. Back to Main Menu');
    print('------------------------------------------');
    stdout.write('Enter your choice: ');
    final input = stdin.readLineSync();

    if (input == '1') {
      print('Available Doctors:');
      for (var i = 0; i < repo.doctors.length; i++) {
        print(
          '${i + 1}. ${repo.doctors[i].name} (${repo.doctors[i].specialization})',
        );
      }
    } else if (input == '2') {
      print('Select Doctor Index:');
      for (var i = 0; i < repo.doctors.length; i++) {
        print(
          '${i + 1}. ${repo.doctors[i].name} (${repo.doctors[i].specialization})',
        );
      }
      final didx = int.tryParse(stdin.readLineSync() ?? '') ?? 1;
      final doctor = repo.getDoctorByIndex(didx - 1);
      if (doctor == null) {
        print('Invalid doctor index.');
        continue;
      }
      stdout.write('Enter Date (YYYY-MM-DD HH:MM): ');
      final dateStr = stdin.readLineSync() ?? '';
      DateTime? date;
      try {
        date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      } catch (_) {
        print('Invalid date format.');
        continue;
      }
      if (!doctor.isAvailable(date)) {
        print(' Not available — Appointment already scheduled.');
        continue;
      }
      patient.bookAppointment(doctor, date);
      repo.addAppointment(patient.appointments.last);
      print(' Appointment booked successfully! (Status: Scheduled)');
    } else if (input == '3') {
      print('My Appointments:');
      for (var i = 0; i < patient.appointments.length; i++) {
        final a = patient.appointments[i];
        print(
          '${i + 1}. Dr. ${a.doctor.name} | ${a.date} | Status: ${a.status.name}',
        );
      }
      stdout.write('Select Appointment to Cancel: ');
      final idx = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      if (idx < 1 || idx > patient.appointments.length) {
        print('Invalid index.');
        continue;
      }
      patient.cancelAppointment(patient.appointments[idx - 1]);
      print(' Appointment canceled successfully!');
    } else if (input == '4') {
      print('My Appointments:');
      for (var i = 0; i < patient.appointments.length; i++) {
        final a = patient.appointments[i];
        print(
          '${i + 1}. Dr. ${a.doctor.name} | ${a.date} | Status: ${a.status.name}',
        );
      }
    } else if (input == '5') {
      break;
    }
  }
}
