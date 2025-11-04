part of hospital;

class Doctor extends Person {
  String specialization;
  Department department;
  final List<Appointment> appointments = [];

  Doctor({
    required String name,
    required int id,
    required String gender,
    required int age,
    required this.specialization,
    required this.department,
  }) : super(name: name, id: id, gender: gender, age: age);

  bool isAvailable(DateTime date) {
    return !appointments.any(
      (a) => a.date == date && a.status == AppointmentStatus.scheduled,
    );
  }
}
