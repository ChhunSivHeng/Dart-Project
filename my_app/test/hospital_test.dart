import 'package:test/test.dart';
import 'package:my_app/domain/department.dart';
import 'package:my_app/domain/doctor.dart';
import 'package:my_app/domain/patient.dart';
import 'package:my_app/domain/appointment.dart';

void main() {
  group('Domain-only Hospital tests (no repository)', () {
    late Department dept;
    late Doctor doctor;
    late Patient patient;

    final slot = DateTime(2025, 11, 6, 10, 0);

    setUp(() {
      dept = Department(id: 1, name: 'Cardiology');
      doctor = Doctor(
        name: 'Dr. Ronan',
        id: 101,
        gender: 'M',
        age: 30,
        specialization: 'Cardiologist',
        department: dept,
      );

      dept.addDoctor(doctor);
      patient = Patient(name: 'Bunna', id: 201, gender: 'M', age: 21);
    });

    test('Department contains doctor after addDoctor', () {
      expect(dept.doctors, contains(doctor));
      expect(doctor.department, equals(dept));
    });

    test('Patient can book an appointment', () {
      final ok = patient.bookAppointment(doctor, slot);
      expect(ok, isTrue);
      final appt = patient.appointments.last;
      expect(patient.appointments, contains(appt));
      expect(doctor.appointments, contains(appt));
      expect(appt.status, AppointmentStatus.scheduled);
      expect(appt.patient, equals(patient));
      expect(appt.doctor, equals(doctor));
    });

    test('Patient can cancel their appointment', () {
      final ok = patient.bookAppointment(doctor, slot);
      expect(ok, isTrue);
      final appt = patient.appointments.last;
      patient.cancelAppointment(appt);
      expect(appt.status, AppointmentStatus.canceled);
    });

    test('Doctor can confirm and complete appointment', () {
      final ok = patient.bookAppointment(doctor, slot);
      expect(ok, isTrue);
      final appt = patient.appointments.last;
      doctor.confirmAppointment(appt);
      expect(appt.status, AppointmentStatus.pending);
      doctor.completeAppointment(appt);
      expect(appt.status, AppointmentStatus.completed);
    });
  });
}
