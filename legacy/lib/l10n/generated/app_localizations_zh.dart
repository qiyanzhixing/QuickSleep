// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'QuickSleep';

  @override
  String get introTitle => '让呼吸慢下来';

  @override
  String get introSubtitle => '呼吸引导 · 音乐陪伴';

  @override
  String get durationTitle => '助眠时长';

  @override
  String minutes(int count) {
    return '$count分钟';
  }

  @override
  String get customDuration => '自定义';

  @override
  String get durationHint => '含呼吸引导 · 最后 15 秒淡出';

  @override
  String get soundMode => '声音模式';

  @override
  String get change => '更换';

  @override
  String get modeMoon => '月下轻语';

  @override
  String get modeMountain => '山间静心';

  @override
  String get modeForest => '林间晚风';

  @override
  String get descMoon => '轻柔合成女声 · 氛围音乐';

  @override
  String get descMountain => '沉稳合成男声 · 仿古琴合成音';

  @override
  String get descForest => '自然合成轻声 · 风声与树叶';

  @override
  String get mixedHint => '语音与配乐已搭配好';

  @override
  String get start => '开始放松';

  @override
  String get lockHint => '锁屏后继续播放';

  @override
  String get soundHint => '选一种声音，陪你慢慢入睡';

  @override
  String get preview => '试听';

  @override
  String get stopPreview => '停止试听';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get customTitle => '自定义时长';

  @override
  String get customHint => '输入 2–60 的整数分钟';

  @override
  String get customError => '请输入 2–60 的整数分钟';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get system => '跟随系统';

  @override
  String get night => '夜间';

  @override
  String get light => '浅色';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get sessionTitle => '助眠练习';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get end => '结束';

  @override
  String get backHome => '返回准备页';

  @override
  String get loading => '正在准备声音';

  @override
  String get paused => '已暂停';

  @override
  String get completed => '安静休息吧';

  @override
  String get inhale => '吸气';

  @override
  String get hold => '屏息';

  @override
  String get exhale => '呼气';

  @override
  String get natural => '自然呼吸';

  @override
  String get fading => '渐渐安静';

  @override
  String round(int count) {
    return '第 $count 轮 / 共 4 轮';
  }

  @override
  String remaining(String time) {
    return '剩余 $time';
  }

  @override
  String get audioError => '声音未能播放，请返回后重试';

  @override
  String get startupError => '无法加载本地声音，请重试或重新安装';

  @override
  String get retry => '重试';

  @override
  String get saveError => '设置未能保存，下次打开可能会恢复默认';

  @override
  String get safetyHint => '呼吸不适时，可随时结束并恢复自然呼吸';

  @override
  String get offlineNote => '完全离线 · 无账号 · 无统计';

  @override
  String get syntheticNote => '语音与背景均为合成内容；仿古琴合成音并非真实古琴演奏';

  @override
  String get nextSessionHint => '语言与声音更改将在下一次练习生效';

  @override
  String get previewError => '试听未能播放，请重试';

  @override
  String get restartRequired => '声音服务未能启动，请完全退出并重新打开 QuickSleep';
}
