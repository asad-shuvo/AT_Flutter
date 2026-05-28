class PlaceAddressResult {
  const PlaceAddressResult({
    required this.displayAddress,
    this.street = '',
    this.houseNumber = '',
    this.city = '',
    this.postCode = '',
    this.country = 'Austria',
    this.countryCode = 'AT',
    this.lat,
    this.lng,
  });

  final String displayAddress;
  final String street;
  final String houseNumber;
  final String city;
  final String postCode;
  final String country;
  final String countryCode;
  final double? lat;
  final double? lng;
}
