import 'domain/hospital.dart';

void main() {
  final dep = Department(id: 1, name: 'Cardiology');
  final doc = Doctor(
    name: 'Dr. Smith',
    id: 1,
    gender: 'M',
    age: 45,
    specialization: 'Cardiologist',
    department: dep,
  );
  final pat = Patient(name: 'Alice', id: 1, gender: 'F', age: 30);

  dep.addDoctor(doc);
  pat.bookAppointment(doc, DateTime(2024, 6, 1, 10, 0));

  assert(
    pat.appointments.isNotEmpty,
    'Patient should have at least one appointment',
  );
  assert(
    doc.appointments.isNotEmpty,
    'Doctor should have at least one appointment',
  );
  assert(
    pat.appointments.first.doctor == doc,
    'Appointment doctor should match',
  );
  assert(
    pat.appointments.first.patient == pat,
    'Appointment patient should match',
  );
  assert(
    pat.appointments.first.status == AppointmentStatus.scheduled,
    'Appointment should be scheduled',
  );

  pat.cancelAppointment(pat.appointments.first);
  assert(
    pat.appointments.first.status == AppointmentStatus.canceled,
    'Appointment should be canceled',
  );

  print('All tests passed!');
}
