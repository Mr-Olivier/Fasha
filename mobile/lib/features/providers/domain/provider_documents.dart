import 'verification_status.dart';

/// Mirrors the backend's ProviderDocumentsResponse - booleans only, never
/// a raw file path (see the backend DTO's own doc comment for why).
class ProviderDocuments {
  const ProviderDocuments({
    required this.idDocumentUploaded,
    required this.tradeCertificateUploaded,
    required this.selfieUploaded,
    this.documentsSubmittedAt,
    required this.verificationStatus,
  });

  final bool idDocumentUploaded;
  final bool tradeCertificateUploaded;
  final bool selfieUploaded;
  final DateTime? documentsSubmittedAt;
  final VerificationStatus verificationStatus;

  bool get canSubmit => idDocumentUploaded && selfieUploaded;

  factory ProviderDocuments.fromJson(Map<String, dynamic> json) => ProviderDocuments(
        idDocumentUploaded: json['idDocumentUploaded'] as bool,
        tradeCertificateUploaded: json['tradeCertificateUploaded'] as bool,
        selfieUploaded: json['selfieUploaded'] as bool,
        documentsSubmittedAt:
            json['documentsSubmittedAt'] != null ? DateTime.parse(json['documentsSubmittedAt'] as String) : null,
        verificationStatus: VerificationStatusJson.fromWire(json['verificationStatus'] as String),
      );
}
