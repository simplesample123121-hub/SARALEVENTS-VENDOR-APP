import 'package:flutter/material.dart';

enum EventType {
  wedding,
  birthday,
  houseParty,
  corporate,
  anniversary,
  graduation,
  babyShower,
  engagement,
  other,
}

enum PaymentStatus {
  paid,
  pending,
  overdue,
  cancelled,
}

enum TaskPriority {
  high,
  medium,
  low,
}

enum CollaboratorRole {
  owner,
  editor,
  viewer,
}

enum ActivityType {
  eventCreated,
  eventUpdated,
  taskAdded,
  taskCompleted,
  guestAdded,
  noteAdded,
  budgetUpdated,
  collaboratorAdded,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.wedding:
        return 'Wedding';
      case EventType.birthday:
        return 'Birthday Party';
      case EventType.houseParty:
        return 'House Party';
      case EventType.corporate:
        return 'Corporate Event';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.graduation:
        return 'Graduation';
      case EventType.babyShower:
        return 'Baby Shower';
      case EventType.engagement:
        return 'Engagement';
      case EventType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.wedding:
        return Icons.favorite;
      case EventType.birthday:
        return Icons.cake;
      case EventType.houseParty:
        return Icons.home;
      case EventType.corporate:
        return Icons.business;
      case EventType.anniversary:
        return Icons.celebration;
      case EventType.graduation:
        return Icons.school;
      case EventType.babyShower:
        return Icons.child_care;
      case EventType.engagement:
        return Icons.diamond;
      case EventType.other:
        return Icons.event;
    }
  }

  Color get color {
    switch (this) {
      case EventType.wedding:
        return Colors.pink;
      case EventType.birthday:
        return Colors.orange;
      case EventType.houseParty:
        return Colors.blue;
      case EventType.corporate:
        return Colors.indigo;
      case EventType.anniversary:
        return Colors.purple;
      case EventType.graduation:
        return Colors.green;
      case EventType.babyShower:
        return Colors.cyan;
      case EventType.engagement:
        return Colors.red;
      case EventType.other:
        return Colors.grey;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.overdue:
        return Icons.warning;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class Event {
  final String id;
  final String userId;
  final String name;
  final EventType type;
  final DateTime date;
  final String? imageUrl;
  final String? description;
  final String? venue;
  final String? venueAddress;
  final double? venueLatitude;
  final double? venueLongitude;
  final PaymentStatus paymentStatus;
  final double? budget;
  final double? spentAmount;
  final int? expectedGuests;
  final int? actualGuests;
  final bool isPublic;
  final bool isArchived;
  final List<String> sharedWith;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.date,
    this.imageUrl,
    this.description,
    this.venue,
    this.venueAddress,
    this.venueLatitude,
    this.venueLongitude,
    required this.paymentStatus,
    this.budget,
    this.spentAmount,
    this.expectedGuests,
    this.actualGuests,
    this.isPublic = false,
    this.isArchived = false,
    this.sharedWith = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUpcoming => date.isAfter(DateTime.now());
  
  Duration get timeUntilEvent => date.difference(DateTime.now());
  
  double get budgetUsedPercentage {
    if (budget == null || budget == 0) return 0.0;
    return ((spentAmount ?? 0) / budget!) * 100;
  }

  bool get hasLocation => venueLatitude != null && venueLongitude != null;

  Event copyWith({
    String? id,
    String? userId,
    String? name,
    EventType? type,
    DateTime? date,
    String? imageUrl,
    String? description,
    String? venue,
    String? venueAddress,
    double? venueLatitude,
    double? venueLongitude,
    PaymentStatus? paymentStatus,
    double? budget,
    double? spentAmount,
    int? expectedGuests,
    int? actualGuests,
    bool? isPublic,
    bool? isArchived,
    List<String>? sharedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      venueLatitude: venueLatitude ?? this.venueLatitude,
      venueLongitude: venueLongitude ?? this.venueLongitude,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      budget: budget ?? this.budget,
      spentAmount: spentAmount ?? this.spentAmount,
      expectedGuests: expectedGuests ?? this.expectedGuests,
      actualGuests: actualGuests ?? this.actualGuests,
      isPublic: isPublic ?? this.isPublic,
      isArchived: isArchived ?? this.isArchived,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'event_type': type.name,
      'event_date': date.toIso8601String(),
      'image_url': imageUrl,
      'description': description,
      'venue': venue,
      'venue_address': venueAddress,
      'venue_latitude': venueLatitude,
      'venue_longitude': venueLongitude,
      'payment_status': paymentStatus.name,
      'budget': budget,
      'spent_amount': spentAmount,
      'expected_guests': expectedGuests,
      'actual_guests': actualGuests,
      'is_public': isPublic,
      'is_archived': isArchived,
      'shared_with': sharedWith,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: EventType.values.firstWhere((e) => e.name == (json['event_type'] ?? json['type'])),
      date: DateTime.parse(json['event_date'] ?? json['date']),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      description: json['description'],
      venue: json['venue'],
      venueAddress: json['venue_address'],
      venueLatitude: json['venue_latitude']?.toDouble(),
      venueLongitude: json['venue_longitude']?.toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == (json['payment_status'] ?? json['paymentStatus'])),
      budget: json['budget']?.toDouble(),
      spentAmount: json['spent_amount']?.toDouble() ?? json['spentAmount']?.toDouble(),
      expectedGuests: json['expected_guests'] ?? json['expectedGuests'],
      actualGuests: json['actual_guests'],
      isPublic: json['is_public'] ?? false,
      isArchived: json['is_archived'] ?? false,
      sharedWith: List<String>.from(json['shared_with'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class ChecklistTask {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? assignedTo;
  final String category;
  final double? estimatedCost;
  final double? actualCost;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChecklistTask({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    this.assignedTo,
    this.category = 'general',
    this.estimatedCost,
    this.actualCost,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  ChecklistTask copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistTask(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'category': category,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'],
      eventId: json['event_id'] ?? json['eventId'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['is_completed'] ?? json['isCompleted'],
      priority: TaskPriority.values.firstWhere((e) => e.name == json['priority']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : 
               (json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null),
      assignedTo: json['assigned_to'] ?? json['assignedTo'],
      category: json['category'] ?? 'general',
      estimatedCost: json['estimated_cost']?.toDouble() ?? json['estimatedCost']?.toDouble(),
      actualCost: json['actual_cost']?.toDouble() ?? json['actualCost']?.toDouble(),
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class GuestCategory {
  final String id;
  final String eventId;
  final String name;
  final int guestCount;
  final List<Guest> guests;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestCategory({
    required this.id,
    required this.eventId,
    required this.name,
    required this.guestCount,
    required this.guests,
    required this.createdAt,
    required this.updatedAt,
  });

  GuestCategory copyWith({
    String? id,
    String? eventId,
    String? name,
    int? guestCount,
    List<Guest>? guests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestCategory(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      guestCount: guestCount ?? this.guestCount,
      guests: guests ?? this.guests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'name': name,
      'guest_count': guestCount,
      'guests': guests.map((g) => g.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GuestCategory.fromJson(Map<String, dynamic> json) {
    return GuestCategory(
      id: json['id'],
      eventId: json['event_id'] ?? json['eventId'],
      name: json['name'],
      guestCount: json['guest_count'] ?? json['guestCount'],
      guests: (json['guests'] as List<dynamic>?)
          ?.map((g) => Guest.fromJson(g))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class Guest {
  final String id;
  final String categoryId;
  final String name;
  final String? email;
  final String? phone;
  final bool isInvited;
  final bool hasResponded;
  final bool isAttending;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Guest({
    required this.id,
    required this.categoryId,
    required this.name,
    this.email,
    this.phone,
    required this.isInvited,
    required this.hasResponded,
    required this.isAttending,
    required this.createdAt,
    required this.updatedAt,
  });

  Guest copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? email,
    String? phone,
    bool? isInvited,
    bool? hasResponded,
    bool? isAttending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guest(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isInvited: isInvited ?? this.isInvited,
      hasResponded: hasResponded ?? this.hasResponded,
      isAttending: isAttending ?? this.isAttending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'email': email,
      'phone': phone,
      'is_invited': isInvited,
      'has_responded': hasResponded,
      'is_attending': isAttending,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'],
      categoryId: json['category_id'] ?? json['categoryId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      isInvited: json['is_invited'] ?? json['isInvited'],
      hasResponded: json['has_responded'] ?? json['hasResponded'],
      isAttending: json['is_attending'] ?? json['isAttending'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class EventNote {
  final String id;
  final String eventId;
  final String userId;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventNote({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.title,
    required this.content,
    this.category = 'general',
    this.isPinned = false,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  EventNote copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? title,
    String? content,
    String? category,
    bool? isPinned,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventNote(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'title': title,
      'content': content,
      'category': category,
      'is_pinned': isPinned,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EventNote.fromJson(Map<String, dynamic> json) {
    return EventNote(
      id: json['id'],
      eventId: json['event_id'] ?? json['eventId'],
      userId: json['user_id'] ?? json['userId'],
      title: json['title'],
      content: json['content'],
      category: json['category'] ?? 'general',
      isPinned: json['is_pinned'] ?? json['isPinned'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

// New enhanced models

class BudgetItem {
  final String id;
  final String eventId;
  final String category;
  final String itemName;
  final double estimatedCost;
  final double? actualCost;
  final String? vendorName;
  final String? vendorContact;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetItem({
    required this.id,
    required this.eventId,
    required this.category,
    required this.itemName,
    required this.estimatedCost,
    this.actualCost,
    this.vendorName,
    this.vendorContact,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get variance => (actualCost ?? 0) - estimatedCost;
  double get variancePercentage => estimatedCost > 0 ? (variance / estimatedCost) * 100 : 0;

  BudgetItem copyWith({
    String? id,
    String? eventId,
    String? category,
    String? itemName,
    double? estimatedCost,
    double? actualCost,
    String? vendorName,
    String? vendorContact,
    PaymentStatus? paymentStatus,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      vendorName: vendorName ?? this.vendorName,
      vendorContact: vendorContact ?? this.vendorContact,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'category': category,
      'item_name': itemName,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'vendor_name': vendorName,
      'vendor_contact': vendorContact,
      'payment_status': paymentStatus.name,
      'payment_date': paymentDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'],
      eventId: json['event_id'],
      category: json['category'],
      itemName: json['item_name'],
      estimatedCost: json['estimated_cost'].toDouble(),
      actualCost: json['actual_cost']?.toDouble(),
      vendorName: json['vendor_name'],
      vendorContact: json['vendor_contact'],
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == json['payment_status']),
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class EventTimeline {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? responsiblePerson;
  final bool isMilestone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventTimeline({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.responsiblePerson,
    this.isMilestone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get duration => endTime?.difference(startTime);

  EventTimeline copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? responsiblePerson,
    bool? isMilestone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventTimeline(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      isMilestone: isMilestone ?? this.isMilestone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'responsible_person': responsiblePerson,
      'is_milestone': isMilestone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EventTimeline.fromJson(Map<String, dynamic> json) {
    return EventTimeline(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'],
      responsiblePerson: json['responsible_person'],
      isMilestone: json['is_milestone'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class EventCollaborator {
  final String id;
  final String eventId;
  final String userId;
  final CollaboratorRole role;
  final String? invitedBy;
  final DateTime invitedAt;
  final DateTime? acceptedAt;

  const EventCollaborator({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.role,
    this.invitedBy,
    required this.invitedAt,
    this.acceptedAt,
  });

  bool get hasAccepted => acceptedAt != null;

  EventCollaborator copyWith({
    String? id,
    String? eventId,
    String? userId,
    CollaboratorRole? role,
    String? invitedBy,
    DateTime? invitedAt,
    DateTime? acceptedAt,
  }) {
    return EventCollaborator(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'role': role.name,
      'invited_by': invitedBy,
      'invited_at': invitedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }

  factory EventCollaborator.fromJson(Map<String, dynamic> json) {
    return EventCollaborator(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      role: CollaboratorRole.values.firstWhere((e) => e.name == json['role']),
      invitedBy: json['invited_by'],
      invitedAt: DateTime.parse(json['invited_at']),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
    );
  }
}

class EventActivity {
  final String id;
  final String eventId;
  final String userId;
  final ActivityType action;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  const EventActivity({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'action': action.name,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EventActivity.fromJson(Map<String, dynamic> json) {
    return EventActivity(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      action: ActivityType.values.firstWhere((e) => e.name == json['action']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class EventStatistics {
  final String eventId;
  final int totalTasks;
  final int completedTasks;
  final double taskCompletionPercentage;
  final int totalGuests;
  final int attendingGuests;
  final double totalBudget;
  final double totalSpent;
  final double budgetUsedPercentage;

  const EventStatistics({
    required this.eventId,
    required this.totalTasks,
    required this.completedTasks,
    required this.taskCompletionPercentage,
    required this.totalGuests,
    required this.attendingGuests,
    required this.totalBudget,
    required this.totalSpent,
    required this.budgetUsedPercentage,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
      eventId: json['event_id'],
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      taskCompletionPercentage: (json['task_completion_percentage'] ?? 0).toDouble(),
      totalGuests: json['total_guests'] ?? 0,
      attendingGuests: json['attending_guests'] ?? 0,
      totalBudget: (json['total_budget'] ?? 0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      budgetUsedPercentage: (json['budget_used_percentage'] ?? 0).toDouble(),
    );
  }
}