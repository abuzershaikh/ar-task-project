import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _campaignAlerts = true;
  bool _taskProofs = true;
  bool _walletAlerts = true;
  bool _promoTips = false;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Preferences & Settings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Notification Preferences ──
          _buildSectionHeader('PUSH NOTIFICATIONS'),
          const SizedBox(height: 10),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Campaign Live Alerts',
              subtitle: 'Notify when your order starts receiving worker actions',
              icon: Icons.campaign_rounded,
              value: _campaignAlerts,
              onChanged: (v) => setState(() => _campaignAlerts = v),
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: 'Worker Proof Submissions',
              subtitle: 'Instant alerts when workers submit screenshots for review',
              icon: Icons.camera_alt_rounded,
              value: _taskProofs,
              onChanged: (v) => setState(() => _taskProofs = v),
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: 'Wallet & Balance Alerts',
              subtitle: 'Alerts for deposits, escrow holds, and low campaign balance',
              icon: Icons.account_balance_wallet_rounded,
              value: _walletAlerts,
              onChanged: (v) => setState(() => _walletAlerts = v),
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: 'Viral Strategy & Tips',
              subtitle: 'Weekly insights on YouTube & Instagram recommendation algorithms',
              icon: Icons.lightbulb_rounded,
              value: _promoTips,
              onChanged: (v) => setState(() => _promoTips = v),
            ),
          ]),
          const SizedBox(height: 24),

          // ── System & Interface ──
          _buildSectionHeader('INTERFACE & PERFORMANCE'),
          const SizedBox(height: 10),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Haptic Feedback',
              subtitle: 'Subtle vibration when launching campaigns and approving tasks',
              icon: Icons.vibration_rounded,
              value: _haptics,
              onChanged: (v) => setState(() => _haptics = v),
            ),
            _buildDivider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              title: Text(
                'Default Currency',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'INR (₹ Indian Rupee)',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹ INR', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildDivider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dark_mode_rounded, color: Color(0xFFA855F7), size: 18),
              ),
              title: Text(
                'App Theme',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Cyber Obsidian (OLED Optimized)',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
              ),
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
            ),
          ]),
          const SizedBox(height: 24),

          // ── App Information & Legal ──
          _buildSectionHeader('APPLICATION INFO'),
          const SizedBox(height: 10),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF34D399), size: 18),
              ),
              title: Text(
                'Client Version',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              trailing: Text(
                'v1.2.0 (Build 24)',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            _buildDivider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF94A3B8), size: 18),
              ),
              title: Text(
                'Data Protection & Privacy',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All campaign data and worker logs are 256-bit SSL encrypted.')),
                );
              },
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF38BDF8),
      activeTrackColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
      inactiveThumbColor: const Color(0xFF94A3B8),
      inactiveTrackColor: const Color(0xFF1E293B),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 16,
      endIndent: 16,
    );
  }
}
