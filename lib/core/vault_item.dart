import 'dart:convert';

enum ItemKind { password, note, card, totp, category }

class VaultItem {
  final String id;
  final ItemKind kind;
  final String title;
  final String username;
  final String secret;
  final String website;
  final String category;
  final String notes;
  final String expiry;
  final String cvv;
  final bool favorite;
  final DateTime updatedAt;

  const VaultItem({
    required this.id,
    required this.kind,
    required this.title,
    this.username = '',
    this.secret = '',
    this.website = '',
    this.category = 'Osobno',
    this.notes = '',
    this.expiry = '',
    this.cvv = '',
    this.favorite = false,
    required this.updatedAt,
  });

  VaultItem copyWith({
    String? title,
    String? username,
    String? secret,
    String? website,
    String? category,
    String? notes,
    String? expiry,
    String? cvv,
    bool? favorite,
    DateTime? updatedAt,
  }) =>
      VaultItem(
        id: id,
        kind: kind,
        title: title ?? this.title,
        username: username ?? this.username,
        secret: secret ?? this.secret,
        website: website ?? this.website,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        expiry: expiry ?? this.expiry,
        cvv: cvv ?? this.cvv,
        favorite: favorite ?? this.favorite,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'username': username,
        'secret': secret,
        'website': website,
        'category': category,
        'notes': notes,
        'expiry': expiry,
        'cvv': cvv,
        'favorite': favorite,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory VaultItem.fromJson(Map<String, dynamic> data) => VaultItem(
        id: data['id'] as String,
        kind: ItemKind.values.firstWhere(
          (value) => value.name == data['kind'],
          orElse: () => ItemKind.password,
        ),
        title: data['title'] as String? ?? '',
        username: data['username'] as String? ?? '',
        secret: data['secret'] as String? ?? '',
        website: data['website'] as String? ?? '',
        category: data['category'] as String? ?? 'Osobno',
        notes: data['notes'] as String? ?? '',
        expiry: data['expiry'] as String? ?? '',
        cvv: data['cvv'] as String? ?? '',
        favorite: data['favorite'] == true,
        updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  static String encodeAll(List<VaultItem> items) =>
      jsonEncode({'items': items.map((e) => e.toJson()).toList()});
}
