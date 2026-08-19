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
    this.status = 'active',
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? 0,
      number: json['number'] ?? 0,
      clientAddress: json['clientAddress'] ?? '',
      apartment: json['apartment'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      timeToShop: json['timeToShop'] ?? 0,
      distanceToShop: (json['distanceToShop'] ?? 0).toDouble(),
      timeReceiving: json['timeReceiving'] ?? 0,
      timeToClient: json['timeToClient'] ?? 0,
      distanceToClient: (json['distanceToClient'] ?? 0).toDouble(),
      timeDelivery: json['timeDelivery'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'clientAddress': clientAddress,
      'apartment': apartment,
      'weight': weight,
      'timeToShop': timeToShop,
      'distanceToShop': distanceToShop,
      'timeReceiving': timeReceiving,
      'timeToClient': timeToClient,
      'distanceToClient': distanceToClient,
      'timeDelivery': timeDelivery,
      'status': status,
    };
  }
}