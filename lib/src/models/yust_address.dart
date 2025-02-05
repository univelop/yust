import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
part 'yust_address.g.dart';

@JsonSerializable()
@immutable
class YustAddress {
  const YustAddress({
    this.street,
    this.number,
    this.postcode,
    this.city,
    this.country,
  });

  factory YustAddress.withValueByKey(YustAddress address, String key, dynamic value) {
    switch (key) {
      case 'street':
        return address.copyWithStreet(value);
      case 'number':
        return address.copyWithNumber(value);
      case 'postcode':
        return address.copyWithPostcode(value);
      case 'city':
        return address.copyWithCity(value);
      case 'country':
        return address.copyWithCountry(value);
      default:
        return address;
    }
  }

  factory YustAddress.empty() => const YustAddress(
        street: '',
        number: '',
        postcode: '',
        city: '',
        country: '',
      );

  factory YustAddress.fromJson(Map<String, dynamic> json) =>
      _$YustAddressFromJson(json);

  YustAddress copyWithStreet(String? value) => YustAddress(
        street: value,
        number: number,
        postcode: postcode,
        city: city,
        country: country,
      );

  YustAddress copyWithNumber(String? value) => YustAddress(
        city: city,
        country: country,
        number: value,
        postcode: postcode,
        street: street,
      );

  YustAddress copyWithPostcode(String? value) => YustAddress(
        city: city,
        country: country,
        number: number,
        postcode: value,
        street: street,
      );

  YustAddress copyWithCity(String? value) => YustAddress(
        city: value,
        country: country,
        number: number,
        postcode: postcode,
        street: street,
      );

  YustAddress copyWithCountry(String? value) => YustAddress(
        city: city,
        country: value,
        number: number,
        postcode: postcode,
        street: street,
      );

  final String? street;

  final String? number;

  final String? postcode;

  final String? city;

  final String? country;

  /// Returns true if any of the fields are NULL or empty ('')
  bool hasEmptyValues({bool includeCountry = true}) =>
      (street?.isEmpty ?? true) ||
      (number?.isEmpty ?? true) ||
      (postcode?.isEmpty ?? true) ||
      (city?.isEmpty ?? true) ||
      (includeCountry && (country?.isEmpty ?? true));

  bool hasValue({bool includeCountry = true}) =>
      street != null ||
      number != null ||
      postcode != null ||
      city != null ||
      (includeCountry && country != null);

  String toReadableString({bool includeCountry = false}) {
    final parts = [
      if (street != null && number != null) '${street ?? ''} ${number ?? ''}',
      if (postcode != null && city != null) '${postcode ?? ''} ${city ?? ''}',
      if (includeCountry && country != null) country,
    ];
    return parts
        .where((part) => part != null && part.isNotEmpty)
        .map((part) => part?.trimRight())
        .join(', ');
  }

  @override
  bool operator ==(Object other) =>
      other is YustAddress &&
      street == other.street &&
      number == other.number &&
      postcode == other.postcode &&
      city == other.city &&
      country == other.country;

  dynamic operator [](String key) {
    switch (key) {
      case 'street':
        return street;
      case 'number':
        return number;
      case 'postcode':
        return postcode;
      case 'city':
        return city;
      case 'country':
        return country;
      default:
        throw ArgumentError();
    }
  }

  @override
  int get hashCode => Object.hash(street, number, postcode, city, country);

  Map<String, dynamic> toJson() => _$YustAddressToJson(this);
}
