import 'dart:io';
import 'package:test/test.dart';
import 'package:my_app/data/hospital_repository.dart';
import 'package:my_app/domain/department.dart';
import 'package:my_app/domain/doctor.dart';
import 'package:my_app/domain/patient.dart';
import 'package:my_app/domain/appointment.dart';

void main() {
  group('Hospital unit tests', () {
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
        age: 40,
        specialization: 'Cardiologist',
        department: dep,
      );
      repo.addDoctor(doc);

      pat = Patient(name: 'Nak', id: 201, gender: 'F', age: 21);
      dt = DateTime(2025, 11, 6, 10, 0);
    });

    test('Department contains doctor after addDoctor', () {
      expect(repo.departmentCount, greaterThanOrEqualTo(1));
      expect(dep.doctors.contains(doc), isTrue);
      expect(doc.department, equals(dep));
    });

    test('Register patient and find by phone and id', () {
      // register patient with phone
      pat.phoneNumber = '012345678';
      repo.addPatient(pat);

      final byPhone = repo.findPatientByPhone('012345678');
      expect(byPhone, isNotNull);
      expect(byPhone!.name, equals(pat.name));

      final byId = repo.findPatientById(pat.id);
      expect(byId, isNotNull);
      expect(byId!.id, equals(pat.id));
    });

    test('Patient can book appointment and repository records it', () {
      repo.addPatient(pat);

      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);

      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      expect(repo.appointments, contains(appt));
      expect(doc.appointments, contains(appt));
      expect(pat.appointments, contains(appt));
      expect(appt.status, AppointmentStatus.scheduled);
    });

    test('Doctor rejects conflicting bookings at same datetime', () {
      repo.addPatient(pat);

      final ok1 = pat.bookAppointment(doc, dt);
      expect(ok1, isTrue);
      repo.addAppointment(pat.appointments.last);

      final ok2 = pat.bookAppointment(doc, dt);
      expect(ok2, isFalse,
          reason: 'Second booking at same datetime should be rejected');
    });

    test('Patient can book multiple different appointments', () {
      repo.addPatient(pat);

      final dt2 = dt.add(const Duration(hours: 1));
      final ok1 = pat.bookAppointment(doc, dt);
      final ok2 = pat.bookAppointment(doc, dt2);

      expect(ok1, isTrue);
      expect(ok2, isTrue);

      // add to repo
      repo.addAppointment(pat.appointments[0]);
      repo.addAppointment(pat.appointments[1]);

      expect(doc.appointments.length, greaterThanOrEqualTo(2));
    });

    test('Patient can cancel appointment (status changes)', () {
      repo.addPatient(pat);

      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      // cancel via patient
      pat.cancelAppointment(appt);
      expect(appt.status, AppointmentStatus.canceled);
    });

    test('Repository confirm and complete appointment', () {
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      // confirm -> pending
      repo.confirmAppointment(appt);
      expect(appt.status, AppointmentStatus.pending);

      // complete -> completed
      repo.completeAppointment(appt);
      expect(appt.status, AppointmentStatus.completed);
    });

    test('Get appointments for doctor returns expected items', () {
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      final list = repo.getAppointmentsForDoctor(doc);
      expect(list, isNotEmpty);
      expect(list.first.doctor, equals(doc));
      expect(list.first.patient, equals(pat));
    });

    test('Repository JSON serialization and file persistence', () async {
      // prepare repo with data
      pat.phoneNumber = '099999999';
      repo.addPatient(pat);
      final ok = pat.bookAppointment(doc, dt);
      expect(ok, isTrue);
      final appt = pat.appointments.last;
      repo.addAppointment(appt);

      // save to a temp file and load back
      final tmpDir = Directory.systemTemp.createTempSync('hospital_test_');
      final filePath = '${tmpDir.path}/snapshot.json';

      await repo.saveToFile(filePath);
      final loaded = await HospitalRepository.loadFromFile(filePath);

      // basic assertions on loaded data
      expect(loaded.departmentCount, equals(repo.departmentCount));
      expect(loaded.doctorCount, equals(repo.doctorCount));
      expect(loaded.patientCount, equals(repo.patientCount));
      expect(loaded.appointmentCount, equals(repo.appointmentCount));

      // cleanup
      tmpDir.deleteSync(recursive: true);
    });
  });
}
