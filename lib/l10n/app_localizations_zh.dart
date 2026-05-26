// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => '您的 AI。您的设备。您的规则。';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get done => '完成';

  @override
  String get continue_action => '继续';

  @override
  String get skip => '跳过';

  @override
  String get install => '安装';

  @override
  String get download => '下载';

  @override
  String get resume => '继续';

  @override
  String get pause => '暂停';

  @override
  String get stop => '停止';

  @override
  String get edit => '编辑';

  @override
  String get preview => '预览';

  @override
  String get unload => '卸载';

  @override
  String get load => '加载';

  @override
  String get rename => '重命名';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => '取消 Pin';

  @override
  String get share => '分享';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制！';

  @override
  String get copied_to_clipboard => '已复制到剪贴板';

  @override
  String get select => '选择';

  @override
  String get active => '已启用';

  @override
  String get all => '全部';

  @override
  String get none => '无';

  @override
  String get none_selected => '未选择';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get error => '错误';

  @override
  String get unknown_error => '未知错误';

  @override
  String get not_now => '暂不';

  @override
  String get enable => '启用';

  @override
  String get proceed_anyway => '仍然继续';

  @override
  String get test_connection => '测试连接';

  @override
  String get testing => '正在测试...';

  @override
  String get connection_successful => '连接成功！';

  @override
  String get connection_failed => '连接失败。请检查您的设置。';

  @override
  String get save_continue => '保存并继续';

  @override
  String get save_changes => '保存更改';

  @override
  String get finish_setup => '完成设置';

  @override
  String get start_new_chat => '开始新聊天';

  @override
  String get cannot_undo => '此操作无法撤销。';

  @override
  String get ram_warning => '内存警告';

  @override
  String get recommended => '推荐';

  @override
  String get may_be_large => '可能对于此设备来说过大';

  @override
  String get calculating => '正在计算...';

  @override
  String get download_failed => '下载失败';

  @override
  String get downloaded => '已下载';

  @override
  String get not_downloaded => '未下载';

  @override
  String get installed => '已安装';

  @override
  String get not_installed => '未安装';

  @override
  String get loading => '正在加载...';

  @override
  String get thinking => '正在思考';

  @override
  String get processing => '正在处理...';

  @override
  String get initializing => '正在初始化...';

  @override
  String get ready => '就绪';

  @override
  String get preparing_app => '正在准备应用...';

  @override
  String get initializing_services => '正在初始化服务...';

  @override
  String get configuring_server => '正在配置服务器...';

  @override
  String get startup_failed => '启动失败';

  @override
  String get something_went_wrong => '出了点问题';

  @override
  String get delete_model_title => '删除模型';

  @override
  String delete_model_body(String name) {
    return '您确定要删除 $name 吗？';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return '您确定要删除 $name 吗？这释放大约 $size 的空间。\n\n如有需要，您稍后可以重新下载此模型。';
  }

  @override
  String get delete_voice_title => '删除语音';

  @override
  String delete_voice_body(String name, String size) {
    return '您确定要删除 $name 吗？这释放大约 $size 的空间。\n\n如有需要，您稍后可以重新下载此语音。';
  }

  @override
  String get delete_server_title => '删除服务器';

  @override
  String delete_server_body(String name) {
    return '您确定要删除 \"$name\" 吗？此操作无法撤销。';
  }

  @override
  String get delete_conversation_title => '删除对话吗？';

  @override
  String delete_conversation_body(String title) {
    return '您确定要删除 \"$title\" 吗？此操作无法撤销。';
  }

  @override
  String get delete_message_title => '删除消息吗？';

  @override
  String delete_persona_title(String name) {
    return '删除 \"$name\" 吗？';
  }

  @override
  String get delete_persona_body => '此操作无法撤销。';

  @override
  String get clear_conversation_title => '清除对话吗？';

  @override
  String get clear_conversation_body => '这会删除此对话中的所有消息。';

  @override
  String get clear => '清除';

  @override
  String label_completed(String label) {
    return '$label 已完成';
  }

  @override
  String error_with_message(String error) {
    return '错误: $error';
  }

  @override
  String preview_failed(String error) {
    return '预览失败: $error';
  }

  @override
  String loading_model(String modelId) {
    return '正在加载 $modelId...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return '模型已加载: $modelId ($backend)';
  }

  @override
  String get no_model_loaded => '未加载任何模型。点击 “管理设备端模型” 以下载并加载模型。';

  @override
  String loading_model_error(String error) {
    return '错误: $error';
  }

  @override
  String get delete_conversation => '删除对话吗？';

  @override
  String get nav_history => '历史';

  @override
  String get nav_servers => '服务器';

  @override
  String get nav_local_models => '本地模型';

  @override
  String get nav_tts => '语音合成';

  @override
  String get nav_personas => '角色';

  @override
  String get nav_settings => '设置';

  @override
  String get nav_new_chat => '新聊天';

  @override
  String get search_hint => '搜索对话...';

  @override
  String get no_server_selected => '未选择服务器';

  @override
  String get switch_server => '切换服务器';

  @override
  String get switch_server_subtitle => '选择要连接的服务器';

  @override
  String get manage_servers => '管理服务器';

  @override
  String get open_source => '开源';

  @override
  String get open_source_desc => 'LocalMind 是开源项目。可在 GitHub 上关注我们的进展或参与贡献。';

  @override
  String get star_on_github => '在 GitHub 上点亮 Star';

  @override
  String get settings_title => '设置';

  @override
  String get settings_appearance => '外观';

  @override
  String get settings_language => '语言';

  @override
  String get language_system_default => '系统默认';

  @override
  String get settings_tts => '语音合成 (TTS)';

  @override
  String get settings_behavior => '行为';

  @override
  String get settings_on_device => '设备端推理';

  @override
  String get settings_default_server => '默认服务器';

  @override
  String get settings_default_persona => '默认角色';

  @override
  String get settings_privacy => '隐私';

  @override
  String get settings_data_management => '数据管理';

  @override
  String get settings_about => '关于';

  @override
  String get theme => '主题';

  @override
  String get theme_system => '系统';

  @override
  String get theme_light => '亮色';

  @override
  String get theme_dark => '暗色';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => '字体大小';

  @override
  String get font_size_desc => '调整聊天中的文本大小。';

  @override
  String get font_preview => '敏捷的棕色狐狸跳过那只懒狗。';

  @override
  String get code_theme_dark => '代码主题 (暗色)';

  @override
  String get code_theme_light => '代码主题 (亮色)';

  @override
  String get code_theme_desc => '选择代码块的语法高亮主题。';

  @override
  String get tts_engine => 'TTS 引擎';

  @override
  String get tts_engine_system => '系统 TTS';

  @override
  String get tts_engine_kitten => 'Kitten TTS';

  @override
  String get voice => '语音';

  @override
  String get voice_female => '女声';

  @override
  String get voice_male => '男声';

  @override
  String get voice_other => '其他';

  @override
  String get tts_speed => 'TTS 速度';

  @override
  String get tts_speed_desc => '调整播放速率。';

  @override
  String get manage_tts_models => '管理 TTS 模型';

  @override
  String get manage_on_device_models => '管理设备端模型';

  @override
  String get enable_smart_reply => '设备端智能回复';

  @override
  String get streaming_responses => '流式响应';

  @override
  String get auto_generate_titles => '自动生成标题';

  @override
  String get send_on_enter => '按 Enter 键发送';

  @override
  String get show_system_messages => '显示系统消息';

  @override
  String get haptic_feedback => '触觉反馈';

  @override
  String get enable_mcp => '启用 MCP';

  @override
  String get new_chat_mcp_default => '新聊天默认启用 MCP';

  @override
  String get show_data_indicator => '显示数据指示器';

  @override
  String get privacy_info => '\"LocalMind 绝不查看您的数据\"';

  @override
  String get delete_all_conversations => '删除所有对话';

  @override
  String get reset_settings_defaults => '重置设置至默认值';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => '聊天参数';

  @override
  String get change_persona => '更换角色';

  @override
  String get set_persona => '设置角色';

  @override
  String get remove_persona => '删除角色';

  @override
  String get clear_conversation => '清除对话';

  @override
  String get connection_error => '连接错误。请检查您的服务器。';

  @override
  String get disconnected => '与服务器断开连接。';

  @override
  String get configure => '配置';

  @override
  String get select_model => '选择模型';

  @override
  String get select_persona => '选择角色';

  @override
  String get start_conversation => '开始对话';

  @override
  String get recent_chats => '最近聊天';

  @override
  String get see_all => '查看全部';

  @override
  String get quick_write => '帮我写一个函数';

  @override
  String get quick_explain => '解释这段代码';

  @override
  String get quick_debug => '帮我调试这个';

  @override
  String get quick_async => '我该如何使用 async/await？';

  @override
  String get history_missing_title => '历史记录丢失';

  @override
  String get history_missing_desc => '此聊天中的消息已被删除，或历史记录已损坏。';

  @override
  String get technical_details => '技术细节';

  @override
  String get last_error => '上次错误:';

  @override
  String get copy_info => '复制信息';

  @override
  String get conversation_id => '对话 ID';

  @override
  String get created_at => '创建于';

  @override
  String get expected_messages => '预期消息';

  @override
  String get debug_dialog_desc => '用以帮助识别同步问题的诊断信息。';

  @override
  String get chat_input_hint => '问任何问题';

  @override
  String get send_message_tooltip => '发送消息';

  @override
  String get stop_generation_tooltip => '停止生成';

  @override
  String get attach_images_tooltip => '附加图片';

  @override
  String tool_label(String toolCallId) {
    return '工具: $toolCallId';
  }

  @override
  String get tool_unknown => '工具: 未知';

  @override
  String get message_options => '消息选项';

  @override
  String get copy_markdown => '复制为 Markdown';

  @override
  String get copied_markdown => '已复制为 Markdown';

  @override
  String get read_aloud => '朗读';

  @override
  String get stop_reading => '停止朗读';

  @override
  String get more => '更多';

  @override
  String character_count(int length) {
    return '$length 个字符';
  }

  @override
  String get edit_message => '编辑消息';

  @override
  String get edit_message_desc => '保存将移除下方助手的回复并重新生成。';

  @override
  String get save_regenerate => '保存并重新生成';

  @override
  String get chat_settings_title => '聊天设置';

  @override
  String get reset_defaults => '重置默认值';

  @override
  String get parameters_tab => '参数';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => '温度';

  @override
  String get temperature_desc => '控制随机性：较高 = 创意，较低 = 专注';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => '核采样阈值';

  @override
  String get max_tokens => '最大 Token 数';

  @override
  String get max_tokens_desc => '响应限制';

  @override
  String get context_length => '上下文长度';

  @override
  String get context_length_desc => '历史窗口';

  @override
  String get mcp_disabled_warning => 'MCP 已在全局被禁用。请在设置中启用以使用这些功能。';

  @override
  String get mcp_enable_chat => '为此聊天启用 MCP';

  @override
  String get auto_execute_tools => '自动执行工具';

  @override
  String get beta_label => 'Beta';

  @override
  String get experimental_label => '实验性';

  @override
  String get add_ephemeral_mcp => '添加临时 MCP 服务器';

  @override
  String get mcp_label_placeholder => '标签';

  @override
  String get mcp_url_placeholder => 'URL (https://...)';

  @override
  String get active_integrations => '活动集成';

  @override
  String get enable_notifications => '启用通知';

  @override
  String get enable_notifications_desc => '在模型下载完成时获得通知。';

  @override
  String get chat_history_title => '聊天历史';

  @override
  String get conversation_just_now => '刚刚';

  @override
  String conversation_minutes_ago(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String conversation_hours_ago(int hours) {
    return '$hours小时前';
  }

  @override
  String get conversation_yesterday => '昨天';

  @override
  String conversation_days_ago(int days) {
    return '$days天前';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get options_tooltip => '选项';

  @override
  String get no_results_found => '未找到结果';

  @override
  String get no_conversations_yet => '尚无对话';

  @override
  String get try_different_search => '尝试不同的搜索词';

  @override
  String get start_new_conversation => '开始新对话';

  @override
  String get rename_conversation => '重命名对话';

  @override
  String get enter_new_title => '输入新标题';

  @override
  String get pinned_section => '已 pin';

  @override
  String get today_section => '今天';

  @override
  String get yesterday_section => '昨天';

  @override
  String get previous_7_days => '前 7 天';

  @override
  String get previous_30_days => '前 30 天';

  @override
  String get older_section => '更早';

  @override
  String get onboarding_choose_language => '选择语言';

  @override
  String get onboarding_choose_language_desc => '选择您首选的语言。您随时可以在设置中更改此项。';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => '连接您的\n服务器';

  @override
  String get onboarding_connect_desc =>
      '连接到 LM Studio、Ollama 或\nOpenRouter，开启您的私有 AI\n体验。';

  @override
  String get onboarding_welcome => '欢迎使用 LocalMind';

  @override
  String get server_type_on_device => '设备端';

  @override
  String get server_type_on_device_sub => '无需服务器';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => '本地 API';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'CLI 引擎';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => '统一云';

  @override
  String get ready_continue => '准备好继续';

  @override
  String get waiting_selection => '等待选择';

  @override
  String get setup_connection => '设置连接';

  @override
  String setup_connection_desc(String server) {
    return '配置您的 $server 服务器以开始聊天。';
  }

  @override
  String get server_name => '服务器名称';

  @override
  String get name_required => '需要名称';

  @override
  String get name_max_50 => '最多 50 个字符';

  @override
  String get host_label => '主机 / IP 地址';

  @override
  String get host_required => '需要主机地址';

  @override
  String get port_label => '端口';

  @override
  String get port_required => '需要端口';

  @override
  String get port_invalid => '必须是数字';

  @override
  String get port_range => '输入有效的端口号 (1-65535)';

  @override
  String get api_key_required => 'API 密钥 *';

  @override
  String get api_key_optional => 'API 密钥 (可选)';

  @override
  String get api_key_required_openrouter => 'OpenRouter 需要 API 密钥';

  @override
  String get api_key_format => 'OpenRouter API 密钥以 sk- 开头';

  @override
  String get my_server_hint => '我的服务器';

  @override
  String get name_length_validation => '名称必须在 50 个字符以内';

  @override
  String get host_valid => '输入有效的主机名或 IP 地址';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => '适用于已验证的服务器';

  @override
  String get update_server => '更新服务器';

  @override
  String get save_server => '保存服务器';

  @override
  String get server_updated => '服务器已更新';

  @override
  String get server_added => '服务器已添加';

  @override
  String get download_model_title => '下载模型';

  @override
  String get download_model_desc => '选择要下载的模型。\n它将在您的设备上本地运行。';

  @override
  String get on_device_android_only => '设备端推理当前仅可在 Android 上使用。';

  @override
  String get total_ram => '总内存';

  @override
  String get available => '可用';

  @override
  String ram_min_required(String fileSize) {
    return '最低要求 $fileSize GB 内存 (RAM)';
  }

  @override
  String download_progress(String percent, String speed) {
    return '$percent% • $speed';
  }

  @override
  String eta_label(String eta) {
    return '预计剩余时间: $eta';
  }

  @override
  String paused_progress(String percent) {
    return '已暂停 - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return '此模型需要至少 $ram GB 内存，但您的设备仅有 $totalMemory。它可能无法正常运行，或会导致应用崩溃。';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return '您的设备当前有 $availableRAM 可用内存，但此模型推荐至少 $ram GB。加载它可能会失败或导致系统不稳定。';
  }

  @override
  String get choose_theme => '选择主题';

  @override
  String get choose_theme_desc => '个性化应用程序外观。您随时可以在设置中更改此项。';

  @override
  String get theme_card_system => '系统';

  @override
  String get theme_card_system_sub => '匹配您的设备设置';

  @override
  String get theme_card_light => '亮色';

  @override
  String get theme_card_light_sub => '干净明亮';

  @override
  String get theme_card_dark => '暗色';

  @override
  String get theme_card_dark_sub => '保护眼睛';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => '温馨的桃色色调主题';

  @override
  String get stay_updated => '保持更新';

  @override
  String get stay_updated_desc => '在您的 AI 模型下载完成或长时间运行的任务结束时获得通知。';

  @override
  String get notification_benefit_downloads => '模型下载进度';

  @override
  String get notification_benefit_completions => '生成完成';

  @override
  String get notification_benefit_background => '后台任务状态';

  @override
  String get allow_notifications => '允许通知';

  @override
  String get servers_title => '服务器';

  @override
  String get no_servers_yet => '尚无服务器';

  @override
  String get no_servers_desc => '添加您的首个服务器以开始与 AI 模型聊天。';

  @override
  String get add_server => '添加服务器';

  @override
  String switched_to_server(String name) {
    return '已切换到 $name';
  }

  @override
  String get edit_server => '编辑服务器';

  @override
  String get add_server_title => '添加服务器';

  @override
  String get server_type_label => '服务器类型';

  @override
  String get server_icon_label => '服务器图标';

  @override
  String get default_icon => '默认图标';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => '兼容 OpenAI';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => '设备端';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => '本地推理';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => '默认';

  @override
  String get set_as_default => '设为默认';

  @override
  String get select_icon => '选择图标';

  @override
  String get select_icon_desc => '为您的服务器选择一个图标';

  @override
  String get search_icons_hint => '搜索图标...';

  @override
  String get server_icon_stack => '服务器堆栈';

  @override
  String get server_icon_stack2 => '服务器堆栈 02';

  @override
  String get server_icon_stack3 => '服务器堆栈 03';

  @override
  String get server_icon_cloud => '云';

  @override
  String get server_icon_cloud_server => '云端服务器';

  @override
  String get server_icon_mcp => 'MCP 服务器';

  @override
  String get server_icon_database => '数据库';

  @override
  String get server_icon_database1 => '数据库 01';

  @override
  String get server_icon_database2 => '数据库 02';

  @override
  String get server_icon_cpu => 'CPU';

  @override
  String get server_icon_chip => '芯片';

  @override
  String get server_icon_chip2 => '芯片 02';

  @override
  String get server_icon_computer => '电脑';

  @override
  String get server_icon_laptop => '笔记本电脑';

  @override
  String get server_icon_terminal => '电脑终端';

  @override
  String get server_icon_code => '代码';

  @override
  String get server_icon_ai_brain => 'AI 大脑';

  @override
  String get server_icon_ai_brain2 => 'AI 大脑 02';

  @override
  String get server_icon_ai_cloud => 'AI 云端';

  @override
  String get server_icon_ai_network => 'AI 网络';

  @override
  String get server_icon_ai_chat => 'AI 聊天';

  @override
  String get server_icon_cellular => '蜂窝网络';

  @override
  String get server_icon_plug1 => '插头 01';

  @override
  String get server_icon_plug2 => '插头 02';

  @override
  String get server_icon_bot => '机器人';

  @override
  String get server_icon_bot2 => '机器人 02';

  @override
  String get server_icon_robotic => '机器人声音';

  @override
  String get server_icon_rocket => '火箭';

  @override
  String get server_icon_star => 'Star';

  @override
  String get server_icon_settings1 => '设置 01';

  @override
  String get server_icon_settings2 => '设置 02';

  @override
  String get server_icon_home1 => '主页 01';

  @override
  String get server_icon_home2 => '主页 02';

  @override
  String get server_icon_folder1 => '文件夹 01';

  @override
  String get server_icon_folder2 => '文件夹 02';

  @override
  String get server_icon_file1 => '文件 01';

  @override
  String get server_icon_lock => '锁';

  @override
  String get server_icon_key => '钥匙 01';

  @override
  String get server_icon_link => '链接 01';

  @override
  String get server_icon_globe => '地球仪';

  @override
  String get server_icon_api => 'API';

  @override
  String get server_icon_arrow_right => '右箭头 01';

  @override
  String get server_icon_check => '勾选圆圈';

  @override
  String get server_icon_alert => '警报圆圈';

  @override
  String get server_icon_info => '信息圆圈';

  @override
  String get server_icon_zap => 'Zap';

  @override
  String get server_icon_cloud_upload => '云端上传';

  @override
  String get server_icon_cloud_download => '云端下载';

  @override
  String get server_icon_refresh => '刷新';

  @override
  String get server_icon_hard_drive => '硬盘';

  @override
  String get server_icon_drive => '驱动器';

  @override
  String get personas_title => '角色';

  @override
  String get persona_category_general => '通用';

  @override
  String get persona_category_coding => '编程';

  @override
  String get persona_category_education => '教育';

  @override
  String get persona_category_creative => '创意';

  @override
  String get persona_builtin_section => '内置';

  @override
  String get persona_my_section => '我的角色';

  @override
  String get clone_edit => '克隆并编辑';

  @override
  String get builtin_badge => '内置';

  @override
  String get no_personas_found => '未找到任何角色';

  @override
  String get no_personas_desc => '创建您的第一个角色以定制 AI 行为。';

  @override
  String get edit_persona => '编辑角色';

  @override
  String get create_persona => '创建角色';

  @override
  String get create_persona_button => '创建';

  @override
  String get emoji_label => '表情符号';

  @override
  String get name_label => '名称';

  @override
  String get my_persona_hint => '我的角色';

  @override
  String get category_label => '分类';

  @override
  String get description_optional => '描述 (可选)';

  @override
  String get description_hint => '此角色要做的是...';

  @override
  String get system_prompt => '系统提示词';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => '尚无提示词...';

  @override
  String get prompt_hint => '你是一个得力的助手...';

  @override
  String get prompt_required => '需要系统提示词';

  @override
  String get prompt_max_chars => '最多 4000 个字符';

  @override
  String get advanced_settings => '高级设置';

  @override
  String get temperature_label => '温度 (0.0-2.0)';

  @override
  String get top_p_label => 'Top P (0.0-1.0)';

  @override
  String get temp_hint => '0.7';

  @override
  String get top_p_hint => '0.9';

  @override
  String get range_0_2 => '0.0-2.0';

  @override
  String get range_0_1 => '0.0-1.0';

  @override
  String get persona_updated => '角色已更新';

  @override
  String get persona_created => '角色已创建';

  @override
  String get tts_models_title => '语音合成模型';

  @override
  String get always_available => '始终可用';

  @override
  String get tts_system_desc => '使用您设备内置的语音合成引擎。\n无需额外下载。语音选择依赖您的设备系统设置。';

  @override
  String get downloading_status => '正在下载...';

  @override
  String tts_kitten_desc(String size) {
    return '拥有 8 种表现力声音的闪电般高速神经网络 TTS。\n需要下载 $size。';
  }

  @override
  String tts_piper_desc(String size) {
    return '快速离线 Piper 语音，拥有 2 种极具表现力的声音。\n每个声音需要下载 $size。';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb MB · $ramMb MB 内存 · $voiceCount 种语音';
  }

  @override
  String get on_device_models_title => '设备端模型';

  @override
  String get available_models => '可用模型';

  @override
  String get device_memory => '设备内存';

  @override
  String get ram_usage => '内存占用';

  @override
  String get memory_healthy => '健康';

  @override
  String get memory_critical => '严重警告';

  @override
  String get memory_low => '偏低';

  @override
  String ram_used(String percent) {
    return '已使用 $percent%';
  }

  @override
  String get available_ram => '可用内存';

  @override
  String get total_capacity => '总容量';

  @override
  String get loaded_status => '已加载';

  @override
  String get inference_backend => '推理后端';

  @override
  String get backend_ios_notice => 'iOS 上仅支持 CPU 后端。';

  @override
  String get backend_cpu_desc => '适用于所有设备。兼容性最好。';

  @override
  String get backend_gpu_desc => 'OpenCL 加速。在支持 of 设备上运行更快。';

  @override
  String get backend_npu_desc => '厂商 NPU (高通/联发科)。最快的推理速度。';

  @override
  String get select_model_title => '选择模型';

  @override
  String get refresh_models => '刷新模型';

  @override
  String get search_models_hint => '搜索模型...';

  @override
  String get no_server_connected => '未连接服务器';

  @override
  String get add_server_first => '请先添加服务器以查看可用模型。';

  @override
  String get failed_load_models => '加载模型失败';

  @override
  String get no_models_available => '无可用模型';

  @override
  String no_models_match(String searchQuery) {
    return '没有匹配 \"$searchQuery\" 的模型';
  }

  @override
  String model_load_failed(String error) {
    return '加载模型失败: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return '在 keep-alive 时间过去后，$name 将被自动卸载';
  }

  @override
  String model_unloaded_success(String name) {
    return '$name 已成功卸载';
  }

  @override
  String model_unload_failed(String error) {
    return '卸载模型失败: $error';
  }

  @override
  String get unload_from_server => '从服务器卸载';

  @override
  String context_chip(String ctx) {
    return '$ctx 上下文 (ctx)';
  }

  @override
  String download_notification_title(String modelName) {
    return '正在下载 $modelName...';
  }

  @override
  String get download_complete_notification => '下载完成！';

  @override
  String download_complete_body(String modelName) {
    return '$modelName 已成功下载。';
  }

  @override
  String download_failed_notification(String error) {
    return '下载失败: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return '下载 $modelName 失败。';
  }

  @override
  String get engine_name_system => '系统 TTS';

  @override
  String get engine_tagline_system => '内置设备引擎';

  @override
  String get engine_name_kitten => 'Kitten TTS';

  @override
  String get engine_tagline_kitten => '高速神经网络 TTS';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => '离线 Piper 语音';

  @override
  String get voice_jasper => 'Jasper';

  @override
  String get voice_bella => 'Bella';

  @override
  String get voice_bruno => 'Bruno';

  @override
  String get voice_luna => 'Luna';

  @override
  String get voice_hugo => 'Hugo';

  @override
  String get voice_rosie => 'Rosie';

  @override
  String get voice_leo => 'Leo';

  @override
  String get voice_kiki => 'Kiki';

  @override
  String get voice_lessac => 'Lessac (美音)';

  @override
  String get voice_ryan => 'Ryan (美音)';

  @override
  String get model_qwen_3 => 'Qwen 3 0.6B';

  @override
  String get model_qwen_3_desc => '最小的通用聊天模型。响应速度快，内存消耗低。';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc => '平衡的质量和大小。适合一般对话。';

  @override
  String get model_deepseek => 'DeepSeek R1 Distill Qwen 1.5B';

  @override
  String get model_deepseek_desc => '推理与思维链模型。最适合逻辑任务。';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc => 'Google 旗舰模型。最高质量，需要更多内存。';

  @override
  String export_header(String date) {
    return '*导出自 LocalMind — $date*';
  }

  @override
  String get export_role_user => '## 👤 用户';

  @override
  String get export_role_assistant => '## 🤖 助手';

  @override
  String get export_role_system => '## ⚙️ 系统';

  @override
  String get export_role_tool => '## 🔧 工具';

  @override
  String get export_text_user => '[用户]';

  @override
  String get export_text_assistant => '[助手]';

  @override
  String get export_text_system => '[系统]';

  @override
  String get export_text_tool => '[工具]';

  @override
  String get export_label_user => '用户';

  @override
  String get export_label_assistant => '助手';

  @override
  String get export_label_system => '系统';

  @override
  String get export_label_tool => '工具';

  @override
  String get select_model_hint => '选择一个模型以开始聊天';

  @override
  String get test_notification_title => '测试通知';

  @override
  String get test_notification_body => '这是用于展示模型下载进度的测试通知。';
}
