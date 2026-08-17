class Delivery {
  final int? id;
  final int? orderId;
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

  Delivery({
    this.id,
    this.orderId,
    required this.number,
    required this.clientAddress,
    required this.apartment,
    required this.weight,
    this.timeToShop = 0,
    this.distanceToShop = 0.0,
    this.timeReceiving = 0,
    this.timeToClient = 0,
    this.distanceToClient = 0.0,
    this.timeDelivery = 0,
    this.status = 'active',
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      orderId: json['orderId'],
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
}