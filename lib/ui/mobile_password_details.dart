import 'package:flutter/material.dart';

import '../core/vault_item.dart';
import 'brand.dart';

/// Android account-detail layout. All data comes from the currently unlocked
/// vault record; this widget never caches a plaintext secret outside its
/// supplied model or sends account details to remote icon providers.
class MobilePasswordDetails extends StatefulWidget {
  final VaultItem item;
  final Future<void> Function(String) onCopy;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onRestore;
  final VoidCallback onErase;

  const MobilePasswordDetails({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onEdit,
    required this.onRemove,
    required this.onRestore,
    required this.onErase,
  });

  @override
  State<MobilePasswordDetails> createState() => _MobilePasswordDetailsState();
}

class _MobilePasswordDetailsState extends State<MobilePasswordDetails> {
  bool revealed = false;

  @override
  void didUpdateWidget(covariant MobilePasswordDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.secret != widget.item.secret ||
        oldWidget.item.trashed != widget.item.trashed) {
      revealed = false;
    }
  }

  Widget _icon(IconData icon, {Color color = VColors.muted, double size = 20}) =>
      Icon(icon, color: color, size: size);

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(13, 12, 13, 12),
  }) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102D42), Color(0xFF071D2E)]),
          border: Border.all(color: VColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _field(IconData icon, String title, String value, {
    VoidCallback? onAction,
    IconData actionIcon = Icons.copy_outlined,
    String actionLabel = 'Kopiraj',
    Color valueColor = VColors.text,
  }) => _panel(
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _icon(icon, size: 21, color: const Color(0xFFD5E5F5)),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: VColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
            maxLines: title == 'Bilješke' ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor, fontSize: 13.5, height: 1.3)),
        ],
      )),
      if (onAction != null)
        IconButton(
          tooltip: actionLabel,
          onPressed: onAction,
          icon: _icon(actionIcon, color: VColors.text, size: 20)),
    ]),
  );

  Widget _hero() {
    final item = widget.item;
    final webUri = Uri.tryParse(item.website);
    final displayWebsite = webUri?.host.isNotEmpty == true
        ? webUri!.host : item.website;
    return _panel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(
            painter: _AccountWavePainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  border: Border.all(color: VColors.border),
                  borderRadius: BorderRadius.circular(17),
                  color: VColors.background,
                ),
                child: Center(child: item.title.toLowerCase().contains('github')
                    ? const SizedBox(
                        width: 67, height: 67,
                        child: CustomPaint(painter: _CatMarkPainter()))
                    : _icon(Icons.key_rounded,
                        color: VColors.accent, size: 34)),
              ),
              const SizedBox(width: 17),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w800, color: VColors.text)),
                  if (displayWebsite.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(children: [
                      _icon(Icons.link, color: VColors.accent, size: 17),
                      const SizedBox(width: 7),
                      Expanded(child: Text(displayWebsite,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VColors.muted, fontSize: 13))),
                    ]),
                  ],
                  const SizedBox(height: 9),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3D53),
                      border: Border.all(color: const Color(0xFF31566C)),
                      borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _icon(Icons.work_outline, size: 13),
                      const SizedBox(width: 5),
                      Text(item.category,
                        style: const TextStyle(
                          color: VColors.muted, fontSize: 11)),
                    ]),
                  ),
                ],
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _password() {
    final secret = widget.item.secret;
    return _panel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(children: [
        Row(children: [
          _icon(Icons.lock_outline,
            color: const Color(0xFFD5E5F5), size: 22),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lozinka', style: TextStyle(
                fontSize: 12, color: VColors.muted)),
              const SizedBox(height: 4),
              Text(revealed ? secret : '••••••••••',
                key: const ValueKey('mobile-detail-password'),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  letterSpacing: 1.5, color: VColors.text, fontSize: 14)),
            ],
          )),
          IconButton(
            tooltip: revealed ? 'Sakrij' : 'Prikaži',
            icon: _icon(revealed
              ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: VColors.text, size: 21),
            onPressed: () => setState(() => revealed = !revealed),
          ),
          IconButton(
            tooltip: 'Kopiraj',
            icon: _icon(Icons.copy_outlined,
              color: VColors.text, size: 20),
            onPressed: secret.isEmpty
              ? null : () => widget.onCopy(secret),
          ),
        ]),
        if (!widget.item.trashed) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 47,
            child: VPrimaryButton(
              label: 'Kopiraj lozinku',
              icon: Icons.copy_outlined,
              onPressed: secret.isEmpty
                ? null : () => widget.onCopy(secret))),
        ],
      ]),
    );
  }

  Widget _action(IconData icon, String label, String sublabel,
      VoidCallback? action) => Expanded(child: Material(
    color: VColors.surface,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: action,
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: VColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          _icon(icon, color: action == null
              ? VColors.muted : VColors.text, size: 20),
          const SizedBox(height: 5),
          Text(label, maxLines: 1,
            style: TextStyle(
              color: action == null ? VColors.muted : VColors.text,
              fontSize: 12, fontWeight: FontWeight.w700)),
          Text(sublabel, maxLines: 1,
            style: const TextStyle(
              color: VColors.muted, fontSize: 9)),
        ]),
      ),
    ),
  ));

  String _formattedDate() {
    const months = [
      'siječnja', 'veljače', 'ožujka', 'travnja',
      'svibnja', 'lipnja', 'srpnja', 'kolovoza',
      'rujna', 'listopada', 'studenoga', 'prosinca',
    ];
    final date = widget.item.updatedAt.toLocal();
    return '${date.day}. ${months[date.month - 1]} ${date.year}.';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ListView(
      key: const ValueKey('mobile-password-details'),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
      children: [
        const Text('Detalji lozinke', style: TextStyle(
          color: VColors.text, fontSize: 25,
          fontWeight: FontWeight.w800, letterSpacing: -.5)),
        const SizedBox(height: 13),
        _hero(),
        if (item.username.isNotEmpty)
          _field(Icons.person_outline,
            'Korisničko ime', item.username,
            onAction: () => widget.onCopy(item.username)),
        if (item.secret.isNotEmpty) _password(),
        if (item.website.isNotEmpty)
          _field(Icons.link, 'Web-adresa', item.website,
            valueColor: VColors.accent,
            // Copy locally instead of opening an unverified external link.
            onAction: () => widget.onCopy(item.website),
            actionLabel: 'Kopiraj web-adresu'),
        if (item.notes.isNotEmpty)
          _field(Icons.description_outlined, 'Bilješke', item.notes),
        _field(Icons.access_time_outlined,
          'Zadnja izmjena', _formattedDate()),
        const SizedBox(height: 6),
        if (item.trashed) ...[
          SizedBox(height: 48, child: VPrimaryButton(
            label: 'Vrati iz Koša',
            icon: Icons.restore,
            onPressed: widget.onRestore)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onErase,
            icon: const Icon(Icons.delete_forever, color: VColors.red),
            label: const Text('Trajno ukloni',
              style: TextStyle(color: VColors.red))),
        ] else ...[
          Row(children: [
            _action(Icons.copy_all_outlined, 'Kopiraj',
              'korisničko ime',
              item.username.isEmpty ? null
                  : () => widget.onCopy(item.username)),
            const SizedBox(width: 9),
            _action(Icons.edit_outlined, 'Uredi',
              'ovaj unos', widget.onEdit),
            const SizedBox(width: 9),
            _action(Icons.lock_outline, 'Podijeli',
              'nije dostupno', null),
          ]),
          const SizedBox(height: 11),
          SizedBox(height: 54, child: OutlinedButton.icon(
            onPressed: widget.onRemove,
            style: OutlinedButton.styleFrom(
              foregroundColor: VColors.red,
              backgroundColor: const Color(0xFF3B1525),
              side: const BorderSide(color: VColors.red),
            ),
            icon: const Icon(Icons.delete_outline,
              color: VColors.red),
            label: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Obriši', style: TextStyle(
                  color: VColors.red, fontWeight: FontWeight.w800)),
                Text('premjesti u Koš',
                  style: TextStyle(
                    color: VColors.muted, fontSize: 9)),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

/// Purely local decoration for the teal wave behind a service identity.
/// It does not fetch brand icons or reference images from outside the app.
class _AccountWavePainter extends CustomPainter {
  const _AccountWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF092539), Color(0xFF104354),
          Color(0xFF071C2C)],
      ).createShader(bounds));
    final underWave = Path()
      ..moveTo(size.width * .55, size.height)
      ..cubicTo(size.width * .73, size.height * .78,
        size.width * .90, size.height * .90,
        size.width, size.height * .18)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(underWave, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft, end: Alignment.topRight,
        colors: [Color(0x0002BEB7), Color(0x8A087D85),
          Color(0x0007AFA7)],
      ).createShader(bounds));
    final lightRibbon = Path()
      ..moveTo(size.width * .61, size.height)
      ..cubicTo(size.width * .77, size.height * .78,
        size.width * .86, size.height * .92,
        size.width, size.height * .27);
    canvas.drawPath(lightRibbon, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft, end: Alignment.topRight,
        colors: [Color(0x0008D7D3), Color(0x6613C9C9),
          Color(0x0031F0E7)],
      ).createShader(bounds));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A compact vector cat mark composed exclusively from local paths. The
/// identity tile never loads a third-party favicon or contacts any host.
class _CatMarkPainter extends CustomPainter {
  const _CatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate(
      (size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 100);
    canvas.drawCircle(const Offset(50, 50), 46,
      Paint()..color = const Color(0xFFF5F8FA));
    final cat = Path()
      ..moveTo(23, 46)
      ..quadraticBezierTo(19, 34, 27, 26)
      ..lineTo(30, 14)
      ..quadraticBezierTo(40, 17, 43, 24)
      ..quadraticBezierTo(50, 21, 58, 24)
      ..quadraticBezierTo(64, 17, 76, 14)
      ..lineTo(76, 30)
      ..quadraticBezierTo(82, 40, 79, 51)
      ..quadraticBezierTo(78, 63, 67, 69)
      ..quadraticBezierTo(63, 73, 63, 80)
      ..lineTo(62, 92)
      ..lineTo(37, 92)
      ..lineTo(36, 79)
      ..quadraticBezierTo(35, 73, 30, 69)
      ..quadraticBezierTo(23, 64, 23, 46)
      ..close();
    canvas.drawPath(cat, Paint()..color = const Color(0xFF091321));
    // Curved tail/shoulder detail within the white disk.
    final tail = Path()
      ..moveTo(37, 80)
      ..cubicTo(26, 84, 21, 75, 18, 70)
      ..cubicTo(15, 65, 11, 66, 13, 70)
      ..cubicTo(17, 85, 28, 93, 40, 88);
    canvas.drawPath(tail, Paint()
      ..color = const Color(0xFF091321)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
