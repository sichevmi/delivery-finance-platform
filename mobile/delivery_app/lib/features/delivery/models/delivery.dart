class Delivery {
  final int id;
  final int number;
  final String clientAddress;
  final String apartment;
  final double weight;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final double tip;
  final String status;

  const Delivery({
    required this.id,
    required this.number,
    required this.clientAddress,
    required this.apartment,
    required this.weight,
    required this.timeToShop,
    required this.distanceToShop,
    required this.timeReceiving,
    required this.timeToClient,
    required this.distanceToClient,
    required this.timeDelivery,
    this.tip = 0.0,
    this.status = 'active',
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? 0,
      number: json['number'] ?? 0,
      clientAddress: json['clientAddress'] ?? '',
      apartment: json['apartment'] ?? '',
      weight: _roundToTwo((json['weight'] ?? 0).toDouble()),
      timeToShop: json['timeToShop'] ?? 0,
      distanceToShop: _roundToTwo((json['distanceToShop'] ?? 0).toDouble()),
      timeReceiving: json['timeReceiving'] ?? 0,
      timeToClient: json['timeToClient'] ?? 0,
      distanceToClient: _roundToTwo((json['distanceToClient'] ?? 0).toDouble()),
      timeDelivery: json['timeDelivery'] ?? 0,
      tip: _roundToTwo((json['tip'] ?? 0).toDouble()),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'clientAddress': clientAddress,
      'apartment': apartment,
      'weight': _roundToTwo(weight),
      'timeToShop': timeToShop,
      'distanceToShop': _roundToTwo(distanceToShop),
      'timeReceiving': timeReceiving,
      'timeToClient': timeToClient,
      'distanceToClient': _roundToTwo(distanceToClient),
      'timeDelivery': timeDelivery,
      'tip': _roundToTwo(tip),
      'status': status,
    };
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}