import 'dart:math';

class DriveDefaultFolders {
  static const String portalFilesId = '7195e98c-925c-49d6-b461-91eadcae7e14';
  static const String starredId = 'e5724271-79a3-457d-b747-5544e329366a';
  static const String archivedId = 'eb88dbae-4d0a-48ce-a5b9-b7d97ba8ba36';
  static const String dossiersId = '6f1e5dfd-5049-42ce-a264-7e349d1cf405';
  static const String myContractsId = 'a80f8237-532e-4881-a739-1d1348ce3b02';

  static const List<String> allIds = [
    portalFilesId,
    starredId,
    archivedId,
    dossiersId,
    myContractsId,
  ];

  static bool isDefaultFolder(String? id) => allIds.contains(id);
  static bool isCreateDisabled(String? id) => allIds.contains(id);

  static bool isArchivedContext(String? id) => id == archivedId;
  static bool isStarredContext(String? id) => id == starredId;

  static List<DriveFolder> buildDefaultList() {
    return [
      DriveFolder(
        itemId: portalFilesId,
        name: 'tns.DMS_PORTAL_FILES',
        isDefault: true,
        isCreateDisabled: true,
      ),
      DriveFolder(
        itemId: starredId,
        name: 'tns.DMS_STARRED_DOCUMENTS',
        isDefault: true,
        isCreateDisabled: true,
      ),
      DriveFolder(
        itemId: archivedId,
        name: 'tns.DMS_ARCHIVED_DOCUMENTS',
        isDefault: true,
        isCreateDisabled: true,
      ),
      DriveFolder(
        itemId: dossiersId,
        name: 'tns.DMS_DOSSIERS',
        isDefault: true,
        isCreateDisabled: true,
      ),
      DriveFolder(
        itemId: myContractsId,
        name: 'tns.DMS_MY_CONTRACTS',
        isDefault: true,
        isCreateDisabled: true,
      ),
    ];
  }
}

class DriveFolder {
  const DriveFolder({
    required this.itemId,
    required this.name,
    this.ownerId,
    this.ownerName,
    this.isFavorite = false,
    this.isArchived = false,
    this.createDate,
    this.isDefault = false,
    this.isCreateDisabled = false,
    this.metaData,
  });

  final String itemId;
  final String name;
  final String? ownerId;
  final String? ownerName;
  final bool isFavorite;
  final bool isArchived;
  final String? createDate;
  final bool isDefault;
  final bool isCreateDisabled;
  final Map<String, dynamic>? metaData;

  DriveFolder copyWith({
    String? name,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return DriveFolder(
      itemId: itemId,
      name: name ?? this.name,
      ownerId: ownerId,
      ownerName: ownerName,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createDate: createDate,
      isDefault: isDefault,
      isCreateDisabled: isCreateDisabled,
      metaData: metaData,
    );
  }

  DateTime get sortDate {
    final ext = metaData?['ExternalDocumentCreateDate']?['Value'] as String?;
    if (ext != null) {
      return DateTime.tryParse(ext) ?? DateTime(0);
    }
    return DateTime.tryParse(createDate ?? '') ?? DateTime(0);
  }
}

class DriveFile {
  const DriveFile({
    required this.itemId,
    required this.name,
    this.ownerId,
    this.ownerName,
    this.fileStorageId,
    this.thumbnailId,
    this.isFavorite = false,
    this.isArchived = false,
    this.createDate,
    this.metaData,
    this.tags,
    this.source,
  });

  final String itemId;
  final String name;
  final String? ownerId;
  final String? ownerName;
  final String? fileStorageId;
  final String? thumbnailId;
  final bool isFavorite;
  final bool isArchived;
  final String? createDate;
  final Map<String, dynamic>? metaData;
  final List<dynamic>? tags;
  final String? source;

  String get fileType {
    final ft = metaData?['FileType']?['Value'] as String?;
    return ft?.toUpperCase() ?? _extensionFromName.toUpperCase();
  }

  String get _extensionFromName {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  String get fileSizeLabel {
    final ds = metaData?['DocumentSize']?['Value'] as String?;
    if (ds != null && ds.isNotEmpty && ds != '0') return ds;
    return '';
  }

  bool get canPermanentDelete {
    final src = metaData?['Source']?['Value'] as String?;
    return isArchived && (src?.toLowerCase() == 'filip');
  }

  DriveFile copyWith({
    String? name,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return DriveFile(
      itemId: itemId,
      name: name ?? this.name,
      ownerId: ownerId,
      ownerName: ownerName,
      fileStorageId: fileStorageId,
      thumbnailId: thumbnailId,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createDate: createDate,
      metaData: metaData,
      tags: tags,
      source: source,
    );
  }

  DateTime get sortDate {
    final ext = metaData?['ExternalDocumentCreateDate']?['Value'] as String?;
    if (ext != null) {
      return DateTime.tryParse(ext) ?? DateTime(0);
    }
    return DateTime.tryParse(createDate ?? '') ?? DateTime(0);
  }

  int get fileSizeBytes {
    final ds = metaData?['DocumentSize']?['Value'] as String?;
    if (ds == null) return 0;
    // parse "3.2 MB" or "4.7 KB" etc.
    final match = RegExp(r'([\d.]+)\s*(bytes|KB|MB|GB)', caseSensitive: false)
        .firstMatch(ds);
    if (match == null) return 0;
    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2)?.toUpperCase() ?? '';
    switch (unit) {
      case 'KB':
        return (value * 1024).round();
      case 'MB':
        return (value * 1024 * 1024).round();
      case 'GB':
        return (value * 1024 * 1024 * 1024).round();
      default:
        return value.round();
    }
  }
}

class DriveBreadcrumb {
  const DriveBreadcrumb({required this.name, required this.itemId});

  final String name;
  final String itemId;
}

enum DriveViewMode { list, grid }

enum DriveSortMode {
  nameAZ,
  nameZA,
  largestFirst,
  smallestFirst,
  newestFirst,
  oldestFirst,
}

String newGuid() {
  final rng = Random();
  String hex(int bits) => rng.nextInt(1 << bits).toRadixString(16).padLeft(bits ~/ 4, '0');
  // hex(48) exceeds Dart's Random.nextInt 2^32 limit — split into hex(32)+hex(16)
  return '${hex(32)}-${hex(16)}-4${hex(12)}-${(8 + rng.nextInt(4)).toRadixString(16)}${hex(12)}-${hex(32)}${hex(16)}';
}
