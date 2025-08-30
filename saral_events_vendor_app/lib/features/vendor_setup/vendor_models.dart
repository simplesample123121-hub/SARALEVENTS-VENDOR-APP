import 'dart:io';

class VendorProfile {
  final String? id;
  final String userId;
  final String businessName;
  final String address;
  final String category;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? description;
  final List<String> services;
  final List<VendorDocument> documents;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorProfile({
    this.id,
    required this.userId,
    required this.businessName,
    required this.address,
    required this.category,
    this.phoneNumber,
    this.email,
    this.website,
    this.description,
    required this.services,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'address': address,
      'category': category,
      'phone_number': phoneNumber,
      'email': email,
      'website': website,
      'description': description,
      'services': services,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      address: json['address'],
      category: json['category'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      website: json['website'],
      description: json['description'],
      services: List<String>.from(json['services'] ?? []),
      documents: [], // Documents will be fetched separately
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class VendorDocument {
  final String? id;
  final String vendorId;
  final String documentType;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final DateTime uploadedAt;

  VendorDocument({
    this.id,
    required this.vendorId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory VendorDocument.fromJson(Map<String, dynamic> json) {
    return VendorDocument(
      id: json['id'],
      vendorId: json['vendor_id'],
      documentType: json['document_type'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
