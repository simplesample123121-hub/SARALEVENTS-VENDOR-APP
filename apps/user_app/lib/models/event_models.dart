class EventType {
  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final List<String> relatedCategories;
  final String? iconName;

  const EventType({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.relatedCategories,
    this.iconName,
  });
}

class EventCategory {
  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final String eventTypeId;
  final String databaseCategory; // Maps to actual database category field

  const EventCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.eventTypeId,
    required this.databaseCategory,
  });
}

// Static data for event types
class EventData {
  static const List<EventType> eventTypes = [
    EventType(
      id: 'wedding',
      name: 'Wedding',
      description: 'Complete wedding planning services',
      imageAsset: 'assets/events/wedding.jpg',
      relatedCategories: ['Venue', 'Photography', 'Decoration', 'Catering', 'Music/Dj', 'Essentials'],
      iconName: 'favorite',
    ),
    EventType(
      id: 'birthday',
      name: 'Birthday',
      description: 'Birthday party celebrations',
      imageAsset: 'assets/events/birthday.jpg',
      relatedCategories: ['Venue', 'Decoration', 'Catering', 'Photography', 'Essentials'],
      iconName: 'cake',
    ),
    EventType(
      id: 'corporate',
      name: 'Corporate',
      description: 'Corporate events and meetings',
      imageAsset: 'assets/events/corporate.jpg',
      relatedCategories: ['Venue', 'Catering', 'Photography', 'Essentials'],
      iconName: 'business',
    ),
    EventType(
      id: 'anniversary',
      name: 'Anniversary',
      description: 'Anniversary celebrations',
      imageAsset: 'assets/events/anniversary.jpg',
      relatedCategories: ['Venue', 'Photography', 'Decoration', 'Catering', 'Music/Dj'],
      iconName: 'celebration',
    ),
    EventType(
      id: 'engagement',
      name: 'Engagement',
      description: 'Engagement ceremonies',
      imageAsset: 'assets/events/engagement.jpg',
      relatedCategories: ['Venue', 'Photography', 'Decoration', 'Catering', 'Music/Dj'],
      iconName: 'diamond',
    ),
    EventType(
      id: 'baby_shower',
      name: 'Baby Shower',
      description: 'Baby shower celebrations',
      imageAsset: 'assets/events/baby_shower.jpg',
      relatedCategories: ['Venue', 'Decoration', 'Catering', 'Photography', 'Essentials'],
      iconName: 'child_care',
    ),
  ];

  static const Map<String, List<EventCategory>> eventCategories = {
    'wedding': [
      EventCategory(
        id: 'wedding_venues',
        name: 'Venues',
        description: 'Lawns, Banquets, Resorts & more',
        imageAsset: 'assets/categories/wedding_venues.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'wedding_decors',
        name: 'Decors',
        description: 'Lights, flowers, stage decor & more',
        imageAsset: 'assets/categories/wedding_decors.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Decoration',
      ),
      EventCategory(
        id: 'wedding_catering',
        name: 'Catering',
        description: 'Veg, Gujarati, North Indian & more',
        imageAsset: 'assets/categories/wedding_catering.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Catering',
      ),
      EventCategory(
        id: 'wedding_photography',
        name: 'Photography',
        description: 'Pre-wedding, Photographer',
        imageAsset: 'assets/categories/wedding_photography.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Photography',
      ),
      EventCategory(
        id: 'wedding_makeup',
        name: 'Makeup Artist',
        description: 'Groom makeup, Bridal makeup',
        imageAsset: 'assets/categories/wedding_makeup.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Essentials', // Assuming makeup falls under essentials
      ),
      EventCategory(
        id: 'wedding_music',
        name: 'Music & Dance',
        description: 'DJ, Live music, Dance performers',
        imageAsset: 'assets/categories/wedding_music.jpg',
        eventTypeId: 'wedding',
        databaseCategory: 'Music/Dj',
      ),
    ],
    'birthday': [
      EventCategory(
        id: 'birthday_venues',
        name: 'Venues',
        description: 'Party halls, Outdoor spaces & more',
        imageAsset: 'assets/categories/birthday_venues.jpg',
        eventTypeId: 'birthday',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'birthday_decoration',
        name: 'Decoration',
        description: 'Balloons, Themes, Backdrops & more',
        imageAsset: 'assets/categories/birthday_decoration.jpg',
        eventTypeId: 'birthday',
        databaseCategory: 'Decoration',
      ),
      EventCategory(
        id: 'birthday_catering',
        name: 'Catering',
        description: 'Cakes, Snacks, Meals & more',
        imageAsset: 'assets/categories/birthday_catering.jpg',
        eventTypeId: 'birthday',
        databaseCategory: 'Catering',
      ),
      EventCategory(
        id: 'birthday_photography',
        name: 'Photography',
        description: 'Event photography & videography',
        imageAsset: 'assets/categories/birthday_photography.jpg',
        eventTypeId: 'birthday',
        databaseCategory: 'Photography',
      ),
      EventCategory(
        id: 'birthday_entertainment',
        name: 'Entertainment',
        description: 'Games, Activities, Performers',
        imageAsset: 'assets/categories/birthday_entertainment.jpg',
        eventTypeId: 'birthday',
        databaseCategory: 'Music/Dj', // Entertainment often includes music/DJ
      ),
    ],
    'corporate': [
      EventCategory(
        id: 'corporate_venues',
        name: 'Venues',
        description: 'Conference halls, Meeting rooms',
        imageAsset: 'assets/categories/corporate_venues.jpg',
        eventTypeId: 'corporate',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'corporate_catering',
        name: 'Catering',
        description: 'Business meals, Coffee breaks',
        imageAsset: 'assets/categories/corporate_catering.jpg',
        eventTypeId: 'corporate',
        databaseCategory: 'Catering',
      ),
      EventCategory(
        id: 'corporate_av',
        name: 'AV Equipment',
        description: 'Projectors, Sound systems',
        imageAsset: 'assets/categories/corporate_av.jpg',
        eventTypeId: 'corporate',
        databaseCategory: 'Essentials',
      ),
      EventCategory(
        id: 'corporate_photography',
        name: 'Photography',
        description: 'Event documentation',
        imageAsset: 'assets/categories/corporate_photography.jpg',
        eventTypeId: 'corporate',
        databaseCategory: 'Photography',
      ),
    ],
    'anniversary': [
      EventCategory(
        id: 'anniversary_venues',
        name: 'Venues',
        description: 'Romantic venues, Banquet halls',
        imageAsset: 'assets/categories/anniversary_venues.jpg',
        eventTypeId: 'anniversary',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'anniversary_photography',
        name: 'Photography',
        description: 'Couple photography, Event coverage',
        imageAsset: 'assets/categories/anniversary_photography.jpg',
        eventTypeId: 'anniversary',
        databaseCategory: 'Photography',
      ),
      EventCategory(
        id: 'anniversary_decoration',
        name: 'Decoration',
        description: 'Romantic decor, Floral arrangements',
        imageAsset: 'assets/categories/anniversary_decoration.jpg',
        eventTypeId: 'anniversary',
        databaseCategory: 'Decoration',
      ),
      EventCategory(
        id: 'anniversary_catering',
        name: 'Catering',
        description: 'Dinner arrangements, Cake services',
        imageAsset: 'assets/categories/anniversary_catering.jpg',
        eventTypeId: 'anniversary',
        databaseCategory: 'Catering',
      ),
    ],
    'engagement': [
      EventCategory(
        id: 'engagement_venues',
        name: 'Venues',
        description: 'Engagement halls, Garden venues',
        imageAsset: 'assets/categories/engagement_venues.jpg',
        eventTypeId: 'engagement',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'engagement_photography',
        name: 'Photography',
        description: 'Ring ceremony, Couple shoots',
        imageAsset: 'assets/categories/engagement_photography.jpg',
        eventTypeId: 'engagement',
        databaseCategory: 'Photography',
      ),
      EventCategory(
        id: 'engagement_decoration',
        name: 'Decoration',
        description: 'Stage decor, Floral arrangements',
        imageAsset: 'assets/categories/engagement_decoration.jpg',
        eventTypeId: 'engagement',
        databaseCategory: 'Decoration',
      ),
      EventCategory(
        id: 'engagement_catering',
        name: 'Catering',
        description: 'Reception catering, Sweets',
        imageAsset: 'assets/categories/engagement_catering.jpg',
        eventTypeId: 'engagement',
        databaseCategory: 'Catering',
      ),
    ],
    'baby_shower': [
      EventCategory(
        id: 'baby_shower_venues',
        name: 'Venues',
        description: 'Party halls, Home venues',
        imageAsset: 'assets/categories/baby_shower_venues.jpg',
        eventTypeId: 'baby_shower',
        databaseCategory: 'Venue',
      ),
      EventCategory(
        id: 'baby_shower_decoration',
        name: 'Decoration',
        description: 'Baby themes, Balloon arrangements',
        imageAsset: 'assets/categories/baby_shower_decoration.jpg',
        eventTypeId: 'baby_shower',
        databaseCategory: 'Decoration',
      ),
      EventCategory(
        id: 'baby_shower_catering',
        name: 'Catering',
        description: 'Party snacks, Themed cakes',
        imageAsset: 'assets/categories/baby_shower_catering.jpg',
        eventTypeId: 'baby_shower',
        databaseCategory: 'Catering',
      ),
      EventCategory(
        id: 'baby_shower_photography',
        name: 'Photography',
        description: 'Maternity shoots, Event coverage',
        imageAsset: 'assets/categories/baby_shower_photography.jpg',
        eventTypeId: 'baby_shower',
        databaseCategory: 'Photography',
      ),
    ],
  };

  static List<EventCategory> getCategoriesForEvent(String eventTypeId) {
    return eventCategories[eventTypeId] ?? [];
  }

  static EventType? getEventTypeById(String id) {
    try {
      return eventTypes.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
}