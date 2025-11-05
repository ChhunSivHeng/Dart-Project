import 'dart:io';
import '../domain/hospital.dart';
import '../data/hospital_repository.dart';

DateTime? _parseFlexibleDate(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;

  // Try common ISO-like "YYYY-MM-DD[ HH:MM]" allowing single-digit month/day
  final isoReg = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2}))?$');
  final mIso = isoReg.firstMatch(s);
  if (mIso != null) {
    final y = int.parse(mIso.group(1)!);
    final mo = int.parse(mIso.group(2)!);
    final d = int.parse(mIso.group(3)!);
    final hh = mIso.group(4) != null ? int.parse(mIso.group(4)!) : 0;
    final mm = mIso.group(5) != null ? int.parse(mIso.group(5)!) : 0;
    try {
      return DateTime(y, mo, d, hh, mm);
    } catch (_) {
      return null;
    }
  }

  // Try US format "MM/DD/YY" or "MM/DD/YYYY" with optional time " HH:MM"
  final usReg = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})(?:[ T](\d{1,2}):(\d{2}))?$');
  final mUs = usReg.firstMatch(s);
  if (mUs != null) {
    var mo = int.parse(mUs.group(1)!);
    var d = int.parse(mUs.group(2)!);
    var y = int.parse(mUs.group(3)!);
    if (y < 100) y += 2000; // '25' -> 2025
    final hh = mUs.group(4) != null ? int.parse(mUs.group(4)!) : 0;
    final mm = mUs.group(5) != null ? int.parse(mUs.group(5)!) : 0;
    try {
      return DateTime(y, mo, d, hh, mm);
    } catch (_) {
      return null;
    }
  }

  // Last attempt: try DateTime.parse with 'T' replacement (strict)
  try {
    return DateTime.parse(s.replaceFirst(' ', 'T'));
  } catch (_) {
    return null;
  }
}

DateTime _readDatePrompt(String prompt) {
  while (true) {
    stdout.write(prompt);
    final input = stdin.readLineSync() ?? '';
    final parsed = _parseFlexibleDate(input);
    if (parsed != null) return parsed;
    print('Invalid date format.');
    print('Accepted formats: "YYYY-MM-DD HH:MM" (e.g. 2025-11-05 12:34) or "MM/DD/YY" (e.g. 11/05/25). Please re-enter.');
  }
}

void runConsoleUI() {
  final repo = HospitalRepository();

  // minimal bootstrap so user can test quickly
  final defaultDept = Department(id: 1, name: 'General');
  repo.addDepartment(defaultDept);

  while (true) {
    print('\n====== HOSPITAL APPOINTMENT SYSTEM ======');
    print('\n1. Add Doctor to Department');
    print('2. Patient Book Appointment');
    print('3. Doctor View / Confirm Appointment');
    print('4. Complete or Update Appointment Status');
    print('5. Exit');
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
      print('\n=== BOOK APPOINTMENT ===');
      stdout.write('Enter Patient Name: ');
      final pName = stdin.readLineSync() ?? '';
      stdout.write('Enter Patient ID: ');
      final pId = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      stdout.write('Enter Gender: ');
      final gender = stdin.readLineSync() ?? '';
      stdout.write('Enter Age: ');
      final age = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

      final patient = Patient(name: pName, id: pId, gender: gender, age: age);
      repo.addPatient(patient);

      stdout.write('\nEnter Doctor ID to book: ');
      final did = int.tryParse(stdin.readLineSync() ?? '') ?? 0;
      final doctor = repo.findDoctorById(did);
      if (doctor == null) {
        print('Doctor not found.');
        continue;
      }

      final date = _readDatePrompt('Enter Appointment Date (YYYY-MM-DD HH:MM or MM/DD/YY): ');

      print('\nChecking ${doctor.name} availability...');
      if (!doctor.isAvailable(date)) {
        print('❌ Doctor ${doctor.name} already has an appointment at that time.');
        continue;
      }
      print('✅ Doctor is available.\n\nBooking appointment...');
      final appt = Appointment(
        date: date,
        status: AppointmentStatus.scheduled,
        doctor: doctor,
        patient: patient,
      );
      doctor.appointments.add(appt);
      patient.appointments.add(appt);
      repo.addAppointment(appt);

      print('Appointment created successfully!\n');
      print('Appointment ID: ${appt.id}');
      print('Doctor: ${doctor.name}');
      print('Patient: ${patient.name}');
      print('Date: ${date.toString().split('.').first}');
      print('Status: ${appt.status.name.toUpperCase()}');
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
      stdout.write('Do you want to confirm any appointment? (Enter index or 0 to skip): ');
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
        print('✅ Appointment marked as COMPLETED!');
      } else {
        stdout.write('Enter new status (S = SCHEDULED, P = PENDING, C = CANCELED): ');
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
      print('Exiting system...\nThank you for using the Hospital Appointment System!');
      break;
    } else {
      print('Invalid option.');
    }
    print('----------------------------------------\n');
  }
}
