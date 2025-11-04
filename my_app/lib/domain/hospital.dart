library hospital;

part 'person.dart';
part 'doctor.dart';
part 'patient.dart';

enum AppointmentStatus { scheduled, completed, canceled }

class Department {
  final int id;
  String name;
  final List<Doctor> doctors;

  Department({required this.id, required this.name, List<Doctor>? doctors})
    : doctors = doctors ?? [];

  void addDoctor(Doctor doctor) {
    if (!doctors.contains(doctor)) {
      doctors.add(doctor);
    }
  }
}

class Appointment {
  static int _nextId = 1;
  final int id;
  final DateTime date;
  AppointmentStatus status;
  final Doctor doctor;
  final Patient patient;

  Appointment({
    int? id,
    required this.date,
    required this.status,
    required this.doctor,
    required this.patient,
  }) : id = id ?? _nextId++;

  void schedule() {
    status = AppointmentStatus.scheduled;
  }

  void complete() {
    status = AppointmentStatus.completed;
  }

  void cancel() {
    status = AppointmentStatus.canceled;
  }
}
