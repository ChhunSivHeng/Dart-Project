import 'data/hospital_repository.dart';
import 'domain/department.dart';
import 'domain/doctor.dart';
import 'ui/hospital_console.dart';

Future<void> main() async {
  const snapshot = 'hospital_data.json';
  final repo = await HospitalRepository.loadFromFile(snapshot);

  if (repo.doctorCount == 0 &&
      repo.patientCount == 0 &&
      repo.departmentCount == 0) {
    final cardiology = Department(id: 1, name: 'Cardiology');
    repo.addDepartment(cardiology);

    final drHeng = Doctor(
      name: 'Dr. Ronan',
      id: 101,
      gender: 'M',
      age: 30,
      specialization: 'Adults Heart Surgeon',
      department: cardiology,
    );
    repo.addDoctor(drHeng);

    await repo.saveToFile(snapshot);
  }

  runHospitalConsole(repo);
}
