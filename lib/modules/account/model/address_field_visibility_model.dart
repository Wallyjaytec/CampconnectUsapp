class AddressFieldVisibility {
  final bool showName;
  final bool requireName;

  final bool showPhone;
  final bool requirePhone;

  final bool showAddress;
  final bool requireAddress;

  final bool showPostalCode;
  final bool requirePostalCode;

  final bool showLocation;

  const AddressFieldVisibility({
    required this.showName,
    required this.requireName,
    required this.showPhone,
    required this.requirePhone,
    required this.showAddress,
    required this.requireAddress,
    required this.showPostalCode,
    required this.requirePostalCode,
    required this.showLocation,
  });

  factory AddressFieldVisibility.defaults() {
    return const AddressFieldVisibility(
      showName: true,
      requireName: false,
      showPhone: true,
      requirePhone: false,
      showAddress: true,
      requireAddress: false,
      showPostalCode: true,
      requirePostalCode: false,
      showLocation: true,
    );
  }

  static bool _isOn(dynamic v, {bool defaultValue = true}) {
    if (v == null) return defaultValue;
    final s = v.toString();
    return s == '1';
  }

  factory AddressFieldVisibility.fromSiteSettings(Map<String, dynamic> m) {
    return AddressFieldVisibility(
      showName: _isOn(m['enable_name_in_checkout'], defaultValue: true),
      requireName: _isOn(m['name_required_in_checkout'], defaultValue: false),

      showPhone: _isOn(m['enable_phone_in_checkout'], defaultValue: true),
      requirePhone: _isOn(m['phone_required_in_checkout'], defaultValue: false),

      showAddress: _isOn(m['enable_address_in_checkout'], defaultValue: true),
      requireAddress: _isOn(
        m['address_required_in_checkout'],
        defaultValue: false,
      ),

      showPostalCode: _isOn(
        m['enable_post_code_in_checkout'],
        defaultValue: true,
      ),
      requirePostalCode: _isOn(
        m['post_code_required_in_checkout'],
        defaultValue: false,
      ),

      showLocation: _isOn(
        m['enable_country_state_city_in_checkout'],
        defaultValue: true,
      ),
    );
  }
}
