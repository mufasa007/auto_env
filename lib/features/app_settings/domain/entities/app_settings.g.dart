// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      themeMode:
          $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
          AppThemeMode.light,
      locale: json['locale'] as String?,
      closeAction:
          $enumDecodeNullable(_$CloseActionEnumMap, json['closeAction']) ??
          CloseAction.hideToTray,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'locale': instance.locale,
      'closeAction': _$CloseActionEnumMap[instance.closeAction]!,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
  AppThemeMode.system: 'system',
};

const _$CloseActionEnumMap = {
  CloseAction.hideToTray: 'hideToTray',
  CloseAction.quit: 'quit',
};
