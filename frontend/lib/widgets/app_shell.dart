import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive.dart';
import '../models/user.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import 'dashboard_widgets.dart';

// Shell colours
const kShellBlue = Color(0xFF0B2545);
const kShellBlueDark = Color(0xFF071A33);
const kShellAccent = Color(0xFF45B4EC);
const kShellBg = Color(0xFFDDEAF2);
const kShellField = Color(0xFFDCEAF3);

typedef ShellNavItem = ({IconData icon, IconData activeIcon, String label});

/// Text typed into the shell's search box. Screens listed in
/// [AppShell.searchable] listen to it to filter what they show.
final shellSearch = ValueNotifier<String>('');

/// Sidebar + top bar on wide screens, app bar + bottom navigation on phones.
/// Shared by the admin, sub-admin and employee homes.
class AppShell extends StatefulWidget {
  final UserModel user;
  final List<ShellNavItem> items;
  final List<Widget> screens;

  /// Indexes of [screens] that respond to the search box.
  final Set<int> searchable;

  const AppShell({
    super.key,
    required this.user,
    required this.items,
    required this.screens,
    this.searchable = const {},
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    shellSearch.value = '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    _searchCtrl.clear();
    shellSearch.value = '';
    setState(() => _index = i);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Responsive.isDesktop(context) ? _buildDesktop() : _buildMobile();
  }

  // ── Wide layout ────────────────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: kShellBg,
      body: Row(
        children: [
          _Sidebar(items: widget.items, index: _index, onSelect: _select),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: widget.items[_index].label,
                  user: widget.user,
                  searchCtrl: widget.searchable.contains(_index)
                      ? _searchCtrl
                      : null,
                  onLogout: _logout,
                ),
                Expanded(child: widget.screens[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone layout ───────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: kShellBg,
      appBar: AppBar(
        backgroundColor: kShellBlue,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GTO Connect ERP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              widget.items[_index].label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          _UserMenu(user: widget.user, onLogout: _logout, compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _select,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kShellBlue,
        unselectedItemColor: const Color(0xFF8AA3B5),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        items: widget.items
            .map(
              (n) => BottomNavigationBarItem(
                icon: Icon(n.icon),
                activeIcon: Icon(n.activeIcon),
                label: n.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<ShellNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.items,
    required this.index,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: kShellBlue,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 68,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'GTO Connect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (_, i) => _SidebarItem(
                item: items[i],
                active: i == index,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final ShellNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? kShellAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white.withValues(alpha: 0.06),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: 28),
            Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            // Active marker on the sidebar's right edge
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: active ? 30 : 0,
              decoration: const BoxDecoration(
                color: kShellAccent,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final UserModel user;
  final TextEditingController? searchCtrl;
  final VoidCallback onLogout;

  const _TopBar({
    required this.title,
    required this.user,
    required this.searchCtrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: kShellBlue,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: searchCtrl == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ShellSearchField(controller: searchCtrl),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          _UserMenu(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

/// Pill search box bound to [shellSearch].
class ShellSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final Color fill;
  const ShellSearchField({super.key, this.controller, this.fill = kShellField});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: (v) => shellSearch.value = v,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: kShellBlueDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kShellBlue,
          ),
          suffixIcon: const Icon(Icons.search, size: 20, color: kShellBlue),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Profile block with sign-out menu ─────────────────────────────────────────
class _UserMenu extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final bool compact;

  const _UserMenu({
    required this.user,
    required this.onLogout,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        initialsOf(user.name),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'logout') onLogout();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kShellBlueDark,
                ),
              ),
              Text(
                user.email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF6B8497),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: kShellBlue),
              const SizedBox(width: 10),
              Text(
                'Sign out',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kShellBlueDark,
                ),
              ),
            ],
          ),
        ),
      ],
      child: compact
          ? avatar
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: kShellAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ),
    );
  }
}

// ── Toolbar pill (Sort / Filter / Add) ───────────────────────────────────────
class ShellPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const ShellPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8FA),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: kShellBlueDark.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: kShellBlueDark),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kShellBlueDark,
          ),
        ),
      ],
    ),
  );
}
