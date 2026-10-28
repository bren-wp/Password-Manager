import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';

void main() {
  test('legacy vault records remain readable after card schema extension', () {
    final original = <String, dynamic>{
      'id': 'legacy-1',
      'kind': 'password',
      'title': 'Old login',
      'username': 'old@example.test',
      'secret': 'old secret',
      'website': 'https://example.test',
      'category': 'Osobno',
      'notes': '',
      'favorite': false,
      'updatedAt': '2026-09-01T00:00:00Z',
    };
    final item = VaultItem.fromJson(original);
    expect(item.secret, 'old secret');
    expect(item.expiry, '');
    expect(item.cvv, '');
    expect(item.kind, ItemKind.password);
  });

  test('card expiry and CVV round-trip as encrypted vault payload fields', () {
    final card = VaultItem(
      id: 'card-1',
      kind: ItemKind.card,
      title: 'Demo card',
      username: 'Demo Cardholder',
      secret: '4111111111111111',
      expiry: '12/28',
      cvv: '123',
      updatedAt: DateTime.utc(2026, 10, 28),
    );
    final data = VaultItem.fromJson(jsonDecode(jsonEncode(card.toJson())));
    expect(data.kind, ItemKind.card);
    expect(data.expiry, '12/28');
    expect(data.cvv, '123');
    expect(data.secret, card.secret);
  });

  test('custom category entry is backward compatible with JSON codec', () {
    final category = VaultItem(
      id: 'category-1',
      kind: ItemKind.category,
      title: 'Moja kategorija',
      updatedAt: DateTime.utc(2026, 10, 28),
    );
    expect(VaultItem.fromJson(category.toJson()).kind, ItemKind.category);
  });
}
