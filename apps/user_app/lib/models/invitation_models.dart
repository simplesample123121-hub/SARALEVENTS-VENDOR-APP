enum InvitationVisibility { public, unlisted, private }

class InvitationItem {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? eventDate;
  final String? eventTime; // HH:mm
  final String? venueName;
  final String? address;
  final String? coverImageUrl;
  final List<String> galleryUrls;
  final String slug;
  final InvitationVisibility visibility;
  final int? rsvpLimit;
  final int rsvpCount;
  final String? theme;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvitationItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.eventDate,
    this.eventTime,
    this.venueName,
    this.address,
    this.coverImageUrl,
    this.galleryUrls = const <String>[],
    required this.slug,
    this.visibility = InvitationVisibility.unlisted,
    this.rsvpLimit,
    this.rsvpCount = 0,
    this.theme,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvitationItem.fromMap(Map<String, dynamic> row) {
    return InvitationItem(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      eventDate: row['event_date'] != null ? DateTime.parse(row['event_date'] as String) : null,
      eventTime: row['event_time'] as String?,
      venueName: row['venue_name'] as String?,
      address: row['address'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      galleryUrls: List<String>.from(row['gallery_urls'] ?? const <String>[]),
      slug: row['slug'] as String,
      visibility: _visibilityFromString(row['visibility'] as String?),
      rsvpLimit: (row['rsvp_limit'] as int?),
      rsvpCount: (row['rsvp_count'] as int?) ?? 0,
      theme: row['theme'] as String?,
      createdAt: DateTime.parse((row['created_at'] as String)),
      updatedAt: DateTime.parse((row['updated_at'] as String)),
    );
  }

  static InvitationVisibility _visibilityFromString(String? value) {
    switch ((value ?? 'unlisted').toLowerCase()) {
      case 'public':
        return InvitationVisibility.public;
      case 'private':
        return InvitationVisibility.private;
      default:
        return InvitationVisibility.unlisted;
    }
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'event_date': eventDate?.toIso8601String(),
      'event_time': eventTime,
      'venue_name': venueName,
      'address': address,
      'cover_image_url': coverImageUrl,
      'gallery_urls': galleryUrls,
      'slug': slug,
      'visibility': visibility.name,
      'rsvp_limit': rsvpLimit,
      'theme': theme,
    };
  }
}

class InvitationRsvpItem {
  final String id;
  final String invitationId;
  final String? name;
  final String? email;
  final String? phone;
  final String status; // yes | no | maybe
  final int? guestsCount;
  final String? note;
  final DateTime createdAt;

  const InvitationRsvpItem({
    required this.id,
    required this.invitationId,
    this.name,
    this.email,
    this.phone,
    required this.status,
    this.guestsCount,
    this.note,
    required this.createdAt,
  });

  factory InvitationRsvpItem.fromMap(Map<String, dynamic> row) {
    return InvitationRsvpItem(
      id: row['id'] as String,
      invitationId: row['invitation_id'] as String,
      name: row['name'] as String?,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      status: (row['status'] as String?) ?? 'yes',
      guestsCount: row['guests_count'] as int?,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}


