import '../domain/hospital.dart';

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
    final exist = findPatientById(p.id);
    if (exist == null) {
      patients.add(p);
    } else {
      // update basic info
      exist.name = p.name;
      exist.gender = p.gender;
      exist.age = p.age;
    }
  }
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

  // Counts
  int get departmentCount => departments.length;
  int get doctorCount => doctors.length;
  int get patientCount => patients.length;
  int get appointmentCount => appointments.length;
}
