import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap/core/theme/app_colors.dart';
import 'package:sigap/core/widgets/sigap_logo.dart';
import 'package:sigap/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:sigap/features/family/presentation/screens/family_assistance_screen.dart';
import 'package:sigap/features/map/presentation/screens/risk_map_screen.dart';
import 'package:sigap/core/services/bmkg_service.dart';
import 'package:sigap/features/settings/presentation/screens/settings_screen.dart';
import 'package:sigap/features/profile/presentation/screens/profile_screen.dart';

/// Screen Dashboard SIGAP Kota Padang
/// Mengimplementasikan secara presisi desain:
/// "SIGAP mobile — Dashboard — iPhone 17 Pro.svg"
///
/// Komponen & Fitur:
/// - Header: Logo SIGAP, Waktu Padang (PDG 09:41), Pengaturan & Akun
/// - Judul: "Dashboard" + "Ringkasan kondisi terkini · Padang, Sumatera Barat"
/// - Kartu Peringatan Aktif: "Gempa bumi M5.8" + Tombol "LIHAT PERINGATAN"
/// - 4 Kartu Tindakan Cepat (Grid 2x2): "SAYA AMAN", "BUTUH BANTUAN", "PETA RISIKO", "HUBUNGI DARURAT"
/// - Kartu Risiko Lokasi Anda: "Potensi banjir" (Status: SEDANG)
/// - Kartu Keluarga & Bantuan: Daftar anggota (Ibu AMAN, Ayah BELUM TERHUBUNG, Adik PERLU KONFIRMASI)
/// - Kartu Pembaruan Terakhir (Timeline log kejadian terkini)
/// - Bottom Navigation Bar (4 tab kustom sesuai mockup: Dashboard, Peringatan, Peta risiko, Keluarga & Bantuan)
class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({
    super.key,
    this.userName = 'Warga Padang',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Dashboard, 1: Peringatan, 2: Peta risiko, 3: Keluarga

  // Status Keamanan Pengguna
  bool _isSafe = true;
  String _userSafetyTime = 'baru saja';
  String _userLocationNote = 'rumah';
  bool _shareLocation = true;

  // Animasi Pulsing untuk Live Alert Status
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State Checklist "Tas Siaga Bencana (72 Jam)"
  final List<Map<String, dynamic>> _survivalKit = [
    {'title': 'Dokumen Penting (KTP/KK)', 'checked': true},
    {'title': 'Air Bersih & Makanan Darurat', 'checked': true},
    {'title': 'Kotak P3K & Obat Khusus', 'checked': true},
    {'title': 'Senter & Peluit Darurat', 'checked': false},
    {'title': 'Powerbank & Baterai Cadangan', 'checked': false},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadBmkgData();
  }

  // Real-Time BMKG State
  BmkgGempa? _bmkgGempa;

  Future<void> _loadBmkgData() async {
    final data = await BmkgService.fetchLatestGempa();
    if (mounted) {
      setState(() {
        _bmkgGempa = data;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ==========================================
  // MODAL / DIALOG HANDLERS
  // ==========================================

  void _showSayaAmanDialog() {
    final noteController = TextEditingController(text: _userLocationNote);
    bool shareLoc = _shareLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primaryDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Status: SAYA AMAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Keluarga terdekat akan segera melihat status ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Keterangan Kondisi / Lokasi (Opsional)',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
                  hintText: 'Misal: di rumah bersama keluarga, kondisi aman',
                  filled: true,
                  fillColor: AppColors.backgroundCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // BRD FR-24: Berbagi lokasi hanya bila dicentang secara sadar
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: shareLoc,
                activeColor: AppColors.primaryDark,
                title: Text(
                  'Sertakan titik lokasi perkiraan (Padang Barat)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                ),
                onChanged: (val) {
                  setModalState(() {
                    shareLoc = val ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSafe = true;
                    _userSafetyTime = 'baru saja';
                    _userLocationNote = noteController.text.trim().isEmpty ? 'rumah' : noteController.text.trim();
                    _shareLocation = shareLoc;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Status "Saya Aman" berhasil diperbarui dan dibagikan!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.safeGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Kirim Status Aman',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showButuhBantuanDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.alertPeach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_rounded, color: AppColors.alertRust, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemberitahuan: BUTUH BANTUAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Pilih kondisi darurat Anda saat ini di Kota Padang',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEmergencyOption(
              icon: Icons.personal_injury_rounded,
              title: 'Butuh Bantuan Medis / Evakuasi',
              subtitle: 'Kondisi luka atau terjebak reruntuhan/banjir',
            ),
            const SizedBox(height: 10),
            _buildEmergencyOption(
              icon: Icons.family_restroom_rounded,
              title: 'Anggota Keluarga Hilang / Terpisah',
              subtitle: 'Terputus kontak saat evakuasi bencana',
            ),
            const SizedBox(height: 10),
            _buildEmergencyOption(
              icon: Icons.fastfood_rounded,
              title: 'Butuh Logistik / Air Bersih',
              subtitle: 'Posko atau rumah isolasi kekurangan logistik',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSafe = false;
                  _userSafetyTime = 'baru saja';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Status darurat "BUTUH BANTUAN" telah dikirimkan ke keluarga dan relawan!'),
                    backgroundColor: AppColors.alertRust,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertRust,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Kirim Sinyal Bantuan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.alertRust, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSlate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHubungiDaruratSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Layanan Darurat Kota Padang',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Panggilan langsung tanpa perantara ke pihak berwenang',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSlate),
            ),
            const SizedBox(height: 18),
            _buildContactRow(name: 'Call Center Darurat Padang', number: '112', tag: 'Bebas Pulsa / 24 Jam', isPrimary: true),
            const SizedBox(height: 10),
            _buildContactRow(name: 'BPBD Kota Padang', number: '(0751) 778775', tag: 'Pusdalops Bencana'),
            const SizedBox(height: 10),
            _buildContactRow(name: 'Basarnas Pos SAR Padang', number: '(0751) 484344', tag: 'Pencarian & Penyelamatan'),
            const SizedBox(height: 10),
            _buildContactRow(name: 'PMI Kota Padang', number: '(0751) 23812', tag: 'Ambulans & Medis'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required String name,
    required String number,
    required String tag,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.mintAccent : AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? AppColors.primary : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_in_talk_rounded, color: isPrimary ? AppColors.primaryDark : AppColors.textDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
                Text('$number · $tag', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSlate)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.safeGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungkan panggilan ke $number ($name)...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailPeringatanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.alertPeach,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.alertBorderPeach),
              ),
              child: Text(
                'PERINGATAN RESMI BMKG',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.alertRust,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gempa bumi M5.8',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Waktu Kejadian: Hari ini, 08:42 WIB\nPusat Gempa: 24 km Barat Daya Kota Padang\nKedalaman: 10 km (Gempa Dangkal)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSlate, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Instruksi Keselamatan Bagi Warga Padang:',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Jauhi gedung bertingkat dan bangunan dengan keretakan struktur.\n2. Bersiap di area terbuka atau titik kumpul terdekat (GOR H. Agus Salim, Lapangan Imam Bonjol).\n3. Waspadai gempa susulan (*aftershocks*).\n4. Tidak berpotensi tsunami di pesisir Kota Padang.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToAlerts();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Buka Peringatan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAlerts() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => AlertsScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToFamilyAssistance() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => FamilyAssistanceScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToRiskMap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => RiskMapScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => SettingsScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => ProfileScreen(
          onNavigateToDashboard: () {
            Navigator.of(context).pop();
          },
          onNavigateToAlerts: () {
            Navigator.of(context).pop();
            _navigateToAlerts();
          },
          onNavigateToMap: () {
            Navigator.of(context).pop();
            _navigateToRiskMap();
          },
          onNavigateToFamily: () {
            Navigator.of(context).pop();
            _navigateToFamilyAssistance();
          },
          onNavigateToSettings: () {
            Navigator.of(context).pop();
            _navigateToSettings();
          },
        ),
        transitionsBuilder: (context, a1, a2, child) => FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showSirineDialog() {
    bool isSounding = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isSounding
                          ? AppColors.alertAwas.withValues(alpha: _pulseAnimation.value * 0.25)
                          : AppColors.mintAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSounding ? AppColors.alertAwas : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSounding ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                isSounding ? 'SIRINE DARURAT AKTIF' : 'Sirine Dijeda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isSounding ? AppColors.alertAwas : AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Frekuensi audio sinyal tinggi (110 dB) untuk memudahkan tim SAR dan relawan evakuasi mendeteksi posisi Anda saat terjebak atau terisolir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSlate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setSheetState(() {
                          isSounding = !isSounding;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isSounding ? AppColors.alertRust : AppColors.primary,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isSounding ? 'Jeda Bunyi' : 'Lanjutkan Sirine',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: isSounding ? AppColors.alertRust : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Matikan & Tutup',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showShelterEvakuasiModal() {
    final shelters = [
      {
        'name': 'TES Gedung Escape Ulak Karang',
        'dist': '420 meter',
        'time': '5 mnt',
        'capacity': '3.000 jiwa',
        'elevation': '16 mdpl',
        'route': 'Lewat Jl. Bahari menuju utara',
        'isNear': true,
      },
      {
        'name': 'Masjid Raya Sumatera Barat',
        'dist': '1.2 km',
        'time': '15 mnt',
        'capacity': '10.000 jiwa',
        'elevation': 'Zona Hijau Aman',
        'route': 'Jl. Khatib Sulaiman',
        'isNear': false,
      },
      {
        'name': 'Gedung SMPN 1 Padang (Vertical Evac)',
        'dist': '650 meter',
        'time': '8 mnt',
        'capacity': '1.500 jiwa',
        'elevation': 'Lantai 3 & 4',
        'route': 'Jl. Jend. Sudirman',
        'isNear': false,
      },
      {
        'name': 'Hotel Ibis Padang (Shelter Vertikal)',
        'dist': '950 meter',
        'time': '11 mnt',
        'capacity': '2.000 jiwa',
        'elevation': 'Lantai 5 ke atas',
        'route': 'Jl. Taman Siswa',
        'isNear': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_run_rounded, color: AppColors.primaryDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titik Evakuasi Sementara (TES)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Peta Shelter Aman Tsunami Kota Padang',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertPeach,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.alertBorderPeach),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.alertRust, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PENTING: Jangan gunakan mobil atau motor saat evakuasi tsunami untuk mencegah kemacetan total!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertRust,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...shelters.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: s['isNear'] == true ? AppColors.mintSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: s['isNear'] == true ? AppColors.primaryLight : AppColors.borderLight,
                    width: s['isNear'] == true ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (s['isNear'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TERDEKAT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded, size: 15, color: AppColors.textSlate),
                        const SizedBox(width: 4),
                        Text('${s['dist']} (${s['time']})', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(width: 12),
                        const Icon(Icons.people_outline_rounded, size: 15, color: AppColors.textSlate),
                        const SizedBox(width: 4),
                        Text('${s['capacity']}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSlate)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rute: ${s['route']} · Elevasi: ${s['elevation']}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSlate),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeOfflineDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.offline_pin_rounded, color: AppColors.safeGreen, size: 26),
            const SizedBox(width: 10),
            Text(
              'Mode Offline Aktif',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark),
            ),
          ],
        ),
        content: Text(
          'Seluruh peta zona evakuasi tsunami Padang, nomor darurat 112, serta data kontak keluarga telah tersimpan di memori lokal ponsel Anda. Aplikasi tetap berfungsi penuh meskipun sinyal internet padam akibat bencana.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSlate, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Dimengerti',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showFamilyMemberDetail({
    required String name,
    required String status,
    required Color statusColor,
    required String location,
    required String lastUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.mintAccent,
                  child: const Icon(Icons.person_rounded, size: 26, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                          Text(' · $lastUpdate', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSlate)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi Terakhir: $location',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Menghubungi telepon $name...'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Telepon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToFamilyAssistance();
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Buka Profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. TOP HEADER (LOGO RESMI SIGAP · SETTINGS & PROFILE)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    // Brand Logo Resmi SIGAP
                    const SigapLogo(
                      size: 30,
                      showText: true,
                      textColor: AppColors.textDark,
                      hasGlow: true,
                    ),
                    const Spacer(),
                    // Settings Icon Button
                    InkWell(
                      onTap: _navigateToSettings,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          size: 19,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Profile Icon Button
                    InkWell(
                      onTap: _navigateToProfile,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 19,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. GREETING & RINGKASAN STATUS
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${widget.userName} 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kesiapsiagaan: Waspada Gempa Susulan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSlate,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Live Status Badge SIAGA dengan Animasi Pendar Halus
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.alertPeach,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.alertTerracotta.withValues(alpha: _pulseAnimation.value),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.alertTerracotta.withValues(alpha: _pulseAnimation.value * 0.25),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.alertAwas,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SIAGA · 09:41',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.alertRust,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Skor Kesiapsiagaan Personal Warga Padang (Gamifikasi)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF3F9F5),
                        Color(0xFFE8F3EC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: (50 + (_survivalKit.where((k) => k['checked'] == true).length * 10)) / 100,
                              backgroundColor: AppColors.borderLight,
                              color: AppColors.primary,
                              strokeWidth: 3.5,
                            ),
                          ),
                          Text(
                            '${50 + (_survivalKit.where((k) => k['checked'] == true).length * 10)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level Kesiapsiagaan: Siaga Tangguh',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              '${_survivalKit.where((k) => k['checked'] == true).length} dari 5 perlengkapan tas siaga siap bawa',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 3. KARTU PERINGATAN AKTIF (WARM GRADIENT & SHADOW)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF6F0),
                        Color(0xFFFFECE0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.alertBorderPeach, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.alertTerracotta.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final quake = _bmkgGempa ?? BmkgGempa.fallbackPadang;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.alertTerracotta,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🚨 BMKG · GEMPA M5.8',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      quake.jam,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSlate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _showDetailPeringatanDialog,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.alertTerracotta, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Detail',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.alertRust,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.alertRust),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.alertBorderPeach),
                            ),
                            child: const Icon(Icons.crisis_alert_rounded, color: AppColors.alertRust, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gempa bumi M${_bmkgGempa?.magnitude ?? '5.8'} (Dangkal)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_bmkgGempa?.wilayah ?? '24 km barat daya Padang'} · Kedalaman ${_bmkgGempa?.kedalaman ?? '10 km'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Potensi Tsunami: ${_bmkgGempa?.potensi ?? 'Tidak berpotensi'}. Waspada bangunan retak.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.alertRust,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 4. TINDAKAN CEPAT (TACTILE 2x2 GRID + TOOLS BAR)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'TINDAKAN CEPAT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSlate,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSafe)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  'Status: AMAN ($_userSafetyTime)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            title: 'SAYA AMAN',
                            subtitle: 'Kabari keluarga',
                            icon: Icons.shield_rounded,
                            isPrimary: true,
                            onTap: _showSayaAmanDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            title: 'BUTUH BANTUAN',
                            subtitle: 'Kirim sinyal SOS',
                            icon: Icons.waving_hand_rounded,
                            isAlert: true,
                            onTap: _showButuhBantuanDialog,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            title: 'PETA RISIKO',
                            subtitle: 'Jalur evakuasi',
                            icon: Icons.map_rounded,
                            onTap: _navigateToRiskMap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            title: 'DARURAT 112',
                            subtitle: 'BPBD & SAR Padang',
                            icon: Icons.phone_in_talk_rounded,
                            onTap: _showHubungiDaruratSheet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quick Survival Tools Strip
                    Row(
                      children: [
                        // Offline Mode Indicator
                        Expanded(
                          child: InkWell(
                            onTap: _showModeOfflineDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.safeGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Siaga Offline: Siap',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textSlate),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Siren Quick Trigger
                        Expanded(
                          child: InkWell(
                            onTap: _showSirineDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.alertPeach,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.alertBorderPeach),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.volume_up_rounded, size: 14, color: AppColors.alertRust),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Sirine / Peluit',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.alertRust,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.alertRust),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 5. SHELTER EVAKUASI TERDEKAT (TSUNAMI HERO WIDGET)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.mintSurface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ZONA AMAN TSUNAMI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Elevasi: 16 mdpl',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.safeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _showShelterEvakuasiModal,
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Semua Shelter',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.directions_run_rounded, color: AppColors.primaryDark, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TES Gedung Escape Ulak Karang',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '420 meter · ±5 menit jalan kaki · Kapasitas 3.000 jiwa',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showShelterEvakuasiModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Pandu',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 6. STATUS LINGKUNGAN (DUAL COLUMN: RISIKO & CUACA)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    // Risiko Lokasi
                    Expanded(
                      child: InkWell(
                        onTap: _navigateToRiskMap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.water_damage_rounded, size: 20, color: AppColors.primary),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SEDANG',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Potensi Banjir Rob',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Padang Barat · Pesisir',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cuaca Terkini BMKG
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.cloud_queue_rounded, size: 20, color: AppColors.primaryDark),
                                Text(
                                  '29°C',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hujan Ringan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Angin 14 km/j · BMKG',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 6.5. KONDISI PANTAI PADANG (TAPLAU MARITIM BMKG)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF0F9FF),
                        Color(0xFFE0F2FE),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.oceanCyan.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.oceanWaveGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.waves_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Taplau (Pantai Padang)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BMKG MARITIM',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gelombang 0.8 - 1.2 m (Tenang) · Pasang 17:45 WIB · UV Sedang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 7. INTERACTIVE CHECKLIST "TAS SIAGA BENCANA (72 JAM)"
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.backpack_outlined, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tas Siaga Bencana (72 Jam)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final readyCount = _survivalKit.where((k) => k['checked'] == true).length;
                              final pct = ((readyCount / _survivalKit.length) * 100).toInt();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: readyCount == _survivalKit.length ? AppColors.safeGreen.withValues(alpha: 0.15) : AppColors.mintAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$pct% ($readyCount/${_survivalKit.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: readyCount == _survivalKit.length ? AppColors.safeGreen : AppColors.primaryDark,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      Builder(
                        builder: (context) {
                          final readyCount = _survivalKit.where((k) => k['checked'] == true).length;
                          final progress = readyCount / _survivalKit.length;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation(
                                readyCount == _survivalKit.length ? AppColors.safeGreen : AppColors.primary,
                              ),
                              minHeight: 5,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // Interactive Checklist Items
                      ..._survivalKit.map((item) {
                        final bool checked = item['checked'] as bool;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              item['checked'] = !checked;
                            });
                            final readyCount = _survivalKit.where((k) => k['checked'] == true).length;
                            if (readyCount == _survivalKit.length) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hebat! Tas Siaga Bencana 72 Jam Anda sudah 100% lengkap! 🎉'),
                                  backgroundColor: AppColors.safeGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 19,
                                  color: checked ? AppColors.primary : AppColors.textSlate,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                                      color: checked ? AppColors.textDark : AppColors.textSlate,
                                      decoration: checked ? TextDecoration.lineThrough : null,
                                      decorationColor: AppColors.textSlate,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 8. KELUARGA TERPANTAU (INTERACTIVE AVATAR CHIPS)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Pantauan Keluarga',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _navigateToFamilyAssistance,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kelola',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyAvatarChip(
                              name: 'Anda',
                              status: _isSafe ? 'Aman' : 'SOS',
                              statusColor: _isSafe ? AppColors.safeGreen : AppColors.alertAwas,
                              icon: Icons.person_rounded,
                              onTap: _showSayaAmanDialog,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyAvatarChip(
                              name: 'Ibu',
                              status: 'Aman',
                              statusColor: AppColors.safeGreen,
                              icon: Icons.face_rounded,
                              onTap: () => _showFamilyMemberDetail(
                                name: 'Ibu',
                                status: 'Aman',
                                statusColor: AppColors.safeGreen,
                                location: 'Rumah (Kec. Padang Barat)',
                                lastUpdate: '2 menit lalu',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyAvatarChip(
                              name: 'Ayah',
                              status: 'Terputus',
                              statusColor: AppColors.alertWaspada,
                              icon: Icons.face_6_rounded,
                              onTap: () => _showFamilyMemberDetail(
                                name: 'Ayah',
                                status: 'Belum Terhubung',
                                statusColor: AppColors.alertWaspada,
                                location: 'Kantor / Jalan (Belum konfirmasi)',
                                lastUpdate: '15 menit lalu',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyAvatarChip(
                              name: 'Adik',
                              status: 'Cek',
                              statusColor: AppColors.alertSiaga,
                              icon: Icons.face_3_rounded,
                              onTap: () => _showFamilyMemberDetail(
                                name: 'Adik',
                                status: 'Perlu Konfirmasi',
                                statusColor: AppColors.alertSiaga,
                                location: 'Sekolah (Kec. Padang Utara)',
                                lastUpdate: '40 menit lalu',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 9. PEMBARUAN TERKINI (COMPACT TICKER)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'PEMBARUAN TERKINI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSlate,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '● Live Feed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.safeGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCompactLogItem(time: '09:38', text: 'Ibu menandai status Aman di rumah.'),
                      const Divider(height: 14, color: AppColors.borderLight),
                      _buildCompactLogItem(time: '08:42', text: 'Peringatan gempa M5.8 diterbitkan BMKG.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ==========================================
      // 8. BOTTOM NAVIGATION BAR (FLOATING ISLAND)
      // ==========================================
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavPill(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              _buildNavPill(
                index: 1,
                icon: Icons.notifications_active_rounded,
                label: 'Peringatan',
              ),
              _buildNavPill(
                index: 2,
                icon: Icons.map_rounded,
                label: 'Peta risiko',
              ),
              _buildNavPill(
                index: 3,
                icon: Icons.group_rounded,
                label: 'Keluarga & Bantuan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isAlert = false,
  }) {
    Color bgColor = Colors.white;
    Color textColor = AppColors.textDark;
    Color subColor = AppColors.textSlate;
    Color iconColor = AppColors.primary;
    Border? border = Border.all(color: AppColors.borderLight);

    if (isPrimary) {
      bgColor = AppColors.primaryDark;
      textColor = Colors.white;
      subColor = AppColors.textMint;
      iconColor = AppColors.mintAccent;
      border = null;
    } else if (isAlert) {
      bgColor = Colors.white;
      textColor = AppColors.alertRust;
      iconColor = AppColors.alertRust;
      border = Border.all(color: AppColors.alertBorderPeach, width: 1.2);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.15)
                    : (isAlert ? AppColors.alertPeach : AppColors.mintSurface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyAvatarChip({
    required String name,
    required String status,
    required Color statusColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.mintSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.mintAccent,
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLogItem({
    required String time,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.mintAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildNavPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) {
            _navigateToAlerts();
          } else if (index == 2) {
            _navigateToRiskMap();
          } else if (index == 3) {
            _navigateToFamilyAssistance();
          } else {
            setState(() {
              _activeTab = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isActive ? Colors.white : AppColors.textSlate,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
