/// Pet mood states for the AI report and dashboard.
enum PetMood {
  happy,
  excited,
  calm,
  lazy,
  aggressive,
}

extension PetMoodExtension on PetMood {
  String get displayName {
    switch (this) {
      case PetMood.happy:
        return 'Happy';
      case PetMood.excited:
        return 'Excited';
      case PetMood.calm:
        return 'Calm';
      case PetMood.lazy:
        return 'Lazy';
      case PetMood.aggressive:
        return 'Aggressive';
    }
  }

  String get emoji {
    switch (this) {
      case PetMood.happy:
        return '😊';
      case PetMood.excited:
        return '🐕';
      case PetMood.calm:
        return '😌';
      case PetMood.lazy:
        return '😴';
      case PetMood.aggressive:
        return '😠';
    }
  }
}
