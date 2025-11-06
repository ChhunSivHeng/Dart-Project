import 'doctor.dart';

class Department {
  final int id;
  String name;
  final List<Doctor> doctors;

  Department({required this.id, required this.name, List<Doctor>? doctors})
    : doctors = doctors ?? [];

  void addDoctor(Doctor doctor) {
    if (!doctors.contains(doctor)) {
      doctors.add(doctor);
      doctor.department = this;
    }
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
