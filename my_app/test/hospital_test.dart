import 'package:test/test.dart';
import 'package:my_app/data/hospital_repository.dart';
import 'package:my_app/domain/department.dart';
import 'package:my_app/domain/doctor.dart';
import 'package:my_app/domain/patient.dart';
import 'package:my_app/domain/appointment.dart';

void main() {
  group('Simple Hospital tests', () {
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
        name: 'Dr. Heng',
        id: 101,
        gender: 'M',
        age: 15,
        specialization: 'Cardiologist',
        department: dep,
      );
      repo.addDoctor(doc);

      pat = Patient(name: 'Nak', id: 201, gender: 'F', age: 21);
      // tests will register patient into repo where needed
      dt = DateTime(2025, 11, 6, 10, 0);
    });

    test('View doctors shows added doctor', () {
      final doctors = repo.getAllDoctors();
      expect(doctors, isNotEmpty);
      expect(doctors.first.name, equals('Dr. Smith'));
      expect(doctors.first.specialization, contains('Cardio'));
    });

    test('Patient can book appointment and it appears in repo', () {
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue,
          reason: 'Booking should succeed when doctor available');

      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      // repo should contain the appointment and doctor/patient lists updated
      expect(repo.appointments, contains(appt));
      expect(doc.appointments, contains(appt));
      expect(pat.appointments, contains(appt));
      expect(appt.status, AppointmentStatus.scheduled);
    });

    test('Conflicting booking is rejected', () {
      repo.addPatient(pat);
      final first = pat.bookAppointment(doc, dt);
      expect(first, isTrue);
      repo.addAppointment(pat.appointments.last);

      // second attempt same date/time must fail
      final second = pat.bookAppointment(doc, dt);
      expect(second, isFalse, reason: 'Doctor already booked at same time');
    });

    test('Patient can cancel appointment', () {
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      // cancel and check status
      pat.cancelAppointment(appt);
      expect(appt.status, AppointmentStatus.canceled);
    });

    test('Doctor schedule returns the doctor appointments', () {
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      final list = repo.getAppointmentsForDoctor(doc);
      expect(list.length, greaterThanOrEqualTo(1));
      expect(list.first.doctor, equals(doc));
      expect(list.first.patient, equals(pat));
    });
  });
}
