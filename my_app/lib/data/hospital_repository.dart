import '../domain/hospital.dart';

class HospitalRepository {
  final List<Department> departments = [];
  final List<Doctor> doctors = [];
  final List<Patient> patients = [];
  final List<Appointment> appointments = [];

  void addDepartment(Department department) => departments.add(department);
  void addDoctor(Doctor doctor) {
    doctors.add(doctor);
    doctor.department.addDoctor(doctor);
  }

  void addPatient(Patient patient) => patients.add(patient);
  void addAppointment(Appointment appointment) => appointments.add(appointment);

  Department? getDepartmentByIndex(int index) =>
      (index >= 0 && index < departments.length) ? departments[index] : null;
  Doctor? getDoctorByIndex(int index) =>
      (index >= 0 && index < doctors.length) ? doctors[index] : null;
  Patient? getPatientByIndex(int index) =>
      (index >= 0 && index < patients.length) ? patients[index] : null;

  Doctor? findDoctorById(int id) {
    try {
      return doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Patient? findPatientById(int id) {
    try {
      return patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  int get departmentCount => departments.length;
  int get doctorCount => doctors.length;
  int get patientCount => patients.length;
  int get appointmentCount => appointments.length;
}
