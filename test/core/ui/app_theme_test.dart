import 'package:auto_env/core/ui/app_colors.dart';
import 'package:auto_env/core/ui/app_motion.dart';
import 'package:auto_env/core/ui/app_radii.dart';
import 'package:auto_env/core/ui/app_spacing.dart';
import 'package:auto_env/core/ui/app_theme.dart';
import 'package:auto_env/core/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing token values', () {
    test('grid is 4/8/12/16/24/32', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 12);
      expect(AppSpacing.lg, 16);
      expect(AppSpacing.xl, 24);
      expect(AppSpacing.xxl, 32);
    });
  });

  group('AppRadii token values', () {
    test('field/card/modal/pill radii', () {
      expect(AppRadii.field, 6);
      expect(AppRadii.card, 8);
      expect(AppRadii.modal, 10);
      expect(AppRadii.pill, 999);
    });
  });

  group('AppMotion token values', () {
    test('fast/base/slow durations and ease-out curve', () {
      expect(AppMotion.fast, const Duration(milliseconds: 120));
      expect(AppMotion.base, const Duration(milliseconds: 180));
      expect(AppMotion.slow, const Duration(milliseconds: 240));
      expect(AppMotion.curve, Curves.easeOutCubic);
    });
  });

  group('AppColors palette', () {
    test('core palette is the Raycast-style dark set', () {
      expect(AppColors.bg, const Color(0xFF1A1A1B));
      expect(AppColors.surface, const Color(0xFF1B1B1F));
      expect(AppColors.surfaceElevated, const Color(0xFF222226));
      expect(AppColors.border, const Color(0xFF2A2A2E));
      expect(AppColors.accent, const Color(0xFFFF6363));
      expect(AppColors.textPrimary, const Color(0xFFF2F2F4));
      expect(AppColors.textSecondary, const Color(0xFF9A9AA0));
    });
  });

  group('AppTypography', () {
    test('sans family is Inter', () {
      expect(AppTypography.sans, 'Inter');
      expect(AppTypography.title.fontFamily, 'Inter');
      expect(AppTypography.body.fontFamily, 'Inter');
      expect(AppTypography.caption.fontFamily, 'Inter');
    });

    test('mono falls back to system mono (no Inter)', () {
      expect(AppTypography.mono.fontFamily, isNull);
      expect(AppTypography.mono.fontFamilyFallback, contains('SF Mono'));
      expect(AppTypography.mono.fontFamilyFallback, contains('Cascadia Code'));
    });

    test('font sizes and weights match Raycast scale', () {
      expect(AppTypography.title.fontSize, 15);
      expect(AppTypography.title.fontWeight, FontWeight.w600);
      expect(AppTypography.body.fontSize, 13);
      expect(AppTypography.body.fontWeight, FontWeight.w400);
      expect(AppTypography.caption.fontSize, 11);
      expect(AppTypography.caption.fontWeight, FontWeight.w500);
      expect(AppTypography.mono.fontSize, 12);
    });
  });

  group('AppTheme.dark()', () {
    final theme = AppTheme.dark();

    test('is dark mode', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('scaffold background is the bg token', () {
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
    });

    test('color scheme primary is the accent token', () {
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.colorScheme.error, AppColors.error);
    });

    test('default font family is Inter', () {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });

    test('card theme uses border token', () {
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(cardShape.side.color, AppColors.border);
      expect(theme.cardTheme.elevation, 0);
    });

    test('dialog theme uses the modal radius', () {
      final dialogShape = theme.dialogTheme.shape! as RoundedRectangleBorder;
      final radius = dialogShape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppRadii.modal);
    });
  });
}
