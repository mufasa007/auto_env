// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'auto_env';

  @override
  String get listPageTitle => '环境列表';

  @override
  String get listEmpty => '还没有环境配置，点击 + 创建一个。';

  @override
  String listLoadError(String error) {
    return '加载环境配置失败：\n$error';
  }

  @override
  String get listFab => '新建环境';

  @override
  String get settingsTooltip => '设置';

  @override
  String get deleteDialogTitle => '删除环境？';

  @override
  String deleteDialogBody(String name) {
    return '确定删除「$name」？此操作不可撤销。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get cardActive => '当前生效';

  @override
  String cardSummary(int hosts, int envs, String updated) {
    return '$hosts 条 hosts · $envs 个环境变量 · 更新于 $updated';
  }

  @override
  String get actionActive => '已生效';

  @override
  String get actionActivate => '切换';

  @override
  String get actionRollback => '回滚';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionDelete => '删除';

  @override
  String get editTitleNew => '新建环境';

  @override
  String get editTitleEdit => '编辑环境';

  @override
  String get fieldName => '名称';

  @override
  String get errorNameEmpty => '名称不能为空';

  @override
  String get sectionHosts => 'Hosts 条目';

  @override
  String get sectionEnvVars => '环境变量';

  @override
  String get save => '保存';

  @override
  String get fieldIp => 'IP';

  @override
  String get fieldHostname => '主机名';

  @override
  String get addHostEntry => '添加 hosts 条目';

  @override
  String get fieldKey => '键';

  @override
  String get fieldValue => '值';

  @override
  String get addVariable => '添加变量';

  @override
  String get remove => '删除';

  @override
  String get modeRows => '表格';

  @override
  String get modeText => '文本';

  @override
  String parseLineError(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String get switchTitleRunning => '正在切换环境';

  @override
  String get switchTitleFailed => '切换失败';

  @override
  String get stageRequestingPrivilege => '正在申请管理员权限…';

  @override
  String get stageWritingHosts => '正在写入 hosts 文件…';

  @override
  String get stageWritingEnvVars => '正在更新环境变量…';

  @override
  String get stageFlushingDns => '正在刷新 DNS 缓存…';

  @override
  String get stageDone => '完成';

  @override
  String get dismiss => '关闭';

  @override
  String get retry => '重试';

  @override
  String switchedInBanner(String seconds) {
    return '切换完成（$seconds 秒）· 已运行的进程需要重启才能读到新环境变量。';
  }

  @override
  String get errorPrivilegePasswordWrong =>
      '管理员密码不正确。请点击重试，输入本机管理员账户（你登录系统用的那个）的密码。';

  @override
  String get errorPrivilegeNotAdmin =>
      '当前账户不是管理员。请切换到管理员账户，或在「系统设置 → 用户与群组」中授予管理员权限。';

  @override
  String get errorPrivilegeUserCanceled => '你取消了管理员授权。点击重试可重新弹出授权框。';

  @override
  String get errorPrivilegeGeneric => '管理员授权失败。点击重试可重新弹出授权框。';

  @override
  String get errorHostsWrite => '写入 hosts 文件失败。';

  @override
  String get errorEnvVarWrite => '更新环境变量失败。';

  @override
  String get errorDnsFlush => '刷新 DNS 缓存失败。';

  @override
  String get errorPartial => '切换只完成了一部分，建议回滚。';

  @override
  String get errorSwitchGeneric => '切换未能完成。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionWindow => '窗口';

  @override
  String get closeActionHideToTrayLabel => '最小化到托盘';

  @override
  String get closeActionHideToTrayDesc =>
      '关闭窗口时 auto_env 仍在菜单栏 / 系统托盘运行，从托盘菜单退出。';

  @override
  String get closeActionQuitLabel => '退出';

  @override
  String get closeActionQuitDesc => '关闭窗口时直接退出 auto_env（macOS / Windows 原生行为）。';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get languageLabel => '界面语言';

  @override
  String get localeSystem => '跟随系统';

  @override
  String get localeFollowSystem => '跟随系统';

  @override
  String get localeChinese => '中文';

  @override
  String get localeEnglish => 'English';

  @override
  String get trayNoActive => '无生效环境';

  @override
  String trayActive(String name) {
    return '已生效：$name';
  }

  @override
  String get trayNoProfilesHint => '暂无环境，请在 app 中创建';

  @override
  String get trayShowWindow => '显示窗口';

  @override
  String get trayQuit => '退出';
}
