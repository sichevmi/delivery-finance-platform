class Delivery {
  final int number;
  final String clientAddress;
  final double weight;
  final String apartment;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final String? returnReason;

  Delivery({
    required this.number,
    required this.clientAddress,
    required this.weight,
    required this.apartment,
    required this.timeToShop,
    required this.distanceToShop,
    required this.timeReceiving,
    required this.timeToClient,
    required this.distanceToClient,
    required this.timeDelivery,
    this.returnReason,
  });
}