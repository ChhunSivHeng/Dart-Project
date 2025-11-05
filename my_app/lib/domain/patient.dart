part of hospital;

class Patient extends Person {
  final List<Appointment> appointments = [];

  Patient({
    required String name,
    required int id,
    required String gender,
    required int age,
  }) : super(name: name, id: id, gender: gender, age: age);

  bool bookAppointment(Doctor doctor, DateTime date) {
    if (!doctor.isAvailable(date)) return false;

    final appointment = Appointment(
      date: date,
      status: AppointmentStatus.scheduled,
      doctor: doctor,
      patient: this,
    );
    appointments.add(appointment);
    doctor.appointments.add(appointment);
    return true;
  }

  void cancelAppointment(Appointment appointment) {
    appointment.cancel();
  }
}
