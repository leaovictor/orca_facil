class PixPayload {
  final String key;
  final String name;
  final String city;
  final String? txId;
  final double? amount;

  PixPayload({
    required this.key,
    required this.name,
    this.city = 'BRASIL', // Default city if not provided
    this.txId,
    this.amount,
  });

  String generatePayload() {
    final buffer = StringBuffer();

    // 00 - Payload Format Indicator
    _appendTLV(buffer, '00', '01');

    // 26 - Merchant Account Information
    final merchantAccountInfo = StringBuffer();
    _appendTLV(
      merchantAccountInfo,
      '00',
      'BR.GOV.BCB.PIX',
    ); // Must be uppercase
    _appendTLV(merchantAccountInfo, '01', key);
    _appendTLV(buffer, '26', merchantAccountInfo.toString());

    // 52 - Merchant Category Code
    _appendTLV(buffer, '52', '0000');

    // 53 - Transaction Currency
    _appendTLV(buffer, '53', '986'); // BRL

    // 54 - Transaction Amount (Optional)
    if (amount != null && amount! > 0) {
      _appendTLV(buffer, '54', amount!.toStringAsFixed(2));
    }

    // 58 - Country Code
    _appendTLV(buffer, '58', 'BR');

    // 59 - Merchant Name (normalized to remove special characters)
    _appendTLV(buffer, '59', _normalizeText(_truncate(name, 25)));

    // 60 - Merchant City (normalized to remove special characters)
    _appendTLV(buffer, '60', _normalizeText(_truncate(city, 15)));

    // 62 - Additional Data Field Template
    final additionalData = StringBuffer();
    _appendTLV(additionalData, '05', _normalizeText(txId ?? '***'));
    _appendTLV(buffer, '62', additionalData.toString());

    // 63 - CRC16
    final payloadWithoutCrc = '${buffer.toString()}6304';
    final crc = _calculateCRC16(payloadWithoutCrc);

    return '$payloadWithoutCrc$crc';
  }

  void _appendTLV(StringBuffer buffer, String id, String value) {
    buffer.write(id);
    buffer.write(value.length.toString().padLeft(2, '0'));
    buffer.write(value);
  }

  String _truncate(String value, int length) {
    if (value.length <= length) return value;
    return value.substring(0, length);
  }

  /// Normalizes text to remove accents and special characters
  /// PIX EMV standard requires only ASCII characters
  String _normalizeText(String text) {
    // Remove accents and convert to uppercase
    const withAccents = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñ';
    const withoutAccents = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNn';

    String normalized = text.toUpperCase();

    for (int i = 0; i < withAccents.length; i++) {
      normalized = normalized.replaceAll(withAccents[i], withoutAccents[i]);
    }

    // Keep only alphanumeric and spaces
    normalized = normalized.replaceAll(RegExp(r'[^A-Z0-9\s]'), '');

    return normalized;
  }

  String _calculateCRC16(String payload) {
    int crc = 0xFFFF;
    final bytes = payload.codeUnits;

    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }

    return (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
