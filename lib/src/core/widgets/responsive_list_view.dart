import 'package:flutter/material.dart';

class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final view = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final horizontal = switch (constraints.maxWidth) {
          >= 900 => 24.0,
          >= 560 => 18.0,
          _ => 14.0,
        };
        final top = constraints.maxWidth >= 560 ? 16.0 : 12.0;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 28),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    final body = SafeArea(top: false, bottom: false, child: view);
    if (onRefresh == null) {
      return body;
    }

    return RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}
