import 'dart:io';
import '../data/hospital_repository.dart';
import '../domain/department.dart';
import '../domain/doctor.dart';
import '../domain/patient.dart';
import '../domain/appointment.dart';

DateTime? _parseFlexibleDate(String input) {
  // Try "YYYY-MM-DD HH:MM"
  try {
    return DateTime.parse(input);
  } catch (_) {}

  // Try "MM/DD/YY"
  final parts = input.split('/');
  if (parts.length == 3) {
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month != null && day != null && year != null) {
      final fullYear = year < 100 ? 2000 + year : year;
      return DateTime(fullYear, month, day);
    }
  }
  return null;
}

DateTime _readDatePrompt(String prompt) {
  while (true) {
    stdout.write(prompt);
    final input = stdin.readLineSync() ?? '';
    final parsed = _parseFlexibleDate(input);
    if (parsed != null) return parsed;
    print('Invalid date format.');
    print(
      'Accepted formats: "YYYY-MM-DD HH:MM" (e.g. 2025-11-05 12:34) or "MM/DD/YY" (e.g. 11/05/25). Please re-enter.',
    );
  }
}

void _registerPatientUI(HospitalRepository repo) {
  print('\n--- Register New Patient ---');
  stdout.write('Name: ');
  final name = stdin.readLineSync() ?? '';
  stdout.write('Gender: ');
  final gender = stdin.readLineSync() ?? '';
  stdout.write('Age: ');
  final age = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
  stdout.write('Phone number: ');
  final phone = (stdin.readLineSync() ?? '').trim();

  // generate an internal numeric id if needed
  final id = repo.patients.length + 1;

  final patient = Patient(
    name: name,
    id: id,
    gender: gender,
    age: age,
    phoneNumber: phone,
  );
  repo.addPatient(patient);
  print(' Patient registered: ${patient.name} (Phone: ${patient.phoneNumber})');
}

void _findPatientByPhoneUI(HospitalRepository repo) {
  stdout.write('Enter patient phone number: ');
  final phone = (stdin.readLineSync() ?? '').trim();
  if (phone.isEmpty) return;
  final p = repo.findPatientByPhone(phone);
  if (p == null) {
    print('Patient not found.');
    return;
  }
  print(
    'Found: ${p.name}, Age: ${p.age}, Gender: ${p.gender}, Phone: ${p.phoneNumber}',
  );
}

void runHospitalConsole(HospitalRepository repo) async {
  const filePath = 'hospital_snapshot.json';

  // Ensure at least one department exists
  if (repo.departments.isEmpty) {
    final defaultDept = Department(id: 1, name: 'General');
    repo.addDepartment(defaultDept);
  }

  while (true) {
    print('\n====== HOSPITAL APPOINTMENT SYSTEM ======');
    print('\n1. Add Doctor to Department');
    print('2. Patient Book Appointment');
    print('3. Doctor View / Confirm Appointment');
    print('4. Complete or Update Appointment Status');
    print('5. Find Patient by Phone');
    print('6. View All Doctors');
    print('7. Exit');
    stdout.write('----------------------------------------\nSelect option: ');
    final option = (stdin.readLineSync() ?? '').trim();

    if (option == '1') {
      print('\n=== ADD DOCTOR TO DEPARTMENT ===');
      stdout.write('Enter Department ID: ');
      final depId = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      stdout.write('Enter Department Name: ');
      final depName = stdin.readLineSync() ?? '';

      var dept = repo.findDepartmentById(depId);
      if (dept == null) {
        dept = Department(id: depId, name: depName);
        repo.addDepartment(dept);
      } else {
        dept.name = depName.isNotEmpty ? depName : dept.name;
      }

      stdout.write('Enter Doctor Name: ');
      final docName = stdin.readLineSync() ?? '';
      stdout.write('Enter Doctor ID: ');
      final docId = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      stdout.write('Enter Specialization: ');
      final spec = stdin.readLineSync() ?? '';

      final doc = Doctor(
        name: docName,
        id: docId,
        gender: 'N/A',
        age: 0,
        specialization: spec,
        department: dept,
      );
      repo.addDoctor(doc);
      print('\nDoctor added successfully to department "${dept.name}"!');
    } else if (option == '2') {
      _patientBookingFlow(repo);
    } else if (option == '3') {
      print('\n=== DOCTOR VIEW APPOINTMENTS ===');
      stdout.write('Enter Doctor ID: ');
      final did = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      final doctor = repo.findDoctorById(did);
      if (doctor == null) {
        print('Doctor not found.');
        continue;
      }
      print('Doctor: ${doctor.name} (ID: ${doctor.id})');
      print('----------------------------------------');
      final list = repo.getAppointmentsForDoctor(doctor);
      if (list.isEmpty) {
        print('No appointments.');
        continue;
      }
      for (var i = 0; i < list.length; i++) {
        final a = list[i];
        print('[${i + 1}] Appointment ID: ${a.id}');
        print('    Patient: ${a.patient.name}');
        print('    Date: ${a.date.toString().split('.').first}');
        print('    Status: ${a.status.name.toUpperCase()}\n');
      }
      stdout.write(
        'Do you want to confirm any appointment? (Enter index or 0 to skip): ',
      );
      final idx = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      if (idx > 0 && idx <= list.length) {
        final sel = list[idx - 1];
        repo.confirmAppointment(sel);
        print('Appointment confirmed.');
        print('Status updated to: ${sel.status.name.toUpperCase()}');
      }
    } else if (option == '4') {
      print('\n=== UPDATE / COMPLETE APPOINTMENT ===');
      stdout.write('Doctor ID: ');
      final did = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      final doctor = repo.findDoctorById(did);
      if (doctor == null) {
        print('Doctor not found.');
        continue;
      }
      final list = repo.getAppointmentsForDoctor(doctor);
      if (list.isEmpty) {
        print('No appointments.');
        continue;
      }
      print('Doctor: ${doctor.name}');
      print('----------------------------------------');
      for (var i = 0; i < list.length; i++) {
        final a = list[i];
        print('[${i + 1}] Appointment ID: ${a.id}');
        print('    Patient: ${a.patient.name}');
        print('    Date: ${a.date.toString().split('.').first}');
        print('    Status: ${a.status.name.toUpperCase()}\n');
      }
      stdout.write('Select appointment index to update: ');
      final selIdx = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      if (selIdx < 1 || selIdx > list.length) {
        print('Invalid selection.');
        continue;
      }
      final ap = list[selIdx - 1];
      stdout.write('Has the appointment ended? (Y/N): ');
      final ended = (stdin.readLineSync() ?? '').trim().toUpperCase();
      if (ended == 'Y') {
        repo.completeAppointment(ap);
        print('Appointment marked as COMPLETED!');
      } else {
        stdout.write(
          'Enter new status (S = SCHEDULED, P = PENDING, C = CANCELED): ',
        );
        final st = (stdin.readLineSync() ?? '').trim().toUpperCase();
        if (st == 'S') {
          ap.status = AppointmentStatus.scheduled;
        } else if (st == 'P') {
          ap.status = AppointmentStatus.pending;
        } else if (st == 'C') {
          repo.cancelAppointment(ap);
        }
        print('Status updated to: ${ap.status.name.toUpperCase()}');
      }

      print('\nCurrent Appointment Summary:');
      print('Appointment ID: ${ap.id}');
      print('Doctor: ${ap.doctor.name}');
      print('Patient: ${ap.patient.name}');
      print('Date: ${ap.date.toString().split('.').first}');
      print('Status: ${ap.status.name.toUpperCase()}');
    } else if (option == '5') {
      _findPatientByPhoneUI(repo);
    } else if (option == '6') {
      _viewAllDoctors(repo);
    } else if (option == '7') {
      print(
        'Exiting system...\nThank you for using the Hospital Appointment System!',
      );
      await repo.saveToFile(filePath);
      break;
    } else {
      print('Invalid option.');
    }
    print('----------------------------------------\n');
  }
}

// New: patient booking & status flow
void _patientBookingFlow(HospitalRepository repo) {
  // identify patient by phone
  stdout.write('Enter patient phone number: ');
  var phone = (stdin.readLineSync() ?? '').trim();
  Patient? patient = repo.findPatientByPhone(phone);

  if (patient == null) {
    stdout.write('Patient not found. Register new? (Y/N): ');
    final create = (stdin.readLineSync() ?? '').trim().toUpperCase();
    if (create == 'Y') {
      _registerPatientUI(repo);
      // ask phone again to locate the created patient
      stdout.write('Enter patient phone number you just registered: ');
      phone = (stdin.readLineSync() ?? '').trim();
      patient = repo.findPatientByPhone(phone);
      if (patient == null) {
        print('Registration lookup failed. Returning to main menu.');
        return;
      }
    } else {
      print('Returning to main menu.');
      return;
    }
  }

  while (true) {
    print(
      '\n--- Patient Menu for ${patient.name} (Phone: ${patient.phoneNumber}) ---',
    );
    print('1. Book new appointment');
    print('2. View my bookings (and cancel)');
    print('3. Back');
    stdout.write('Choice: ');
    final choice = (stdin.readLineSync() ?? '').trim();

    switch (choice) {
      case '1':
        if (repo.doctors.isEmpty) {
          print('No doctors available to book.');
          continue;
        }
        print('\nAvailable Doctors:');
        for (var i = 0; i < repo.doctors.length; i++) {
          final d = repo.doctors[i];
          print('${i + 1}. ${d.name} (ID: ${d.id}) — ${d.specialization}');
        }
        stdout.write('Choose doctor index: ');
        final didx = int.tryParse(stdin.readLineSync() ?? '') ?? -1;
        if (didx < 1 || didx > repo.doctors.length) {
          print('Invalid doctor selection.');
          continue;
        }
        final doctor = repo.doctors[didx - 1];
        final date = _readDatePrompt(
          'Enter appointment date (YYYY-MM-DD HH:MM or MM/DD/YY): ',
        );
        if (!doctor.isAvailable(date)) {
          print('Doctor ${doctor.name} is not available at that time.');
          continue;
        }
        final ok = patient.bookAppointment(doctor, date);
        if (ok) {
          final appt = patient.appointments.last;
          repo.addAppointment(appt);
          print(
            'Appointment booked: [${appt.id}] ${appt.date.toLocal()} with Dr ${doctor.name}',
          );
        } else {
          print('Failed to book appointment.');
        }
        break;
      case '2':
        if (patient.appointments.isEmpty) {
          print('No appointments.');
          continue;
        }
        print('\nMy Appointments:');
        for (var i = 0; i < patient.appointments.length; i++) {
          final a = patient.appointments[i];
          print(
            '${i + 1}. [${a.id}] ${a.date.toLocal()} — Dr: ${a.doctor.name} | ${a.status.name.toUpperCase()}',
          );
        }
        stdout.write('Enter appointment index to cancel or 0 to go back: ');
        final idx = int.tryParse(stdin.readLineSync() ?? '') ?? -1;
        if (idx == 0) continue;
        if (idx < 1 || idx > patient.appointments.length) {
          print('Invalid selection.');
          continue;
        }
        final appt = patient.appointments[idx - 1];
        repo.cancelAppointment(appt);
        print('Appointment [${appt.id}] canceled.');
        break;
      case '3':
        return;
      default:
        print('Invalid choice.');
    }
  }
}

// New: list all doctors
void _viewAllDoctors(HospitalRepository repo) {
  print('\n--- All Doctors ---');
  if (repo.doctors.isEmpty) {
    print('No doctors registered.');
    return;
  }
  for (var d in repo.doctors) {
    final deptName = d.department.name;
    print(
        'ID: ${d.id} | Name: ${d.name} | Specialization: ${d.specialization} | Department: $deptName');
  }
}

// Patient registration: _registerPatientUI(repo)
// Patient booking / view / cancel: _patientBookingFlow(repo)
// Find patient by phone: _findPatientByPhoneUI(repo)
// View all doctors: _viewAllDoctors(repo)
// Doctor change/confirm/complete/update status: handled in option '3' and option '4'
// No code changes required here.
