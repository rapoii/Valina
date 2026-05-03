/// Intensitas flow menstruasi (mengikuti standar tracking app medis).
enum FlowIntensity {
  spotting('Spotting'),
  light('Ringan'),
  medium('Sedang'),
  heavy('Berat');

  const FlowIntensity(this.label);
  final String label;
}

enum Mood {
  happy('Bahagia'),
  calm('Tenang'),
  energetic('Berenergi'),
  sad('Sedih'),
  anxious('Cemas'),
  irritable('Mudah marah'),
  tired('Lelah');

  const Mood(this.label);
  final String label;
}

enum Symptom {
  cramps('Kram'),
  headache('Sakit kepala'),
  fatigue('Lelah'),
  bloating('Kembung'),
  breastTenderness('Nyeri payudara'),
  acne('Jerawat'),
  backache('Sakit punggung'),
  nausea('Mual'),
  cravings('Ngidam'),
  insomnia('Sulit tidur');

  const Symptom(this.label);
  final String label;
}

enum Discharge {
  dry('Kering'),
  sticky('Lengket'),
  creamy('Krim'),
  eggWhite('Telur mentah'),
  watery('Basah');

  const Discharge(this.label);
  final String label;
}

enum SexualActivity {
  none('Tidak ada'),
  protected('Dengan pengaman'),
  unprotected('Tanpa pengaman');

  const SexualActivity(this.label);
  final String label;
}

enum CycleGoal {
  trackCycle('Lacak siklus'),
  tryConceive('Coba hamil'),
  generalHealth('Pantau kesehatan');

  const CycleGoal(this.label);
  final String label;
}

enum CyclePhase {
  menstrual('Menstruasi'),
  follicular('Folikular'),
  ovulation('Ovulasi'),
  luteal('Luteal');

  const CyclePhase(this.label);
  final String label;
}

/// Jenis kelamin user. `female` = pemilik siklus (bisa edit),
/// `male` = pasangan yang terhubung via kode (hanya view).
enum UserGender {
  female('Perempuan'),
  male('Laki-laki');

  const UserGender(this.label);
  final String label;
}

/// Helper buat parse enum dari string name dengan fallback aman.
T? enumFromName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
