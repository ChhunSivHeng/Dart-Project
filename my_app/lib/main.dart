import 'data/hospital_repository.dart';
import 'domain/department.dart';
import 'domain/doctor.dart';
import 'ui/hospital_console.dart';

Future<void> main() async {
  const snapshot = 'hospital_snapshot.json';
  final repo = await HospitalRepository.loadFromFile(snapshot);

  // Bootstraps Department + Doctor if repo empty, then runHospitalConsole(repo)
  if (repo.doctorCount == 0 &&
      repo.patientCount == 0 &&
      repo.departmentCount == 0) {
    final cardiology = Department(id: 1, name: 'Cardiology');
    repo.addDepartment(cardiology);

    final drHeng = Doctor(
      name: 'Dr. Chhun Sivheng',
      id: 101,
      gender: 'M',
      age: 20,
      specialization: 'Adults',
      department: cardiology,
    );
    repo.addDoctor(drHeng);

    await repo.saveToFile(snapshot);
  }

  runHospitalConsole(repo);
}
