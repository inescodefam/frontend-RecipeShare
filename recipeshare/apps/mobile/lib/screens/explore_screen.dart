import 'package:flutter/material.dart';

import 'package:shared/shared.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              icon: Icons.explore_rounded,
              message: 'Explore will appear here next.',
            ),
          ),
        ),
      ],
    );
  }
}

