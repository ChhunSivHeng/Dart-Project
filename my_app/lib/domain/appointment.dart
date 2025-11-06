import 'doctor.dart';
import 'patient.dart';

enum AppointmentStatus { scheduled, pending, completed, canceled }

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

  static void setNextId(int n) {
    _nextId = n;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'status': status.name,
    'doctorId': doctor.id,
    'patientId': patient.id,
  };

  void pending() {
    status = AppointmentStatus.pending;
  }

  void complete() {
    status = AppointmentStatus.completed;
  }

  void cancel() {
    status = AppointmentStatus.canceled;
  }
}
