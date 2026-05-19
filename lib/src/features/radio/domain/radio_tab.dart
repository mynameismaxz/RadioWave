import 'package:flutter/material.dart';

enum RadioTab { discover, favorites, equalizer, add }

extension RadioTabLabel on RadioTab {
  String get label {
    switch (this) {
      case RadioTab.discover:
        return 'Discover';
      case RadioTab.favorites:
        return 'Favorites';
      case RadioTab.equalizer:
        return 'Equalizer';
      case RadioTab.add:
        return 'Add Station';
    }
  }

  IconData get icon {
    switch (this) {
      case RadioTab.discover:
        return Icons.explore_outlined;
      case RadioTab.favorites:
        return Icons.favorite_border_rounded;
      case RadioTab.equalizer:
        return Icons.graphic_eq_rounded;
      case RadioTab.add:
        return Icons.add_rounded;
    }
  }
}
