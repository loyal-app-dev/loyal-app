import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const LoyalApp());
}

class LoyalApp extends StatelessWidget {
  const LoyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOYAL. 1.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

// ============================================================================
// MODELE DANYCH I KOMPONENTY GRAFICZNE KART
// ============================================================================

class StampCardModel {
  final String id;
  final String shopName;
  final String rewardTitle;
  final String ruleText;
  int currentStamps;
  final int maxStamps;
  final int columnsPerRow;
  final String expiresDate;
  final IconData icon;
  final Color themeColor;
  final Color cardTint;
  final Color iconBgColor;

  StampCardModel({
    required this.id,
    required this.shopName,
    required this.rewardTitle,
    required this.ruleText,
    required this.currentStamps,
    required this.maxStamps,
    required this.columnsPerRow,
    required this.expiresDate,
    required this.icon,
    required this.themeColor,
    required this.cardTint,
    required this.iconBgColor,
  });
}

class ActivityLogItem {
  final String initials;
  final String customerName;
  final String actionText;
  final String timeLabel;
  final Color bgColor;
  final Color textColor;

  ActivityLogItem({
    required this.initials,
    required this.customerName,
    required this.actionText,
    required this.timeLabel,
    required this.bgColor,
    required this.textColor,
  });
}

class TicketDivider extends StatelessWidget {
  final Color cutoutColor;
  final Color lineColor;

  const TicketDivider({
    super.key,
    required this.cutoutColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 18,
            decoration: BoxDecoration(
              color: cutoutColor,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(color: lineColor),
            ),
          ),
          Container(
            width: 9,
            height: 18,
            decoration: BoxDecoration(
              color: cutoutColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    double startX = 4;
    while (startX < size.width - 4) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + 4, size.height / 2),
        paint,
      );
      startX += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final double radius = (size.width / 2) - 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const int dashes = 18;
    const double gapAngle = (2 * pi) / dashes;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * gapAngle,
        gapAngle * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerReticlePainter extends CustomPainter {
  final Color cornerColor;
  final bool showLaser;

  _ScannerReticlePainter({required this.cornerColor, required this.showLaser});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(18),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Paint cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double len = 28;
    const double r = 14;

    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
        ..lineTo(size.width, size.height - len),
      cornerPaint,
    );

    if (showLaser) {
      final double laserY = size.height * 0.68;
      canvas.drawLine(
        Offset(16, laserY),
        Offset(size.width - 16, laserY),
        Paint()
          ..color = AppTheme.accentCoral
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerReticlePainter oldDelegate) =>
      oldDelegate.cornerColor != cornerColor || oldDelegate.showLaser != showLaser;
}

// ============================================================================
// GŁÓWNA POWŁOKA APLIKACJI + SYNCHRONIZACJA MIĘDZY DWOMA TELEFONAMI
// ============================================================================

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Kanał synchronizacji na żywo między dwoma telefonami
  static const String _syncTopicUrl = 'https://ntfy.sh/loyal_app_sync_kozakufa_v1';
  Timer? _syncTimer;
  String _lastEventId = '';

  bool isBusinessMode = false;
  int memberTabIndex = 0;
  int businessTabIndex = 0;

  // Realne statystyki dla wersji 1.0
  int totalStampsGiven = 19;
  int uniqueCustomers = 3;
  int totalRewardsRedeemed = 1;

  late List<StampCardModel> walletCards;
  late List<ActivityLogItem> activityLogs;

  @override
  void initState() {
    super.initState();
    walletCards = [
      StampCardModel(
        id: 'northstar',
        shopName: 'Northstar Coffee',
        rewardTitle: 'FREE COFFEE',
        ruleText: 'Collect 10 · Get free coffee',
        currentStamps: 8,
        maxStamps: 10,
        columnsPerRow: 5,
        expiresDate: 'Expires 28 Jun 2026',
        icon: Icons.coffee_outlined,
        themeColor: AppTheme.accentCoral,
        cardTint: const Color(0xFFFFF8F5),
        iconBgColor: const Color(0xFFFCE6DF),
      ),
      StampCardModel(
        id: 'sunday',
        shopName: 'Sunday Bakery',
        rewardTitle: 'FRESH PASTRY',
        ruleText: 'Collect 6 · Get fresh pastry',
        currentStamps: 4,
        maxStamps: 6,
        columnsPerRow: 6,
        expiresDate: 'Expires 14 Jul 2026',
        icon: Icons.bakery_dining_outlined,
        themeColor: AppTheme.accentPurple,
        cardTint: const Color(0xFFFAF9FE),
        iconBgColor: const Color(0xFFEDE8FA),
      ),
      StampCardModel(
        id: 'greenhouse',
        shopName: 'Greenhouse',
        rewardTitle: '£15 REWARD',
        ruleText: 'Collect 8 · Get £15 reward',
        currentStamps: 5,
        maxStamps: 8,
        columnsPerRow: 4,
        expiresDate: 'Expires 02 Aug 2026',
        icon: Icons.eco_outlined,
        themeColor: AppTheme.primaryGreen,
        cardTint: const Color(0xFFF6FAF7),
        iconBgColor: const Color(0xFFE3EFE8),
      ),
    ];

    activityLogs = [
      ActivityLogItem(
        initials: 'AM',
        customerName: 'Alex Morgan',
        actionText: 'Northstar Coffee · 8/10 stamps',
        timeLabel: 'Active card',
        bgColor: AppTheme.softCoralBg,
        textColor: AppTheme.accentCoral,
      ),
    ];

    // Nasłuchiwanie zdarzeń z drugiego telefonu co 2 sekundy
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollRemoteEvents());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendRemoteEvent(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse(_syncTopicUrl),
        body: jsonEncode(data),
      );
    } catch (_) {
      // Ignoruj błędy sieci w trybie offline
    }
  }

  Future<void> _pollRemoteEvents() async {
    try {
      final res = await http.get(Uri.parse('$_syncTopicUrl/json?poll=1&since=5s'));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        final lines = res.body.trim().split('\n');
        for (final line in lines) {
          final Map<String, dynamic> wrapper = jsonDecode(line);
          final String id = wrapper['id'] ?? '';
          if (id.isNotEmpty && id != _lastEventId) {
            _lastEventId = id;
            final String? rawMsg = wrapper['message'];
            if (rawMsg != null && rawMsg.startsWith('{')) {
              final Map<String, dynamic> payload = jsonDecode(rawMsg);
              _applySyncedPayload(payload);
            }
          }
        }
      }
    } catch (_) {}
  }

  void _applySyncedPayload(Map<String, dynamic> payload) {
    final String type = payload['type'] ?? '';
    final String cardId = payload['cardId'] ?? 'northstar';

    setState(() {
      if (type == 'ADD_STAMP') {
        final int newCount = payload['stamps'] ?? 0;
        for (final c in walletCards) {
          if (c.id == cardId) {
            c.currentStamps = newCount.clamp(0, c.maxStamps);
          }
        }
      } else if (type == 'REDEEM_REWARD') {
        for (final c in walletCards) {
          if (c.id == cardId) {
            c.currentStamps = 0;
          }
        }
      } else if (type == 'NEW_CARD_ADDED') {
        uniqueCustomers = payload['uniqueCustomers'] ?? uniqueCustomers;
      }
    });
  }

  void _handleBusinessStampAdded(String customerName, String cardId, int newStampCount, int maxStamps) {
    setState(() {
      totalStampsGiven++;
      for (final c in walletCards) {
        if (c.id == cardId) {
          c.currentStamps = newStampCount.clamp(0, c.maxStamps);
        }
      }
      activityLogs.insert(
        0,
        ActivityLogItem(
          initials: _getInitials(customerName),
          customerName: customerName,
          actionText: '+1 stamp added ($newStampCount/$maxStamps)',
          timeLabel: 'Just now',
          bgColor: AppTheme.softGreenBg,
          textColor: AppTheme.primaryGreen,
        ),
      );
    });

    _sendRemoteEvent({
      'type': 'ADD_STAMP',
      'cardId': cardId,
      'stamps': newStampCount,
    });
  }

  void _handleBusinessRewardGranted(String customerName, String cardId) {
    setState(() {
      totalRewardsRedeemed++;
      for (final c in walletCards) {
        if (c.id == cardId) {
          c.currentStamps = 0;
        }
      }
      activityLogs.insert(
        0,
        ActivityLogItem(
          initials: _getInitials(customerName),
          customerName: customerName,
          actionText: 'Reward redeemed · Stamps reset to 0',
          timeLabel: 'Just now',
          bgColor: AppTheme.softGoldBg,
          textColor: AppTheme.accentGold,
        ),
      );
    });

    _sendRemoteEvent({
      'type': 'REDEEM_REWARD',
      'cardId': cardId,
    });
  }

  void _handleNewCardAddedByMember(StampCardModel newCard) {
    setState(() {
      walletCards.insert(0, newCard);
      uniqueCustomers++;
      activityLogs.insert(
        0,
        ActivityLogItem(
          initials: 'AM',
          customerName: 'Alex Morgan',
          actionText: 'Joined ${newCard.shopName} loyalty card',
          timeLabel: 'Just now',
          bgColor: AppTheme.softPurpleBg,
          textColor: AppTheme.accentPurple,
        ),
      );
    });

    _sendRemoteEvent({
      'type': 'NEW_CARD_ADDED',
      'uniqueCustomers': uniqueCustomers,
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'CU';
  }

  @override
  Widget build(BuildContext context) {
    final StampCardModel activePrimaryCard = walletCards.isNotEmpty
        ? walletCards.first
        : StampCardModel(
      id: 'northstar',
      shopName: 'Northstar Coffee',
      rewardTitle: 'FREE COFFEE',
      ruleText: 'Collect 10 · Get free coffee',
      currentStamps: 0,
      maxStamps: 10,
      columnsPerRow: 5,
      expiresDate: 'Expires 28 Jun 2026',
      icon: Icons.coffee_outlined,
      themeColor: AppTheme.accentCoral,
      cardTint: const Color(0xFFFFF8F5),
      iconBgColor: const Color(0xFFFCE6DF),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: AppTheme.backgroundCream,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppTheme.darkText,
                          ),
                          children: [
                            TextSpan(text: 'LOYAL'),
                            TextSpan(text: '.', style: TextStyle(color: AppTheme.accentCoral)),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => isBusinessMode = !isBusinessMode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.softGreenBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isBusinessMode ? 'BUSINESS' : 'MEMBER',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.swap_horiz, size: 14, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: isBusinessMode
                ? _buildBusinessBody()
                : _buildMemberBody(activePrimaryCard),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
              ),
              child: isBusinessMode ? _buildBusinessBottomNav() : _buildMemberBottomNav(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberBody(StampCardModel primaryCard) {
    switch (memberTabIndex) {
      case 0:
        return MemberWalletScreen(
          cards: walletCards,
          onCardsChanged: () => setState(() {}),
          onAddCard: _handleNewCardAddedByMember,
          onRewardCollectedLocally: (card) {
            _handleBusinessRewardGranted('Alex Morgan', card.id);
          },
        );
      case 1:
        return MemberScanScreen(activeCard: primaryCard);
      case 2:
      default:
        return const MemberProfileScreen();
    }
  }

  Widget _buildBusinessBody() {
    switch (businessTabIndex) {
      case 0:
        return BusinessAnalyticsScreen(
          totalStamps: totalStampsGiven,
          uniqueCustomers: uniqueCustomers,
          rewardsRedeemed: totalRewardsRedeemed,
          activeCardsCount: walletCards.length,
          activityLogs: activityLogs,
          onOpenScanner: () => setState(() => businessTabIndex = 1),
        );
      case 1:
      default:
        return BusinessScannerScreen(
          onStampAdded: _handleBusinessStampAdded,
          onRewardGranted: _handleBusinessRewardGranted,
        );
    }
  }

  // Smukły, niski pasek dolny bez podpisów pod ikonkami
  Widget _buildMemberBottomNav() {
    return NavigationBar(
      height: 52,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.softGreenBg,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: memberTabIndex,
      onDestinationSelected: (i) => setState(() => memberTabIndex = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
          selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen, size: 22),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner, size: 22),
          selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen, size: 22),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, size: 22),
          selectedIcon: Icon(Icons.person, color: AppTheme.primaryGreen, size: 22),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildBusinessBottomNav() {
    return NavigationBar(
      height: 52,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.softGreenBg,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: businessTabIndex,
      onDestinationSelected: (i) => setState(() => businessTabIndex = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined, size: 22),
          selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primaryGreen, size: 22),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner, size: 22),
          selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen, size: 22),
          label: 'Scanner',
        ),
      ],
    );
  }
}

// ============================================================================
// WIDOKI KLIENTA (MEMBER) - PRAWDZIWE KODY QR + SKANOWANIE NOWEJ KARTY
// ============================================================================

class MemberWalletScreen extends StatelessWidget {
  final List<StampCardModel> cards;
  final VoidCallback onCardsChanged;
  final ValueChanged<StampCardModel> onAddCard;
  final ValueChanged<StampCardModel> onRewardCollectedLocally;

  const MemberWalletScreen({
    super.key,
    required this.cards,
    required this.onCardsChanged,
    required this.onAddCard,
    required this.onRewardCollectedLocally,
  });

  void _showRewardModal(BuildContext context, StampCardModel card) {
    // Prawdziwy payload QR dla odbioru nagrody
    final String rewardQrPayload =
        'LOYAL|REWARD|Alex Morgan|${card.id}|${card.shopName}|${card.currentStamps}|${card.maxStamps}|847215';

    showDialog(
      context: context,
      barrierColor: const Color(0x99162820),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: AppTheme.darkText),
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: card.iconBgColor, shape: BoxShape.circle),
                child: Icon(card.icon, color: card.themeColor, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'REWARD UNLOCKED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your coffee is on us',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask the cashier to scan this code on the BUSINESS phone to redeem your reward.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: QrImageView(
                  data: rewardQrPayload,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'OR ENTER CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '847 215',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    onRewardCollectedLocally(card);
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "I've collected my reward",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteModal(BuildContext context, StampCardModel card) {
    showDialog(
      context: context,
      barrierColor: const Color(0x99162820),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: AppTheme.darkText),
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCE6DF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(card.icon, color: AppTheme.accentCoral, size: 28),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE6DF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 13,
                          color: AppTheme.accentCoral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Remove this card?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${card.shopName} card and its ${card.currentStamps} collected stamps will be permanently removed.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Keep card',
                        style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        cards.removeWhere((c) => c.id == card.id);
                        onCardsChanged();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Remove card',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Skanowanie kodu QR lokalu drugim telefonem w celu dodania karty do portfela
  void _showAddCardScannerModal(BuildContext context) {
    bool scanned = false;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add loyalty card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Text(
                'Scan a Shop QR code from the BUSINESS phone (Analytics -> Shop QR) or add a demo card below.',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: MobileScanner(
                    onDetect: (capture) {
                      if (scanned) return;
                      for (final barcode in capture.barcodes) {
                        final String? raw = barcode.rawValue;
                        if (raw != null && raw.isNotEmpty) {
                          scanned = true;
                          String shopName = 'Urban Barber';
                          String reward = 'FREE HAIRCUT';
                          int maxStamps = 5;
                          if (raw.startsWith('LOYAL|NEWCARD|')) {
                            final parts = raw.split('|');
                            if (parts.length >= 5) {
                              shopName = parts[2];
                              reward = parts[3];
                              maxStamps = int.tryParse(parts[4]) ?? 5;
                            }
                          }
                          onAddCard(
                            StampCardModel(
                              id: 'shop_${DateTime.now().millisecondsSinceEpoch}',
                              shopName: shopName,
                              rewardTitle: reward,
                              ruleText: 'Collect $maxStamps · Get ${reward.toLowerCase()}',
                              currentStamps: 1,
                              maxStamps: maxStamps,
                              columnsPerRow: maxStamps <= 5 ? 5 : 6,
                              expiresDate: 'Expires 30 Sep 2026',
                              icon: Icons.storefront_outlined,
                              themeColor: AppTheme.primaryGreen,
                              cardTint: const Color(0xFFF6FAF7),
                              iconBgColor: const Color(0xFFE3EFE8),
                            ),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dodano kartę: $shopName (+1 pieczątka na start)!')),
                          );
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    onAddCard(
                      StampCardModel(
                        id: 'barber_${DateTime.now().millisecondsSinceEpoch}',
                        shopName: 'Urban Barber',
                        rewardTitle: 'FREE HAIRCUT',
                        ruleText: 'Collect 5 · Get free haircut',
                        currentStamps: 1,
                        maxStamps: 5,
                        columnsPerRow: 5,
                        expiresDate: 'Expires 30 Sep 2026',
                        icon: Icons.content_cut,
                        themeColor: AppTheme.primaryGreen,
                        cardTint: const Color(0xFFF6FAF7),
                        iconBgColor: const Color(0xFFE3EFE8),
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Add Urban Barber card (without camera)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR COLLECTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Good morning, Alex',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'AM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My wallet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showAddCardScannerModal(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 5),
                    Text(
                      '+ Add card',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cards.map((card) => _buildTicketStampCard(context, card)),
      ],
    );
  }

  Widget _buildTicketStampCard(BuildContext context, StampCardModel card) {
    final bool isComplete = card.currentStamps >= card.maxStamps;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: card.cardTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: card.themeColor.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: card.iconBgColor, shape: BoxShape.circle),
                    child: Icon(card.icon, color: card.themeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.rewardTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteModal(context, card),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.mutedText, size: 20),
                  ),
                ],
              ),
            ),
            TicketDivider(
              cutoutColor: AppTheme.backgroundCream,
              lineColor: card.themeColor.withValues(alpha: 0.22),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STAMP CARD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        card.ruleText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLinePainter(color: card.themeColor.withValues(alpha: 0.18)),
                  ),
                  const SizedBox(height: 16),
                  _buildStampGrid(card),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
                          children: [
                            TextSpan(
                              text: '${card.currentStamps}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.darkText,
                              ),
                            ),
                            TextSpan(text: ' / ${card.maxStamps} stamps'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.expiresDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isComplete) ...[
              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DashedLinePainter(color: card.themeColor.withValues(alpha: 0.25)),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                color: card.iconBgColor.withValues(alpha: 0.45),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_open_outlined, size: 15, color: card.themeColor),
                        const SizedBox(width: 6),
                        Text(
                          'Card complete — collect to earn again',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: card.themeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCoral,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _showRewardModal(context, card),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Collect the reward',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStampGrid(StampCardModel card) {
    final int rows = (card.maxStamps / card.columnsPerRow).ceil();
    return Column(
      children: List.generate(rows, (r) {
        return Padding(
          padding: EdgeInsets.only(bottom: r < rows - 1 ? 10 : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(card.columnsPerRow, (c) {
              final int index = r * card.columnsPerRow + c;
              if (index >= card.maxStamps) {
                return const SizedBox(width: 44, height: 44);
              }
              final bool filled = index < card.currentStamps;
              final double circleSize = card.columnsPerRow == 6 ? 42 : 48;

              if (filled) {
                return Container(
                  width: circleSize,
                  height: circleSize,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: card.themeColor.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: card.themeColor.withValues(alpha: 0.75),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: Icon(card.icon, size: circleSize * 0.42, color: card.themeColor),
                    ),
                  ),
                );
              } else {
                return CustomPaint(
                  painter: _DashedCirclePainter(color: AppTheme.mutedText.withValues(alpha: 0.35)),
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedText.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
        );
      }),
    );
  }
}

class MemberScanScreen extends StatefulWidget {
  final StampCardModel activeCard;

  const MemberScanScreen({super.key, required this.activeCard});

  @override
  State<MemberScanScreen> createState() => _MemberScanScreenState();
}

class _MemberScanScreenState extends State<MemberScanScreen> {
  int secondsRemaining = 30;
  List<int> digits = [4, 8, 3, 9, 2, 1];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (secondsRemaining > 1) {
          secondsRemaining--;
        } else {
          secondsRemaining = 30;
          final rnd = Random();
          digits = List.generate(6, (_) => rnd.nextInt(10));
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String codeStr = digits.join();
    final StampCardModel card = widget.activeCard;
    // Prawdziwy, pełny ładunek danych w kodzie QR odczytywany przez drugi telefon
    final String qrPayload =
        'LOYAL|STAMP|Alex Morgan|${card.id}|${card.shopName}|${card.currentStamps}|${card.maxStamps}|$codeStr';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      children: [
        const Center(
          child: Text(
            'SECURE VERIFICATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Scan to collect',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.darkText,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Show this code at the checkout to earn your\nstamp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.mutedText),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.softGreenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF2E9B68)),
                        SizedBox(width: 6),
                        Text(
                          'LIVE QR CODE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${card.shopName} (${card.currentStamps}/${card.maxStamps})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'OR ENTER THIS CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: digits
                    .map(
                      (d) => Container(
                    width: 42,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Refreshes in ${secondsRemaining}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.softGreenBg.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protected and private',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your code refreshes automatically every 30s for extra security.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'YOUR ACCOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Profile settings',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.accentGold,
                child: Text(
                  'AM',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText),
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alex Morgan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Member since March 2024',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.softGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email address',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        'Where we send account updates',
                        style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: 'alex.morgan@example.com',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundCream,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email updated!')),
                    );
                  },
                  child: const Text(
                    'Update email',
                    style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDOKI FIRMY (BUSINESS) - UPROSZCZONE STATYSTYKI GRID 1.0 + KAMERA QR
// ============================================================================

class BusinessAnalyticsScreen extends StatelessWidget {
  final int totalStamps;
  final int uniqueCustomers;
  final int rewardsRedeemed;
  final int activeCardsCount;
  final List<ActivityLogItem> activityLogs;
  final VoidCallback onOpenScanner;

  const BusinessAnalyticsScreen({
    super.key,
    required this.totalStamps,
    required this.uniqueCustomers,
    required this.rewardsRedeemed,
    required this.activeCardsCount,
    required this.activityLogs,
    required this.onOpenScanner,
  });

  void _showShopCardQrModal(BuildContext context) {
    const String shopQrData = 'LOYAL|NEWCARD|Northstar Roastery|FREE ESPRESSO|6';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NEW CARD QR CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Northstar Roastery',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan this QR code on the MEMBER phone (Wallet -> + Add card) to issue a new loyalty card.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: shopQrData,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'BUSINESS OVERVIEW · V1.0',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Good morning, Maya',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Live statistics updated directly from QR scans.',
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showShopCardQrModal(context),
                icon: const Icon(Icons.qr_code, size: 18, color: AppTheme.primaryGreen),
                label: const Text(
                  'Shop QR',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkText),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onOpenScanner,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan customer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // UPROSZCZONY GRID STATYSTYK (2x2) ZGODNY Z DOKUMENTACJĄ V1.0
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: [
            _buildGridStatCard(
              icon: Icons.approval_outlined,
              iconBg: AppTheme.softGreenBg,
              iconColor: AppTheme.primaryGreen,
              label: 'Stamps given',
              value: '$totalStamps',
            ),
            _buildGridStatCard(
              icon: Icons.people_outline,
              iconBg: AppTheme.softCoralBg,
              iconColor: AppTheme.accentCoral,
              label: 'Unique customers',
              value: '$uniqueCustomers',
            ),
            _buildGridStatCard(
              icon: Icons.card_giftcard,
              iconBg: AppTheme.softGoldBg,
              iconColor: AppTheme.accentGold,
              label: 'Rewards redeemed',
              value: '$rewardsRedeemed',
            ),
            _buildGridStatCard(
              icon: Icons.credit_card,
              iconBg: AppTheme.softPurpleBg,
              iconColor: AppTheme.accentPurple,
              label: 'Active cards',
              value: '$activeCardsCount',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // REALNY LOG AKTYWNOŚCI ZESKANOWANYCH KODÓW QR
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent scan activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              const Text(
                'Real-time updates when you scan a customer QR',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 14),
              ...activityLogs.take(6).map(
                    (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: log.bgColor,
                        child: Text(
                          log.initials,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: log.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.customerName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                            Text(
                              log.actionText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        log.timeLabel,
                        style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BusinessScannerScreen extends StatefulWidget {
  final void Function(String customerName, String cardId, int newStampCount, int maxStamps)
  onStampAdded;
  final void Function(String customerName, String cardId) onRewardGranted;

  const BusinessScannerScreen({
    super.key,
    required this.onStampAdded,
    required this.onRewardGranted,
  });

  @override
  State<BusinessScannerScreen> createState() => _BusinessScannerScreenState();
}

class _BusinessScannerScreenState extends State<BusinessScannerScreen> {
  bool customerScanned = false;
  String scannedCustomerName = 'Alex Morgan';
  String scannedCardId = 'northstar';
  String scannedShopName = 'Northstar Coffee';
  String scannedCodeToken = '483921';
  int customerStamps = 8;
  int customerMaxStamps = 10;
  String? statusBannerTitle;
  String? statusBannerSubtitle;

  void _processRawQrString(String raw) {
    if (customerScanned) return;

    // Obsługa naszego protokołu: LOYAL|STAMP/REWARD|Name|cardId|shopName|stamps|maxStamps|token
    if (raw.startsWith('LOYAL|')) {
      final parts = raw.split('|');
      if (parts.length >= 8) {
        setState(() {
          customerScanned = true;
          scannedCustomerName = parts[2];
          scannedCardId = parts[3];
          scannedShopName = parts[4];
          customerStamps = int.tryParse(parts[5]) ?? 8;
          customerMaxStamps = int.tryParse(parts[6]) ?? 10;
          scannedCodeToken = parts[7];
          statusBannerTitle = 'QR Code verified (#$scannedCodeToken)';
          statusBannerSubtitle = 'Card: $scannedShopName';
        });
        return;
      }
    }

    // Obsługa dowolnego innego kodu QR
    setState(() {
      customerScanned = true;
      scannedCustomerName = 'Alex Morgan';
      scannedCardId = 'northstar';
      scannedShopName = 'Northstar Coffee';
      scannedCodeToken = raw.length > 8 ? raw.substring(0, 8) : raw;
      statusBannerTitle = 'QR captured ($scannedCodeToken)';
      statusBannerSubtitle = 'Ready to add stamp or apply discount.';
    });
  }

  void _showManualCodeDialog() {
    final TextEditingController codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter 6-digit code'),
        content: TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'e.g. 483921'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim().isEmpty ? '483921' : codeCtrl.text.trim();
              Navigator.pop(ctx);
              _processRawQrString('LOYAL|STAMP|Alex Morgan|northstar|Northstar Coffee|8|10|$code');
            },
            child: const Text('Verify code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCollectionComplete = customerStamps >= customerMaxStamps;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'CUSTOMER CHECKOUT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Scan customer QR code',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Point the camera at the second phone's QR code.",
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 16),

        // WIZJER PRAWDZIWEJ KAMERY (MobileScanner) Z CELOWNIKIEM
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF102119),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!customerScanned)
                  MobileScanner(
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        final String? raw = barcode.rawValue;
                        if (raw != null && raw.isNotEmpty) {
                          _processRawQrString(raw);
                          break;
                        }
                      }
                    },
                  ),
                Container(
                  color: Colors.black.withValues(alpha: customerScanned ? 0.65 : 0.25),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Color(0xFF4ADE80)),
                                const SizedBox(width: 6),
                                Text(
                                  customerScanned ? 'QR Locked' : 'Live Camera Active',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.45),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: _showManualCodeDialog,
                            icon: const Icon(Icons.dialpad, size: 14),
                            label: const Text('Enter 6-digit code', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      height: 150,
                      child: CustomPaint(
                        painter: _ScannerReticlePainter(
                          cornerColor: customerScanned ? const Color(0xFF6EE7B7) : Colors.white,
                          showLaser: !customerScanned,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Text(
                        customerScanned
                            ? 'Code #$scannedCodeToken captured from $scannedCustomerName'
                            : 'Hold steady over the customer QR code — scans automatically',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (!customerScanned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                const Text(
                  'Waiting for a QR scan...',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan the QR code from the second phone or click below to test without a camera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    _processRawQrString(
                      'LOYAL|STAMP|Alex Morgan|northstar|Northstar Coffee|8|10|483921',
                    );
                  },
                  child: const Text(
                    'Simulate scan',
                    style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.softCoralBg,
                      child: Text(
                        scannedCustomerName.substring(0, 2).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.accentCoral,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CUSTOMER VERIFIED VIA QR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scannedCustomerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            '$scannedShopName · Token #$scannedCodeToken',
                            style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.softGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 12, color: AppTheme.primaryGreen),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current progress',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                    ),
                    Text(
                      '$customerStamps of $customerMaxStamps stamps',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(customerMaxStamps, (index) {
                    final bool active = index < customerStamps;
                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.accentCoral : AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                if (statusBannerTitle != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.softGreenBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusBannerTitle!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                statusBannerSubtitle ?? '',
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isCollectionComplete ? const Color(0xFF9CAFA6) : AppTheme.primaryGreen,
                      disabledBackgroundColor: const Color(0xFF9CAFA6),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isCollectionComplete
                        ? null
                        : () {
                      setState(() {
                        customerStamps++;
                        statusBannerTitle = 'Stamp added (+1)';
                        statusBannerSubtitle =
                        'Analytics updated & synced with customer phone.';
                      });
                      widget.onStampAdded(
                        scannedCustomerName,
                        scannedCardId,
                        customerStamps,
                        customerMaxStamps,
                      );
                    },
                    icon: Icon(isCollectionComplete ? Icons.check : Icons.add, size: 18),
                    label: Text(
                      isCollectionComplete ? 'Collection complete' : 'Add Stamp',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isCollectionComplete
                        ? () {
                      setState(() {
                        customerStamps = 0;
                        statusBannerTitle = 'Reward granted & stamps reset';
                        statusBannerSubtitle =
                        'Rewards counter incremented in Business Analytics.';
                      });
                      widget.onRewardGranted(scannedCustomerName, scannedCardId);
                    }
                        : null,
                    icon: const Icon(Icons.local_offer_outlined, size: 16),
                    label: const Text(
                      'Apply Discount (Redeem Reward)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        customerScanned = false;
                        statusBannerTitle = null;
                      });
                    },
                    child: const Text(
                      'Scan another customer',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}