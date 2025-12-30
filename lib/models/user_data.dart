import 'dart:convert';

class UserData {
  String? name;
  int? age;
  double? height;  // Tinggi badan dalam cm
  double? weight;  // Berat badan dalam kg
  bool hasDiabetes;
  bool hasHypertension;
  bool isOnDiet;

  UserData({
    this.name,
    this.age,
    this.height,
    this.weight,
    this.hasDiabetes = false,
    this.hasHypertension = false,
    this.isOnDiet = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'hasDiabetes': hasDiabetes,
      'hasHypertension': hasHypertension,
      'isOnDiet': isOnDiet,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      hasDiabetes: json['hasDiabetes'] ?? false,
      hasHypertension: json['hasHypertension'] ?? false,
      isOnDiet: json['isOnDiet'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserData.fromJsonString(String jsonString) {
    return UserData.fromJson(jsonDecode(jsonString));
  }

  // Get display name (full name)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'Pengguna';
  }

  // Get first name only (for greeting)
  String get firstName {
    if (name != null && name!.isNotEmpty) {
      // Split by space and take first word
      final parts = name!.trim().split(' ');
      return parts.first;
    }
    return 'Pengguna';
  }

  // Calculate BMI (Body Mass Index)
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Tidak tersedia';
    if (bmiValue < 18.5) return 'Kurus';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Gemuk';
    return 'Obesitas';
  }

  // Get list of health conditions
  List<String> get healthConditions {
    List<String> conditions = [];
    if (hasDiabetes) conditions.add('Diabetes');
    if (hasHypertension) conditions.add('Hipertensi');
    if (isOnDiet) conditions.add('Diet');
    return conditions;
  }

  // Check if user has any health conditions
  bool get hasHealthConditions {
    return hasDiabetes || hasHypertension || isOnDiet;
  }

  // Check if user profile is complete
  bool get isProfileComplete {
    return name != null && 
           name!.isNotEmpty && 
           age != null && 
           height != null && 
           weight != null;
  }
}
