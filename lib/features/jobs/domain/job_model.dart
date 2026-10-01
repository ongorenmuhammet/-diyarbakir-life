class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String district;
  final String? salary;
  final String jobType; // Tam Zamanlı, Yarı Zamanlı, Staj, Proje Bazlı
  final String description;
  final List<String> requirements;
  final String contactEmail;
  final String? contactPhone;
  final String date;
  final String? ownerEmail;
  final String status; // 'approved' or 'pending'

  const JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.district,
    this.salary,
    required this.jobType,
    required this.description,
    required this.requirements,
    required this.contactEmail,
    this.contactPhone,
    required this.date,
    this.ownerEmail,
    this.status = 'approved',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'district': district,
      'salary': salary,
      'jobType': jobType,
      'description': description,
      'requirements': requirements,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'date': date,
      'ownerEmail': ownerEmail,
      'status': status,
    };
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      district: json['district'] as String,
      salary: json['salary'] as String?,
      jobType: json['jobType'] as String,
      description: json['description'] as String,
      requirements: List<String>.from(json['requirements'] as List),
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String?,
      date: json['date'] as String,
      ownerEmail: json['ownerEmail'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
