import 'dart:convert';
import 'dart:io';

import '../domain/department.dart';
import '../domain/doctor.dart';
import '../domain/patient.dart';
import '../domain/appointment.dart';

class HospitalRepository {
  final List<Department> departments = [];
  final List<Doctor> doctors = [];
  final List<Patient> patients = [];
  final List<Appointment> appointments = [];

  // Departments
  void addDepartment(Department d) {
    // replace existing by id or add
    final exist = findDepartmentById(d.id);
    if (exist == null) {
      departments.add(d);
    } else {
      exist.name = d.name;
    }
  }

  Department? findDepartmentById(int id) {
    for (var d in departments) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Department> getAllDepartments() => departments;

  // Doctors
  void addDoctor(Doctor d) {
    doctors.add(d);
    if (!d.department.doctors.contains(d)) {
      d.department.addDoctor(d);
    }
  }

  Doctor? findDoctorById(int id) {
    for (var d in doctors) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Doctor> getAllDoctors() => doctors;
  List<Doctor> getDoctorsByDepartmentId(int deptId) =>
      doctors.where((doc) => doc.department.id == deptId).toList();

  // Patients
  void addPatient(Patient p) {
    final exist = findPatientByPhone(p.phoneNumber);
    if (exist == null) {
      patients.add(p);
    } else {
      // update existing info if phone matches
      exist.name = p.name;
      exist.gender = p.gender;
      exist.age = p.age;
    }
  }

  // New: find by phone (primary lookup for patients)
  Patient? findPatientByPhone(String phone) {
    for (var p in patients) {
      if (p.phoneNumber == phone) return p;
    }
    return null;
  }

  // Backward-compatible find by id (kept)
  Patient? findPatientById(int id) {
    for (var p in patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Patient> getAllPatients() => patients;

  // Appointments
  void addAppointment(Appointment a) {
    appointments.add(a);
  }

  List<Appointment> getAppointmentsForDoctor(Doctor d) =>
      appointments.where((a) => a.doctor == d).toList();

  void confirmAppointment(Appointment a) {
    a.status = AppointmentStatus.pending;
  }

  void completeAppointment(Appointment a) {
    a.complete();
  }

  void cancelAppointment(Appointment a) {
    a.cancel();
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'departments': departments.map((d) => d.toJson()).toList(),
      'doctors': doctors.map((d) => d.toJson()).toList(),
      'patients': patients.map((p) => p.toJson()).toList(),
      'appointments': appointments.map((a) => a.toJson()).toList(),
    };
  }

  static HospitalRepository fromJson(Map<String, dynamic> json) {
    final repo = HospitalRepository();

    // departments
    final deps = <int, Department>{};
    for (var d in (json['departments'] as List<dynamic>? ?? [])) {
      final dep = Department(id: d['id'] as int, name: d['name'] as String);
      repo.addDepartment(dep);
      deps[dep.id] = dep;
    }

    // doctors
    final docs = <int, Doctor>{};
    for (var d in (json['doctors'] as List<dynamic>? ?? [])) {
      final deptId = d['departmentId'] as int;
      final dep = deps[deptId] ?? Department(id: deptId, name: 'Unknown');
      final doc = Doctor(
        name: d['name'] as String,
        id: d['id'] as int,
        gender: d['gender'] as String? ?? 'N/A',
        age: d['age'] as int? ?? 0,
        specialization: d['specialization'] as String? ?? '',
        department: dep,
      );
      repo.addDoctor(doc);
      docs[doc.id] = doc;
    }

    // patients (keyed by phone)
    final patsByPhone = <String, Patient>{};
    for (var p in (json['patients'] as List<dynamic>? ?? [])) {
      final phone = (p['phone'] as String?) ?? '';
      final pat = Patient(
        name: p['name'] as String,
        id: p['id'] as int,
        gender: p['gender'] as String? ?? 'N/A',
        age: p['age'] as int? ?? 0,
        phoneNumber: phone,
      );
      repo.addPatient(pat);
      if (phone.isNotEmpty) patsByPhone[phone] = pat;
    }

    // appointments (match by doctor id and patient phone)
    int maxId = 0;
    for (var a in (json['appointments'] as List<dynamic>? ?? [])) {
      final id = a['id'] as int;
      final date = DateTime.parse(a['date'] as String);
      final statusStr = a['status'] as String;
      final status = AppointmentStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => AppointmentStatus.scheduled,
      );
      final doctorId = a['doctorId'] as int;
      final patientPhone =
          a['patientPhone'] as String? ?? a['patientId']?.toString() ?? '';
      final doctor = docs[doctorId];
      final patient =
          patsByPhone[patientPhone] ??
          (a['patientId'] != null
              ? repo.findPatientById(a['patientId'] as int)
              : null);
      if (doctor != null && patient != null) {
        final appt = Appointment(
          id: id,
          date: date,
          status: status,
          doctor: doctor,
          patient: patient,
        );
        repo.addAppointment(appt);
        doctor.appointments.add(appt);
        patient.appointments.add(appt);
        if (id > maxId) maxId = id;
      }
    }

    Appointment.setNextId(maxId + 1);

    return repo;
  }

  // file I/O helpers
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(toJson()));
  }

  static Future<HospitalRepository> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return HospitalRepository();
    final content = await file.readAsString();
    final Map<String, dynamic> data =
        jsonDecode(content) as Map<String, dynamic>;
    return HospitalRepository.fromJson(data);
  }

  // Counts
  int get departmentCount => departments.length;
  int get doctorCount => doctors.length;
  int get patientCount => patients.length;
  int get appointmentCount => appointments.length;
}
