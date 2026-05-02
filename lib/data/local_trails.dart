import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class LocalTrails {
  static final List<TrailModel> all = [
    TrailModel(
      id: 'trail_001',
      name: 'Appalachian Trail - Springer Mountain',
      location: const GeoPoint(34.6275, -84.1938),
      difficulty: 'Moderate',
      lengthMiles: 8.4,
      elevationFt: 3782,
      riskScore: 25,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'The southern terminus of the Appalachian Trail. A classic Georgia hike with beautiful forest scenery.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
    TrailModel(
      id: 'trail_002',
      name: 'Blood Mountain Loop',
      location: const GeoPoint(34.7421, -83.9338),
      difficulty: 'Hard',
      lengthMiles: 6.1,
      elevationFt: 4461,
      riskScore: 45,
      riskLevel: 'Moderate',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'The highest peak on the Georgia AT section. Rocky summit with panoramic views.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
    TrailModel(
      id: 'trail_003',
      name: 'Stone Mountain Trail',
      location: const GeoPoint(33.8057, -84.1457),
      difficulty: 'Easy',
      lengthMiles: 1.3,
      elevationFt: 1686,
      riskScore: 10,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'A short but rewarding summit hike up the exposed granite face of Stone Mountain.',
      state: 'Georgia',
      region: 'Metro Atlanta',
    ),
    TrailModel(
      id: 'trail_004',
      name: 'Amicalola Falls Trail',
      location: const GeoPoint(34.5673, -84.2459),
      difficulty: 'Moderate',
      lengthMiles: 4.2,
      elevationFt: 2100,
      riskScore: 30,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'Trail through Amicalola Falls State Park, passing the tallest cascading waterfall east of the Mississippi.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
    TrailModel(
      id: 'trail_005',
      name: 'Kennesaw Mountain Summit',
      location: const GeoPoint(33.9898, -84.5780),
      difficulty: 'Easy',
      lengthMiles: 2.5,
      elevationFt: 1808,
      riskScore: 15,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'Popular Civil War battlefield hike near Marietta with great city views from the summit.',
      state: 'Georgia',
      region: 'Metro Atlanta',
    ),
    TrailModel(
      id: 'trail_006',
      name: 'Cloudland Canyon Waterfalls',
      location: const GeoPoint(34.8374, -85.4835),
      difficulty: 'Hard',
      lengthMiles: 5.0,
      elevationFt: 1980,
      riskScore: 65,
      riskLevel: 'High',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'Steep canyon descent with two waterfall overlooks. Stairs and switchbacks throughout.',
      state: 'Georgia',
      region: 'Northwest Georgia',
    ),
    TrailModel(
      id: 'trail_007',
      name: 'Anna Ruby Falls Trail',
      location: const GeoPoint(34.7279, -83.7307),
      difficulty: 'Easy',
      lengthMiles: 1.6,
      elevationFt: 1614,
      riskScore: 8,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'A paved trail through Helen, Georgia leading to twin waterfalls in Unicoi State Park.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
    TrailModel(
      id: 'trail_008',
      name: 'Tallulah Gorge Rim Trail',
      location: const GeoPoint(34.7393, -83.3910),
      difficulty: 'Moderate',
      lengthMiles: 3.0,
      elevationFt: 1060,
      riskScore: 50,
      riskLevel: 'Moderate',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'Rim trail above one of the deepest gorges in the eastern US. Dramatic overlooks throughout.',
      state: 'Georgia',
      region: 'Northeast Georgia',
    ),
    TrailModel(
      id: 'trail_009',
      name: 'Raven Cliff Falls',
      location: const GeoPoint(34.7005, -83.8124),
      difficulty: 'Moderate',
      lengthMiles: 5.0,
      elevationFt: 1200,
      riskScore: 20,
      riskLevel: 'Low',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'A forest trail in the Chattahoochee National Forest leading to a 100-foot waterfall.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
    TrailModel(
      id: 'trail_010',
      name: 'Brasstown Bald Summit',
      location: const GeoPoint(34.8741, -83.8102),
      difficulty: 'Hard',
      lengthMiles: 1.0,
      elevationFt: 4784,
      riskScore: 35,
      riskLevel: 'Moderate',
      lastUpdated: DateTime(2025, 1, 1),
      description:
          'Short but steep trail to the highest point in Georgia. 360-degree views on clear days.',
      state: 'Georgia',
      region: 'North Georgia',
    ),
  ];

  static TrailModel? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
