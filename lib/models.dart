import 'dart:convert';
import 'package:latlong2/latlong.dart';

class MaterialPrice {
  const MaterialPrice({
    required this.category,
    required this.icon,
    required this.hindi,
    required this.marathi,
    required this.rate,
    required this.low,
    required this.high,
    required this.unit,
    required this.trend,
    this.co2OffsetPerKg = 1.8, // kg of CO2 saved per kg recycled
    this.esgPointsPerKg = 15,   // Green Credits points multiplier
  });

  final String category;
  final String icon;
  final String hindi;
  final String marathi;
  final double rate;
  final double low;
  final double high;
  final String unit;
  final double trend;
  final double co2OffsetPerKg;
  final int esgPointsPerKg;

  MaterialPrice copyWith({
    String? category,
    String? icon,
    String? hindi,
    String? marathi,
    double? rate,
    double? low,
    double? high,
    String? unit,
    double? trend,
    double? co2OffsetPerKg,
    int? esgPointsPerKg,
  }) {
    return MaterialPrice(
      category: category ?? this.category,
      icon: icon ?? this.icon,
      hindi: hindi ?? this.hindi,
      marathi: marathi ?? this.marathi,
      rate: rate ?? this.rate,
      low: low ?? this.low,
      high: high ?? this.high,
      unit: unit ?? this.unit,
      trend: trend ?? this.trend,
      co2OffsetPerKg: co2OffsetPerKg ?? this.co2OffsetPerKg,
      esgPointsPerKg: esgPointsPerKg ?? this.esgPointsPerKg,
    );
  }
}

class RecyclerInfo {
  const RecyclerInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.authorization,
    required this.categories,
    required this.distanceKm,
    required this.pickup,
    required this.rateFactor,
    required this.phone,
    required this.latLng,
  });

  final String id;
  final String name;
  final String location;
  final String authorization;
  final List<String> categories;
  final double distanceKm;
  final bool pickup;
  final double rateFactor;
  final String phone;
  final LatLng latLng;
}

class WasteLot {
  WasteLot({
    required this.id,
    required this.category,
    required this.description,
    required this.weight,
    required this.estimatedValue,
    required this.quotedPrice,
    required this.finalPrice,
    required this.createdAt,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.recyclerId,
    required this.recyclerName,
    required this.status,
    required this.paymentStatus,
    required this.paymentMode,
    required this.imageBase64,
    required this.synced,
    this.compositionBreakdown = 'E-waste standard scrap',
    this.hazardLevel = 'Low',
    this.greenCreditsEarned = 0,
  });

  final String id;
  final String category;
  final String description;
  final double weight;
  final double estimatedValue;
  final double quotedPrice;
  final double finalPrice;
  final DateTime createdAt;
  final String location;
  final double? latitude;
  final double? longitude;
  final String recyclerId;
  final String recyclerName;
  final String status;
  final String paymentStatus;
  final String paymentMode;
  final String imageBase64;
  final bool synced;
  final String compositionBreakdown;
  final String hazardLevel;
  final int greenCreditsEarned;

  WasteLot copyWith({
    String? recyclerId,
    String? recyclerName,
    double? quotedPrice,
    double? finalPrice,
    String? status,
    String? paymentStatus,
    String? paymentMode,
    bool? synced,
    String? compositionBreakdown,
    String? hazardLevel,
    int? greenCreditsEarned,
  }) {
    return WasteLot(
      id: id,
      category: category,
      description: description,
      weight: weight,
      estimatedValue: estimatedValue,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      createdAt: createdAt,
      location: location,
      latitude: latitude,
      longitude: longitude,
      recyclerId: recyclerId ?? this.recyclerId,
      recyclerName: recyclerName ?? this.recyclerName,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      imageBase64: imageBase64,
      synced: synced ?? this.synced,
      compositionBreakdown: compositionBreakdown ?? this.compositionBreakdown,
      hazardLevel: hazardLevel ?? this.hazardLevel,
      greenCreditsEarned: greenCreditsEarned ?? this.greenCreditsEarned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'description': description,
        'weight': weight,
        'estimatedValue': estimatedValue,
        'quotedPrice': quotedPrice,
        'finalPrice': finalPrice,
        'createdAt': createdAt.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'recyclerId': recyclerId,
        'recyclerName': recyclerName,
        'status': status,
        'paymentStatus': paymentStatus,
        'paymentMode': paymentMode,
        'imageBase64': imageBase64,
        'synced': synced,
        'compositionBreakdown': compositionBreakdown,
        'hazardLevel': hazardLevel,
        'greenCreditsEarned': greenCreditsEarned,
      };

  factory WasteLot.fromJson(Map<String, dynamic> json) => WasteLot(
        id: json['id']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Other',
        description: json['description']?.toString() ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0,
        quotedPrice: (json['quotedPrice'] as num?)?.toDouble() ?? 0,
        finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        location: json['location']?.toString() ?? 'Unknown',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        recyclerId: json['recyclerId']?.toString() ?? '',
        recyclerName: json['recyclerName']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Draft',
        paymentStatus: json['paymentStatus']?.toString() ?? 'Pending',
        paymentMode: json['paymentMode']?.toString() ?? 'Cash',
        imageBase64: json['imageBase64']?.toString() ?? '',
        synced: json['synced'] == true,
        compositionBreakdown: json['compositionBreakdown']?.toString() ?? 'E-waste standard scrap',
        hazardLevel: json['hazardLevel']?.toString() ?? 'Low',
        greenCreditsEarned: (json['greenCreditsEarned'] as num?)?.toInt() ?? 0,
      );

  static String encodeList(List<WasteLot> lots) =>
      jsonEncode(lots.map((lot) => lot.toJson()).toList());

  static List<WasteLot> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WasteLot.fromJson)
        .toList();
  }
}
