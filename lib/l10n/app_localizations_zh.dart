// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Quiz';

  @override
  String get appSubtitle => '通用扩展题库练习系统';

  @override
  String get selectQuestionBank => '选择题库';

  @override
  String get selectMode => '选择模式';

  @override
  String get startPractice => '开始练习';

  @override
  String get exit => '退出';

  @override
  String get practiceMode => '练习模式';

  @override
  String get practiceModeDesc => '逐题练习，即时反馈';

  @override
  String get reviewMode => '复习模式';

  @override
  String get reviewModeDesc => '复习错题和标记题目';

  @override
  String get memorizeMode => '背题模式';

  @override
  String get memorizeModeDesc => '直接显示答案和解析';

  @override
  String get testMode => '模拟考试';

  @override
  String get testModeDesc => '随机抽题，计时考试';

  @override
  String get question => '题目';

  @override
  String get questionOf => '/';

  @override
  String get correct => '正确';

  @override
  String get wrong => '错误';

  @override
  String get accuracy => '正确率';

  @override
  String get mark => '标记';

  @override
  String get unmark => '取消标记';

  @override
  String get previous => '上一题';

  @override
  String get next => '下一题';

  @override
  String get submit => '提交';

  @override
  String get reset => '重置';

  @override
  String get showAnalysis => '显示解析';

  @override
  String get hideAnalysis => '隐藏解析';

  @override
  String get analysis => '解析';

  @override
  String get aiExplain => 'AI 解析';

  @override
  String get overview => '题目概览';

  @override
  String get all => '全部';

  @override
  String get unanswered => '未答';

  @override
  String get answered => '已答';

  @override
  String get marked => '已标记';

  @override
  String get testQuestionCount => '考试题数';

  @override
  String get startTest => '开始考试';

  @override
  String get finishTest => '交卷';

  @override
  String get testResult => '考试结果';

  @override
  String get totalQuestions => '总题数';

  @override
  String get correctCount => '答对';

  @override
  String get wrongCount => '答错';

  @override
  String get unansweredCount => '未答';

  @override
  String get timeTaken => '用时';

  @override
  String get backToHome => '返回首页';

  @override
  String get viewHistory => '查看历史';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get language => '语言';

  @override
  String get quizExperience => '练习体验';

  @override
  String get autoAdvance => '自动下一题';

  @override
  String get autoAdvanceDesc => '答对后自动跳转下一题';

  @override
  String get showAnalysisOption => '显示解析';

  @override
  String get showAnalysisOptionDesc => '答题后显示解析';

  @override
  String get soundEffects => '音效';

  @override
  String get soundEffectsDesc => '答题时播放音效';

  @override
  String get hapticFeedback => '振动反馈';

  @override
  String get hapticFeedbackDesc => '答题时振动提示';

  @override
  String get confettiEffect => '彩带效果';

  @override
  String get confettiEffectDesc => '答对时显示彩带动画';

  @override
  String get aiSettings => 'AI 设置';

  @override
  String get aiProvider => 'AI 服务商';

  @override
  String get aiApiKey => 'API 密钥';

  @override
  String get aiModel => '模型';

  @override
  String get aiChatScrollToBottom => '发送后滚动到底部';

  @override
  String get aiChatScrollToBottomDesc => '发送消息后自动滚动至最新内容';

  @override
  String get allSections => '全部章节';

  @override
  String get section => '章节';

  @override
  String get questions => '题';

  @override
  String get history => '历史记录';

  @override
  String get noHistory => '暂无历史记录';

  @override
  String get clearHistory => '清除历史';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get ok => '确定';

  @override
  String get clear => '清除';

  @override
  String get importPackage => '导入题包';

  @override
  String get importFailed => '导入失败';

  @override
  String importSuccess(String packageName) {
    return '成功导入\"$packageName\"';
  }

  @override
  String confirmDeleteBook(String bookName) {
    return '确定要删除\"$bookName\"吗？';
  }

  @override
  String get aiKeyNotSet => '未设置';

  @override
  String get aiBaseUrl => 'AI 基础 URL';

  @override
  String get aiBaseUrlDefault => '默认';

  @override
  String get aiBaseUrlHint => 'https://generativelanguage.googleapis.com';

  @override
  String get aiBaseUrlHelper => '留空使用默认地址';

  @override
  String get enterApiKey => '请输入 API 密钥';

  @override
  String get textSelectionMenu => '文本选择菜单';

  @override
  String get menuItemOrder => '菜单项排序';

  @override
  String get reorderMenuItems => '调整菜单顺序';

  @override
  String get confirmExitTest => '确定要结束考试吗？';

  @override
  String get resetProgress => '重置进度';

  @override
  String get confirmResetProgress => '确定要重置当前题库的所有进度吗？此操作不可撤销。';

  @override
  String get doReset => '重置';

  @override
  String get aiChatTitle => 'AI 解析';

  @override
  String get chatHistory => '历史记录';

  @override
  String get newChat => '新对话';

  @override
  String get chatInputHint => '输入问题...';

  @override
  String get startConversation => '开始与 AI 对话';

  @override
  String get noChatHistory => '暂无记录';

  @override
  String get deleteChat => '删除对话？';

  @override
  String confirmDeleteChat(String title) {
    return '确定要删除\"$title\"吗？';
  }

  @override
  String get aiSuggestion1 => '详细解析本题';

  @override
  String get aiSuggestion2 => '为什么其他选项是错误的？';

  @override
  String get aiSuggestion3 => '这道题考察的知识点是什么？';

  @override
  String get aiSuggestion4 => '用更简单的话解释';

  @override
  String get aiSuggestion5 => '帮我翻译成中文';

  @override
  String get testHistory => '考试历史';

  @override
  String get noTestHistory => '暂无历史记录';

  @override
  String get clearHistoryConfirm => '确定要清除所有考试历史记录吗？';

  @override
  String get totalShort => '总题';

  @override
  String get correctShort => '正确';

  @override
  String get wrongShort => '错误';
}
