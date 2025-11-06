import 'package:test/test.dart';
import 'package:my_app/domain/department.dart';
import 'package:my_app/domain/doctor.dart';
import 'package:my_app/domain/patient.dart';
import 'package:my_app/domain/appointment.dart';
import 'package:my_app/data/hospital_repository.dart';

void main() {
  group('Hospital domain & repository tests', () {
    late HospitalRepository repo;
    late Department dep;
    late Doctor doc;
    late Patient pat;
    late DateTime dt;

    setUp(() {
      repo = HospitalRepository();
      dep = Department(id: 1, name: 'Cardiology');
      repo.addDepartment(dep);

      doc = Doctor(
        name: 'Dr. Ronan',
        id: 101,
        gender: 'M',
        age: 45,
        specialization: 'Nose',
        department: dep,
      );
      repo.addDoctor(doc);

      pat = Patient(name: 'Alice', id: 201, gender: 'F', age: 30);
      repo.addPatient(pat);

      dt = DateTime(2025, 11, 6, 10, 0);
    });

    test('Patient can book and doctor gets appointment; conflict rejected', () {
      final ok1 = pat.bookAppointment(doc, dt);
      if (ok1) repo.addAppointment(pat.appointments.last);

      expect(ok1, isTrue, reason: 'First booking should succeed');
      expect(doc.appointments.length, 1);
      expect(pat.appointments.length, 1);

      // second booking same slot should fail
      final ok2 = pat.bookAppointment(doc, dt);
      expect(ok2, isFalse,
          reason: 'Second booking at same time should be rejected');
      expect(doc.appointments.length, 1);
    });

    test('Patient can cancel appointment (status set to canceled)', () {
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      expect(appt.status, AppointmentStatus.scheduled);
      pat.cancelAppointment(appt);
      expect(appt.status, AppointmentStatus.canceled);
    });

    test('Repository can mark appointment completed', () {
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      repo.completeAppointment(appt);
      expect(appt.status, AppointmentStatus.completed);
    });

    test('Department contains doctor after adding via repository', () {
      // repo.addDoctor was called in setUp; department should contain doc
      expect(dep.doctors.contains(doc), isTrue);
      expect(doc.department, dep);
    });

    test('Repository find methods and getAppointmentsForDoctor', () {
      expect(repo.findDoctorById(101), equals(doc));
      expect(repo.findPatientById(201), equals(pat));

      // no appointments yet for this doctor in repo appointments list
      expect(repo.getAppointmentsForDoctor(doc).length, 0);

      // after booking and adding appointment to repo
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      final list = repo.getAppointmentsForDoctor(doc);
      expect(list.length, 1);
      expect(list.first.patient, pat);
    });
  });
}
