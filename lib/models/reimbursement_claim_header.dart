/// Claim-level fields from the top block of the reimbursement template.
class ReimbursementClaimHeader {
  const ReimbursementClaimHeader({
    required this.fullName,
    required this.peopleId,
    required this.reviewer,
    required this.approver,
    required this.reimbursementCurrency,
    required this.reimbursementAmount,
    required this.claimStatus,
    required this.reimbursementDate,
  });

  final String fullName;
  final String peopleId;
  final String reviewer;
  final String approver;
  final String reimbursementCurrency;
  final double reimbursementAmount;
  final String claimStatus;
  final DateTime reimbursementDate;

  factory ReimbursementClaimHeader.fromJson(Map<String, dynamic> json) {
    return ReimbursementClaimHeader(
      fullName: json['fullName'] as String,
      peopleId: json['peopleId'] as String,
      reviewer: json['reviewer'] as String,
      approver: json['approver'] as String,
      reimbursementCurrency: json['reimbursementCurrency'] as String,
      reimbursementAmount: (json['reimbursementAmount'] as num).toDouble(),
      claimStatus: json['claimStatus'] as String,
      reimbursementDate: DateTime.parse(json['reimbursementDate'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'peopleId': peopleId,
        'reviewer': reviewer,
        'approver': approver,
        'reimbursementCurrency': reimbursementCurrency,
        'reimbursementAmount': reimbursementAmount,
        'claimStatus': claimStatus,
        'reimbursementDate': reimbursementDate.toIso8601String().split('T').first,
      };
}
