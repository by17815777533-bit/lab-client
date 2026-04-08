import 'package:flutter/material.dart';

class PortalDestinationSpec {
  const PortalDestinationSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class PortalShellScaffold extends StatelessWidget {
  const PortalShellScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.destinations,
    required this.pages,
    required this.onDestinationSelected,
  });

  final String title;
  final int currentIndex;
  final List<PortalDestinationSpec> destinations;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wideLayout = constraints.maxWidth >= 1080;
        final Widget content = IndexedStack(
          index: currentIndex,
          children: pages,
        );

        if (!wideLayout) {
          return Stack(
            children: <Widget>[
              const _ShellBackdrop(),
              Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                body: SafeArea(bottom: false, child: content),
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE7EDF7)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x120F2C59),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: NavigationBar(
                          selectedIndex: currentIndex,
                          onDestinationSelected: onDestinationSelected,
                          destinations: destinations
                              .map(
                                (spec) => NavigationDestination(
                                  icon: Icon(spec.icon),
                                  selectedIcon: Icon(spec.selectedIcon),
                                  label: spec.label,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: <Widget>[
            const _ShellBackdrop(),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: <Widget>[
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Container(
                        width: 114,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          border: Border(
                            right: BorderSide(color: const Color(0xFFE7EDF7)),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x0F0F2C59),
                              blurRadius: 20,
                              offset: Offset(4, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                22,
                                18,
                                18,
                              ),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF12223A),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  16,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    for (
                                      int index = 0;
                                      index < destinations.length;
                                      index++
                                    ) ...<Widget>[
                                      _DesktopDestinationTile(
                                        spec: destinations[index],
                                        selected: currentIndex == index,
                                        onTap: () =>
                                            onDestinationSelected(index),
                                      ),
                                      if (index != destinations.length - 1)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        child: content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopDestinationTile extends StatelessWidget {
  const _DesktopDestinationTile({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final PortalDestinationSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = selected
        ? const Color(0xFF5B6CFF)
        : const Color(0xFF68758A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE4E8FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? spec.selectedIcon : spec.icon,
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                spec.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF12223A) : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFE9F4FF), Color(0xFFF5F7FB)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            left: -36,
            child: _BlurBlob(
              width: 220,
              height: 220,
              colors: <Color>[Color(0x6636A8FF), Color(0x0036A8FF)],
            ),
          ),
          Positioned(
            top: -30,
            right: -42,
            child: _BlurBlob(
              width: 200,
              height: 200,
              colors: <Color>[Color(0x335CCBFF), Color(0x005CCBFF)],
            ),
          ),
          Positioned(
            top: 72,
            right: 84,
            child: Transform.rotate(
              angle: 0.36,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
