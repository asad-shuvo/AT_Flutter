class ContractsLookupOption {
  const ContractsLookupOption({required this.label, required this.value});

  final String label;
  final String value;
}

class ContractsPartnerOption {
  const ContractsPartnerOption({required this.itemId, required this.name});

  final String itemId;
  final String name;
}

class ContractDocument {
  const ContractDocument({
    required this.itemId,
    required this.name,
    required this.uploadDate,
    this.fileStorageId,
  });

  final String itemId;
  final String? name;
  final DateTime uploadDate;
  final String? fileStorageId;
}
