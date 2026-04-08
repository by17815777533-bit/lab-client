import 'package:flutter/material.dart';

class PortalShortcutAction {
  const PortalShortcutAction({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
}

class PortalShortcutGrid extends StatelessWidget {
  const PortalShortcutGrid({super.key, required this.actions});

  final List<PortalShortcutAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 860 => 4,
          >= 560 => 3,
          >= 280 => 2,
          _ => 1,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 58,
          ),
          itemBuilder: (BuildContext context, int index) {
            final action = actions[index];
            return PortalShortcutChip(
              onPressed: action.onPressed,
              icon: action.icon,
              label: action.label,
              fullWidth: true,
            );
          },
        );
      },
    );
  }
}

class PortalShortcutChip extends StatelessWidget {
  const PortalShortcutChip({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.fullWidth = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0x162F76FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: const Color(0xFF476DBB)),
        ),
        const SizedBox(width: 10),
        if (fullWidth)
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF32445D),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF32445D),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Ink(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFF9FBFF), Color(0xFFF1F5FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9E4FF)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A2F76FF),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}
