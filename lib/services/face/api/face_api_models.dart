/// JSON shapes of `GET /api/faces/sync`. See docs/FACE_SYNC_API.md.
library;

class RemotePhoto {
  const RemotePhoto({
    required this.id,
    required this.url,
    this.sha256,
    this.updatedAt,
  });

  factory RemotePhoto.fromJson(Map<String, dynamic> json) => RemotePhoto(
    id: json['id'] as String,
    url: json['url'] as String,
    sha256: json['sha256'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );

  final String id;
  final String url;

  /// Hash of the image file; when it is unchanged the photo is not
  /// downloaded again.
  final String? sha256;
  final String? updatedAt;
}

class RemotePerson {
  const RemotePerson({
    required this.id,
    required this.type,
    required this.name,
    this.classSection,
    this.rollNo,
    this.updatedAt,
    this.deleted = false,
    this.photos = const [],
  });

  factory RemotePerson.fromJson(Map<String, dynamic> json) => RemotePerson(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'student',
    name: json['name'] as String? ?? '',
    classSection: json['classSection'] as String?,
    rollNo: json['rollNo']?.toString(),
    updatedAt: json['updatedAt'] as String?,
    deleted: json['deleted'] as bool? ?? false,
    photos: [
      for (final photo in (json['photos'] as List? ?? const []))
        RemotePhoto.fromJson(photo as Map<String, dynamic>),
    ],
  );

  final String id;

  /// `teacher` or `student`.
  final String type;
  final String name;
  final String? classSection;
  final String? rollNo;
  final String? updatedAt;

  /// The person was removed on the server; the phone deletes them.
  final bool deleted;

  /// The complete current set of photos. Stored photos missing from this list
  /// are deleted from the phone.
  final List<RemotePhoto> photos;
}

class SyncPage {
  const SyncPage({
    required this.serverTime,
    required this.people,
    this.nextCursor,
    this.totalPeople,
  });

  factory SyncPage.fromJson(Map<String, dynamic> json) => SyncPage(
    serverTime: json['serverTime'] as String,
    nextCursor: json['nextCursor'] as String?,
    totalPeople: (json['totalPeople'] as num?)?.toInt(),
    people: [
      for (final person in (json['people'] as List? ?? const []))
        RemotePerson.fromJson(person as Map<String, dynamic>),
    ],
  );

  /// The server's clock when this sync started; sent back as `since` next
  /// time.
  final String serverTime;
  final List<RemotePerson> people;

  /// Null on the last page.
  final String? nextCursor;

  /// Optional: how many people the whole sync covers, for the progress bar.
  final int? totalPeople;
}
