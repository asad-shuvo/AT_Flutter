import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/drive/data/drive_models.dart';

class DriveRepository {
  DriveRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
  })  : _apiClient = apiClient,
        _sessionCache = userSessionCache;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;

  static const String _storageAreaId = '3ad098f9-346d-4463-8ce2-0c9f8ec82901';
  static const String _tenantId = 'EDB4E319-4CCE-49CE-B877-275C8A8E5568';

  Future<_AuthContext?> _auth() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    return _AuthContext(
      accessToken: session.accessToken,
      userId: session.userId,
      personId: session.personId,
      managerNr: session.managerNr,
      displayName: session.displayName,
    );
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'bearer $token',
        'Origin': _apiClient.originUrl,
      };

  // ─── Workspace ────────────────────────────────────────────────────────────

  Future<String?> resolveWorkspaceId(String ownerUserId) async {
    final auth = await _auth();
    if (auth == null) return null;

    // Fallback to auth userId if ownerUserId not yet resolved
    final effectiveOwnerId =
        ownerUserId.isNotEmpty ? ownerUserId : auth.userId;
    if (effectiveOwnerId.isEmpty) return null;

    const workspaceFields =
        'ItemId,Name,Description,IsShared,IsDefault,OwnerId,StorageAreaId,TotalStorageSpace,UsedStorageSpace';
    final workspaceQuery =
        'Select <$workspaceFields>from<Workspace>where<IsShared=__eql(false) & OwnerId=__eql($effectiveOwnerId)>pageNumber=<0>pageSize= <1>';

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'Workspace',
        'Text': workspaceQuery,
        'ExcludeCount': true,
      },
      headers: _headers(auth.accessToken),
    );

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final bodyStatusCode = body['StatusCode'] as int? ?? body['statusCode'] as int? ?? -1;
    final results = body['Results'];
    if (bodyStatusCode == 0 && results is List && results.isNotEmpty) {
      return results.first['ItemId'] as String?;
    }

    // No workspace yet — create one (ignore errors: workspace may already exist)
    try {
      await _createWorkspace(effectiveOwnerId, auth.accessToken);
    } catch (_) {
      // ignore — workspace may already exist
    }

    // Retry query
    final retry = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'Workspace',
        'Text': workspaceQuery,
        'ExcludeCount': true,
      },
      headers: _headers(auth.accessToken),
    );
    final retryBody = retry['body'] as Map<String, dynamic>? ?? {};
    final retryStatusCode = retryBody['StatusCode'] as int? ?? retryBody['statusCode'] as int? ?? -1;
    final retryResults = retryBody['Results'];
    if (retryStatusCode == 0 && retryResults is List && retryResults.isNotEmpty) {
      return retryResults.first['ItemId'] as String?;
    }
    return null;
  }

  Future<void> _createWorkspace(String ownerUserId, String token) async {
    final payload = {
      'OwnerId': ownerUserId,
      'TenantId': _tenantId,
      'TotalStorageSpace': 1000,
    };
    await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/CreateUserWorkspace',
      body: payload,
      headers: _headers(token),
    );
    await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/CreateSharedWorkspace',
      body: payload,
      headers: _headers(token),
    );
  }

  // ─── Listing ──────────────────────────────────────────────────────────────

  Future<DriveListResult?> getDriveList({
    required String customerPersonId,
    required List<String> ownerIds,
    String? parentId,
    bool isArchived = false,
    String? tag,
    bool? isFavorite,
    int pageNumber = 0,
    int pageSize = 10,
  }) async {
    final auth = await _auth();
    if (auth == null) return null;

    final payload = <String, dynamic>{
      'CustomerPersonId': customerPersonId,
      'OwnerIds': ownerIds,
      'ParentId': parentId,
      'IsArchived': isArchived,
      'Pagination': {'pageNumber': pageNumber, 'pageSize': pageSize},
      'Sort': {
        'SortBy': 'MetaData.ExternalDocumentCreateDate.Value',
        'SortOrder': 'desc',
      },
      'ExcludeCount': false,
    };

    if (tag != null) {
      payload['Tag'] = tag;
    } else if (isFavorite == true) {
      payload['IsFavorite'] = true;
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}SelectNetworkQuery/GetDriveList',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final totalCount = body['TotalCount'] as int? ?? 0;
    final data = body['Data'] as Map<String, dynamic>? ?? {};

    final folders = _parseFolders(data['Folders']);
    final files = _parseFiles(data['Files']);

    return DriveListResult(
      folders: folders,
      files: files,
      totalCount: totalCount,
    );
  }

  Future<DriveListResult?> searchDocuments({
    required String ownerUserId,
    String? parentId,
    required String searchText,
    String? folderId,
  }) async {
    final auth = await _auth();
    if (auth == null) return null;

    final fields = [
      'ItemId', 'Name', 'ParentId', 'Tags', 'WorkSpaceId', 'ArtifactType',
      'FileStorageId', 'OwnerId', 'OwnerName', 'CreateDate', 'MetaData',
      'IsFavorite', 'IsArchived', 'CreatedBy', 'ThumbnailId',
    ];

    final basePayload = <String, dynamic>{
      'Text': searchText,
      'ResponseFields': fields,
      'Filter': {
        'SkipOwnerId': true,
        'MatchCriteria': [
          {'Property': 'MetaData', 'Match': 'all'},
          {'Property': 'Tags', 'Match': 'all'},
        ],
      },
    };

    // Determine tags/filters from context
    final folderTags = <String>[];
    final fileTags = <String>[];
    Map<String, dynamic>? folderExtra;
    Map<String, dynamic>? fileExtra;
    String? resolvedParentId = parentId;

    if (folderId != null) {
      if (folderId == DriveDefaultFolders.portalFilesId) {
        folderTags.add('portal-file');
        fileTags.add('portal-file');
        resolvedParentId = null;
      } else if (folderId == DriveDefaultFolders.dossiersId) {
        folderTags.add('dossier-file');
        fileTags.add('dossier-file');
        resolvedParentId = null;
      } else if (folderId == DriveDefaultFolders.myContractsId) {
        folderTags.add('my-contract-file');
        fileTags.add('my-contract-file');
        resolvedParentId = null;
      } else if (folderId == DriveDefaultFolders.archivedId) {
        folderExtra = {'IsArchived': true};
        fileExtra = {'IsArchived': true};
        resolvedParentId = null;
      } else if (folderId == DriveDefaultFolders.starredId) {
        folderExtra = {'IsFavorite': true};
        fileExtra = {'IsFavorite': true};
        resolvedParentId = null;
      } else {
        folderTags.add('create-folder');
        fileTags.add('upload-file');
      }
    }

    // Folder search payload
    final folderPayload = Map<String, dynamic>.from(basePayload);
    final folderFilter = Map<String, dynamic>.from(
        folderPayload['Filter'] as Map<String, dynamic>);
    folderFilter['ArtifactType'] = 1;
    folderFilter['Tags'] = folderTags;
    folderFilter['OwnerId'] = ownerUserId;
    if (folderExtra != null) folderFilter.addAll(folderExtra);
    folderPayload['Filter'] = folderFilter;
    folderPayload['ParentId'] = resolvedParentId;

    // File search payload
    final filePayload = Map<String, dynamic>.from(basePayload);
    final fileFilter = Map<String, dynamic>.from(
        filePayload['Filter'] as Map<String, dynamic>);
    fileFilter['ArtifactType'] = 2;
    fileFilter['Tags'] = fileTags;
    fileFilter['OwnerId'] = ownerUserId;
    if (fileExtra != null) fileFilter.addAll(fileExtra);
    filePayload['Filter'] = fileFilter;
    filePayload['ParentId'] = resolvedParentId;

    final results = await Future.wait([
      _apiClient.postJson(
        url: '${_apiClient.dmsServiceUrl}DmsCommand/SearchObjectArtifact',
        body: folderPayload,
        headers: _headers(auth.accessToken),
      ),
      _apiClient.postJson(
        url: '${_apiClient.dmsServiceUrl}DmsCommand/SearchObjectArtifact',
        body: filePayload,
        headers: _headers(auth.accessToken),
      ),
    ]);

    final folderRes = results[0]['body'] as Map<String, dynamic>? ?? {};
    final fileRes = results[1]['body'] as Map<String, dynamic>? ?? {};

    final folderData = folderRes['Result'] as Map<String, dynamic>? ?? {};
    final fileData = fileRes['Result'] as Map<String, dynamic>? ?? {};

    final folders = _parseFolders(folderData['Result']);
    final files = _parseFiles(fileData['Result']);

    return DriveListResult(
      folders: folders,
      files: files,
      totalCount: folders.length + files.length,
    );
  }

  // ─── Folder commands ──────────────────────────────────────────────────────

  Future<bool> createFolder({
    required String name,
    required String workspaceId,
    String? parentId,
  }) async {
    final auth = await _auth();
    if (auth == null) return false;

    final objectArtifactId = newGuid();
    final payload = {
      'ObjectArtifactId': objectArtifactId,
      'Name': name.trim(),
      'Description': '',
      'ParentId': parentId,
      'StorageAreaId': _storageAreaId,
      'WorkspaceId': workspaceId,
      'Tags': ['create-folder'],
      'MetaData': {
        'ExternalDocumentCreateDate': {
          'Type': 'string',
          'Value': DateTime.now().toIso8601String(),
        },
      },
    };

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/CreateFolder',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final success = (body['statusCode'] == 0 || body['StatusCode'] == 0);
    if (success) {
      _insertActivityLog(
        objectArtifactId: objectArtifactId,
        title: name.trim(),
        tag: 'drive-folder',
        parentId: parentId,
        personId: auth.personId,
        accessToken: auth.accessToken,
      );
    }
    return success;
  }

  void _insertActivityLog({
    required String objectArtifactId,
    required String title,
    required String tag,
    String? parentId,
    required String personId,
    required String accessToken,
    String? managerNr,
    String? displayName,
  }) {
    final activityEntityId = parentId != null && parentId.isNotEmpty
        ? '$objectArtifactId,$parentId'
        : objectArtifactId;
    final logPayload = {
      'EntityName': 'SnActivityLog',
      'JsonString': jsonEncode({
        'ItemId': newGuid(),
        'Tags': ['Is-A-FilipUpdate', tag],
        'Language': 'en-US',
        'ActionType': 'Insert',
        'ActivityEntityName': 'ObjectArtifact',
        'ActivityEntityId': activityEntityId,
        'ActivityTitle': title,
        'OrganizerPersonId': personId,
        'ActivitySource': 'MANUAL',
        'IsLatest': true,
      }),
      'EventData': {'EventType': 'SnActivityLog.Created'},
    };
    _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Insert',
      body: logPayload,
      headers: _headers(accessToken),
    );
    if ((tag == 'drive-file' || tag == 'portal-file') &&
        managerNr != null &&
        managerNr.isNotEmpty &&
        displayName != null) {
      _sendDriveUploadEmail(
        managerNr: managerNr,
        fileName: title,
        personId: personId,
        displayName: displayName,
        accessToken: accessToken,
      );
    }
  }

  void _sendDriveUploadEmail({
    required String managerNr,
    required String fileName,
    required String personId,
    required String displayName,
    required String accessToken,
  }) {
    final query =
        'Select <DisplayName,PersonId,Language>from<AdvisorDenormalized>where<ManagerNr=__eql($managerNr)>pageNumber=<0>pageSize= <1>';
    _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {'EntityName': 'AdvisorDenormalized', 'Text': query, 'ExcludeCount': true},
      headers: _headers(accessToken),
    ).then((response) {
      final body = response['body'] as Map<String, dynamic>? ?? {};
      final results = body['Results'];
      if (results is! List || results.isEmpty) return;
      final advisor = results.first;
      if (advisor is! Map) return;
      final advisorPersonId = advisor['PersonId'] as String?;
      if (advisorPersonId == null || advisorPersonId.isEmpty) return;
      final advisorDisplayName = advisor['DisplayName'] as String? ?? '';
      final advisorLanguage = advisor['Language'] as String? ?? 'en-US';
      final addedBy = advisorLanguage == 'en-US'
          ? 'your customer $displayName'
          : 'von Ihrem Kunde $displayName';
      final mailPayload = {
        'To': [advisorPersonId],
        'Bcc': <String>[],
        'Cc': <String>[],
        'DataContext': {
          'FullName': advisorDisplayName,
          'FileName': fileName,
          'AddedBy': addedBy,
          'DocumentLink': '${_apiClient.originUrl}/customers/$personId/drive/folder/root',
        },
        'Purpose': 'DriveFileUploadEmailForFE',
        'Language': advisorLanguage,
      };
      final mailUri =
          _apiClient.mailServiceUrl.replaceFirst('https:', 'http:') + '/MailCommand/SendEmail';
      _apiClient.postJson(
        url: '${_apiClient.aggregatorUrl}Execute',
        body: {
          'HttpCalls': [
            {
              'Uri': mailUri,
              'Verb': 'Post',
              'Payload': jsonEncode(mailPayload),
              'SuccessIf': jsonEncode({'StatusCode': 0}),
            }
          ],
        },
        headers: _headers(accessToken),
      );
    }).catchError((_) {});
  }

  // ─── Rename ───────────────────────────────────────────────────────────────

  Future<bool> renameObject({
    required String objectArtifactId,
    required String newName,
    String? sourceFileId,
  }) async {
    final auth = await _auth();
    if (auth == null) return false;

    final payload = <String, dynamic>{
      'NewName': newName.trim(),
      'ObjectArtifactId': objectArtifactId,
    };
    if (sourceFileId != null) payload['SourceFileId'] = sourceFileId;

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/RenameObjectArtifact',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    return (body['statusCode'] == 0 || body['StatusCode'] == 0);
  }

  // ─── Favorite ─────────────────────────────────────────────────────────────

  Future<bool> toggleFavorite({
    required String objectArtifactId,
    required bool currentIsFavorite,
    required String ownerUserId,
  }) async {
    final auth = await _auth();
    if (auth == null) return false;

    final payload = {
      'ObjectArtifactId': objectArtifactId,
      'FavoriteFor': ownerUserId,
      'FavoriteStatus': !currentIsFavorite,
      'IsFavorite': !currentIsFavorite,
    };

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/AddToFavorite',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    return (body['statusCode'] == 0 || body['StatusCode'] == 0);
  }

  // ─── Archive / Restore ────────────────────────────────────────────────────

  Future<bool> archiveItem({
    required String objectArtifactId,
    required bool isArchived,
  }) async {
    final auth = await _auth();
    if (auth == null) return false;

    final payload = {
      'ArchivedFor': '',
      'ArchivedStatus': isArchived,
      'IsArchived': isArchived,
      'ObjectArtifactId': objectArtifactId,
    };

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/ArchiveObjectArtifact',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors != null) return errors['IsValid'] == true;
    return (body['statusCode'] == 0 || body['StatusCode'] == 0);
  }

  // ─── Permanent Delete ─────────────────────────────────────────────────────

  Future<bool> permanentDeleteItem(String objectArtifactId) async {
    final auth = await _auth();
    if (auth == null) return false;

    final payload = {'ObjectArtifactId': objectArtifactId};

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/DeleteObjectArtifact',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors != null) return errors['IsValid'] == true;
    return (body['statusCode'] == 0 || body['StatusCode'] == 0);
  }

  // ─── Upload ───────────────────────────────────────────────────────────────

  Future<String?> getPresignedUploadUrl({
    required String fileId,
    required String fileName,
  }) async {
    final auth = await _auth();
    if (auth == null) return null;

    final metaDataJson = jsonEncode({
      'Title': {'Type': 'String', 'Value': fileName},
      'OriginalName': {'Type': 'String', 'Value': fileName},
    });

    final payload = {
      'ItemId': fileId,
      'Name': fileName,
      'MetaData': metaDataJson,
      'ParentDirectoryId': null,
      'Tags': jsonEncode(['upload-file']),
    };

    final response = await _apiClient.postJson(
      url: '${_apiClient.storageServiceUrl}StorageQuery/GetPreSignedUrlForUpload',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    return body['UploadUrl'] as String?;
  }

  Future<bool> putFileBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final statusCode = await _apiClient.putBytes(
        url: uploadUrl,
        bytes: bytes,
        contentType: contentType,
        extraHeaders: {'x-ms-blob-type': 'BlockBlob'},
      );
      return statusCode >= 200 && statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createFileArtifact({
    required String objectArtifactId,
    required String fileStorageId,
    required String fileName,
    required String workspaceId,
    required String customerPersonId,
    String? parentId,
    bool generateThumbnail = false,
    required int fileSizeBytes,
    bool logActivity = true,
  }) async {
    final auth = await _auth();
    if (auth == null) return false;

    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    final fileSizeStr = _formatFileSize(fileSizeBytes);

    final payload = <String, dynamic>{
      'ParentId': parentId,
      'ObjectArtifactId': objectArtifactId,
      'FileStorageId': fileStorageId,
      'Tags': ['upload-file'],
      'FileName': fileName,
      'WorkspaceId': workspaceId,
      'GenerateThumbnail': generateThumbnail,
      'MetaData': {
        'DocumentSize': {'Type': 'string', 'Value': fileSizeStr},
        'ExternalDocumentCreateDate': {
          'Type': 'string',
          'Value': DateTime.now().toIso8601String(),
        },
        'FileType': {'Type': 'string', 'Value': ext},
        'RelatedTo': {'Type': 'string', 'Value': 'Drive'},
        'Source': {'Type': 'string', 'Value': 'Filip'},
        'SourceEntityName': {'Type': 'string', 'Value': 'Person'},
        'SourceId': {'Type': 'string', 'Value': customerPersonId},
      },
    };

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/UploadFile',
      body: payload,
      headers: _headers(auth.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    final success = errors != null
        ? errors['IsValid'] == true
        : (body['statusCode'] == 0 || body['StatusCode'] == 0);
    if (success && logActivity) {
      _insertActivityLog(
        objectArtifactId: objectArtifactId,
        title: fileName,
        tag: 'drive-file',
        parentId: parentId,
        personId: auth.personId,
        accessToken: auth.accessToken,
        managerNr: auth.managerNr,
        displayName: auth.displayName,
      );
    }
    return success;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<DriveFolder> _parseFolders(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((f) {
      return DriveFolder(
        itemId: f['ItemId'] as String? ?? '',
        name: f['Name'] as String? ?? '',
        ownerId: f['OwnerId'] as String?,
        ownerName: f['OwnerName'] as String?,
        isFavorite: f['IsFavorite'] as bool? ?? false,
        isArchived: f['IsArchived'] as bool? ?? false,
        createDate: f['CreateDate'] as String?,
        metaData: f['MetaData'] is Map
            ? Map<String, dynamic>.from(f['MetaData'] as Map)
            : null,
      );
    }).toList();
  }

  List<DriveFile> _parseFiles(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((f) {
      return DriveFile(
        itemId: f['ItemId'] as String? ?? '',
        name: f['Name'] as String? ?? '',
        ownerId: f['OwnerId'] as String?,
        ownerName: f['OwnerName'] as String?,
        fileStorageId: f['FileStorageId'] as String?,
        thumbnailId: f['ThumbnailId'] as String?,
        isFavorite: f['IsFavorite'] as bool? ?? false,
        isArchived: f['IsArchived'] as bool? ?? false,
        createDate: f['CreateDate'] as String?,
        metaData: f['MetaData'] is Map
            ? Map<String, dynamic>.from(f['MetaData'] as Map)
            : null,
        tags: f['Tags'] as List?,
        source: (f['MetaData'] is Map) &&
                ((f['MetaData'] as Map)['Source'] is Map)
            ? ((f['MetaData'] as Map)['Source'] as Map)['Value'] as String?
            : null,
      );
    }).toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 bytes';
    final units = <String>['bytes', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, units.length - 1);
    final val = bytes / pow(1024, i);
    return '${val.toStringAsFixed(1)} ${units[i]}';
  }
}

class DriveListResult {
  const DriveListResult({
    required this.folders,
    required this.files,
    required this.totalCount,
  });

  final List<DriveFolder> folders;
  final List<DriveFile> files;
  final int totalCount;
}

class _AuthContext {
  const _AuthContext({
    required this.accessToken,
    required this.userId,
    required this.personId,
    this.managerNr,
    required this.displayName,
  });

  final String accessToken;
  final String userId;
  final String personId;
  final String? managerNr;
  final String displayName;
}
