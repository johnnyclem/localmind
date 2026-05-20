// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => 'Your AI. Your Device. Your Rules.';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get continue_action => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get install => 'Install';

  @override
  String get download => 'Download';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get edit => 'Edit';

  @override
  String get preview => 'Preview';

  @override
  String get unload => 'Unload';

  @override
  String get load => 'Load';

  @override
  String get rename => 'Rename';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get copied_to_clipboard => 'Copied to clipboard';

  @override
  String get select => 'Select';

  @override
  String get active => 'Active';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get none_selected => 'None selected';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get error => 'Error';

  @override
  String get unknown_error => 'Unknown error';

  @override
  String get not_now => 'Not Now';

  @override
  String get enable => 'Enable';

  @override
  String get proceed_anyway => 'Proceed Anyway';

  @override
  String get test_connection => 'Test Connection';

  @override
  String get testing => 'Testing...';

  @override
  String get connection_successful => 'Connection successful!';

  @override
  String get connection_failed => 'Connection failed. Check your settings.';

  @override
  String get save_continue => 'Save & Continue';

  @override
  String get save_changes => 'Save Changes';

  @override
  String get finish_setup => 'Finish Setup';

  @override
  String get start_new_chat => 'Start New Chat';

  @override
  String get cannot_undo => 'This action cannot be undone.';

  @override
  String get ram_warning => 'RAM Warning';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get may_be_large => 'May be too large for this device';

  @override
  String get calculating => 'Calculating...';

  @override
  String get download_failed => 'Download failed';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get not_downloaded => 'Not downloaded';

  @override
  String get installed => 'Installed';

  @override
  String get not_installed => 'Not installed';

  @override
  String get loading => 'Loading...';

  @override
  String get thinking => 'Thinking';

  @override
  String get processing => 'Processing...';

  @override
  String get initializing => 'Initializing...';

  @override
  String get ready => 'Ready';

  @override
  String get preparing_app => 'Preparing app...';

  @override
  String get initializing_services => 'Initializing services...';

  @override
  String get configuring_server => 'Configuring server...';

  @override
  String get startup_failed => 'Startup failed';

  @override
  String get something_went_wrong => 'Something went wrong';

  @override
  String get delete_model_title => 'Delete Model';

  @override
  String delete_model_body(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return 'Are you sure you want to delete $name? This will free up approximately $size of space.\n\nYou can download this model again later if needed.';
  }

  @override
  String get delete_voice_title => 'Delete Voice';

  @override
  String delete_voice_body(String name, String size) {
    return 'Are you sure you want to delete $name? This will free up approximately $size of space.\n\nYou can download this voice again later if needed.';
  }

  @override
  String get delete_server_title => 'Delete Server';

  @override
  String delete_server_body(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get delete_conversation_title => 'Delete conversation?';

  @override
  String delete_conversation_body(String title) {
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String get delete_message_title => 'Delete message?';

  @override
  String delete_persona_title(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get delete_persona_body => 'This cannot be undone.';

  @override
  String get clear_conversation_title => 'Clear conversation?';

  @override
  String get clear_conversation_body =>
      'This will delete all messages in this conversation.';

  @override
  String get clear => 'Clear';

  @override
  String label_completed(String label) {
    return '$label completed';
  }

  @override
  String error_with_message(String error) {
    return 'Error: $error';
  }

  @override
  String preview_failed(String error) {
    return 'Preview failed: $error';
  }

  @override
  String loading_model(String modelId) {
    return 'Loading $modelId...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return 'Model loaded: $modelId ($backend)';
  }

  @override
  String get no_model_loaded =>
      'No model loaded. Tap \"Manage On-Device Models\" to download and load a model.';

  @override
  String loading_model_error(String error) {
    return 'Error: $error';
  }

  @override
  String get delete_conversation => 'Delete conversation?';

  @override
  String get nav_history => 'History';

  @override
  String get nav_servers => 'Servers';

  @override
  String get nav_local_models => 'Local Models';

  @override
  String get nav_tts => 'Text To Speech';

  @override
  String get nav_personas => 'Personas';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_new_chat => 'New Chat';

  @override
  String get search_hint => 'Search conversations...';

  @override
  String get no_server_selected => 'No server selected';

  @override
  String get switch_server => 'Switch Server';

  @override
  String get switch_server_subtitle => 'Choose a server to connect to';

  @override
  String get manage_servers => 'Manage Servers';

  @override
  String get open_source => 'Open Source';

  @override
  String get open_source_desc =>
      'LocalMind is open source. Follow our progress or contribute on GitHub.';

  @override
  String get star_on_github => 'Star on GitHub';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_language => 'Language';

  @override
  String get language_system_default => 'System Default';

  @override
  String get settings_tts => 'Text-to-Speech';

  @override
  String get settings_behavior => 'Behavior';

  @override
  String get settings_on_device => 'On-Device Inference';

  @override
  String get settings_default_server => 'Default Server';

  @override
  String get settings_default_persona => 'Default Persona';

  @override
  String get settings_privacy => 'Privacy';

  @override
  String get settings_data_management => 'Data Management';

  @override
  String get settings_about => 'About';

  @override
  String get theme => 'Theme';

  @override
  String get theme_system => 'System';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => 'Font Size';

  @override
  String get font_size_desc => 'Adjust text size in chat.';

  @override
  String get font_preview => 'The quick brown fox jumps over the lazy dog.';

  @override
  String get code_theme_dark => 'Code Theme (Dark)';

  @override
  String get code_theme_light => 'Code Theme (Light)';

  @override
  String get code_theme_desc =>
      'Choose syntax highlighting theme for code blocks.';

  @override
  String get tts_engine => 'TTS Engine';

  @override
  String get tts_engine_system => 'System TTS';

  @override
  String get tts_engine_kitten => 'Kitten TTS';

  @override
  String get voice => 'Voice';

  @override
  String get voice_female => 'Female';

  @override
  String get voice_male => 'Male';

  @override
  String get voice_other => 'Other';

  @override
  String get tts_speed => 'TTS Speed';

  @override
  String get tts_speed_desc => 'Adjust the playback rate.';

  @override
  String get manage_tts_models => 'Manage TTS Models';

  @override
  String get manage_on_device_models => 'Manage On-Device Models';

  @override
  String get enable_smart_reply => 'On-Device Smart Replies';

  @override
  String get streaming_responses => 'Streaming Responses';

  @override
  String get auto_generate_titles => 'Auto-generate Titles';

  @override
  String get send_on_enter => 'Send on Enter';

  @override
  String get show_system_messages => 'Show System Messages';

  @override
  String get haptic_feedback => 'Haptic Feedback';

  @override
  String get enable_mcp => 'Enable MCP';

  @override
  String get new_chat_mcp_default => 'New Chat MCP Default';

  @override
  String get show_data_indicator => 'Show Data Indicator';

  @override
  String get privacy_info => '\"LocalMind never sees your data\"';

  @override
  String get delete_all_conversations => 'Delete All Conversations';

  @override
  String get reset_settings_defaults => 'Reset Settings to Defaults';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => 'Chat Parameters';

  @override
  String get change_persona => 'Change Persona';

  @override
  String get set_persona => 'Set Persona';

  @override
  String get remove_persona => 'Remove Persona';

  @override
  String get clear_conversation => 'Clear Conversation';

  @override
  String get connection_error => 'Connection error. Check your server.';

  @override
  String get disconnected => 'Disconnected from server.';

  @override
  String get configure => 'Configure';

  @override
  String get select_model => 'Select Model';

  @override
  String get select_persona => 'Select Persona';

  @override
  String get start_conversation => 'Start a conversation';

  @override
  String get recent_chats => 'Recent chats';

  @override
  String get see_all => 'See all';

  @override
  String get quick_write => 'Help me write a function';

  @override
  String get quick_explain => 'Explain this code';

  @override
  String get quick_debug => 'Debug this for me';

  @override
  String get quick_async => 'How do I use async/await?';

  @override
  String get history_missing_title => 'History Missing';

  @override
  String get history_missing_desc =>
      'Either the messages in this chat were deleted or the history record is corrupted.';

  @override
  String get technical_details => 'Technical Details';

  @override
  String get last_error => 'Last Error:';

  @override
  String get copy_info => 'Copy Info';

  @override
  String get conversation_id => 'Conversation ID';

  @override
  String get created_at => 'Created At';

  @override
  String get expected_messages => 'Expected Messages';

  @override
  String get debug_dialog_desc =>
      'Diagnostic information to help identify synchronization issues.';

  @override
  String get chat_input_hint => 'Ask anything';

  @override
  String get send_message_tooltip => 'Send message';

  @override
  String get stop_generation_tooltip => 'Stop generation';

  @override
  String get attach_images_tooltip => 'Attach images';

  @override
  String tool_label(String toolCallId) {
    return 'Tool: $toolCallId';
  }

  @override
  String get tool_unknown => 'Tool: Unknown';

  @override
  String get message_options => 'Message options';

  @override
  String get copy_markdown => 'Copy as Markdown';

  @override
  String get copied_markdown => 'Copied as Markdown';

  @override
  String get read_aloud => 'Read Aloud';

  @override
  String get stop_reading => 'Stop Reading';

  @override
  String get more => 'More';

  @override
  String character_count(int length) {
    return '$length characters';
  }

  @override
  String get edit_message => 'Edit message';

  @override
  String get edit_message_desc =>
      'Saving will remove the assistant response below and regenerate.';

  @override
  String get save_regenerate => 'Save & regenerate';

  @override
  String get chat_settings_title => 'Chat Settings';

  @override
  String get reset_defaults => 'Reset Defaults';

  @override
  String get parameters_tab => 'Parameters';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperature_desc =>
      'Controls randomness: Higher = Creative, Lower = Focused';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => 'Nucleus sampling threshold';

  @override
  String get max_tokens => 'Max Tokens';

  @override
  String get max_tokens_desc => 'Response limit';

  @override
  String get context_length => 'Context Length';

  @override
  String get context_length_desc => 'History window';

  @override
  String get mcp_disabled_warning =>
      'MCP is disabled globally. Enable it in Settings to use these features.';

  @override
  String get mcp_enable_chat => 'Enable MCP for this chat';

  @override
  String get auto_execute_tools => 'Auto-execute tools';

  @override
  String get add_ephemeral_mcp => 'Add Ephemeral MCP Server';

  @override
  String get mcp_label_placeholder => 'Label';

  @override
  String get mcp_url_placeholder => 'URL (https://...)';

  @override
  String get active_integrations => 'Active Integrations';

  @override
  String get enable_notifications => 'Enable Notifications';

  @override
  String get enable_notifications_desc =>
      'Get notified when models finish downloading.';

  @override
  String get chat_history_title => 'Chat History';

  @override
  String get conversation_just_now => 'Just now';

  @override
  String conversation_minutes_ago(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String conversation_hours_ago(int hours) {
    return '${hours}h ago';
  }

  @override
  String get conversation_yesterday => 'Yesterday';

  @override
  String conversation_days_ago(int days) {
    return '${days}d ago';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get options_tooltip => 'Options';

  @override
  String get no_results_found => 'No results found';

  @override
  String get no_conversations_yet => 'No conversations yet';

  @override
  String get try_different_search => 'Try a different search term';

  @override
  String get start_new_conversation => 'Start a new conversation';

  @override
  String get rename_conversation => 'Rename conversation';

  @override
  String get enter_new_title => 'Enter new title';

  @override
  String get pinned_section => 'PINNED';

  @override
  String get today_section => 'TODAY';

  @override
  String get yesterday_section => 'YESTERDAY';

  @override
  String get previous_7_days => 'PREVIOUS 7 DAYS';

  @override
  String get previous_30_days => 'PREVIOUS 30 DAYS';

  @override
  String get older_section => 'OLDER';

  @override
  String get onboarding_choose_language => 'Choose Language';

  @override
  String get onboarding_choose_language_desc =>
      'Select your preferred language. You can change this anytime in settings.';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => 'Connect Your\nServer';

  @override
  String get onboarding_connect_desc =>
      'Connect to LM Studio, Ollama, or\nOpenRouter to start your private AI\nexperience.';

  @override
  String get onboarding_welcome => 'Welcome to LocalMind';

  @override
  String get server_type_on_device => 'On-Device';

  @override
  String get server_type_on_device_sub => 'NO SERVER NEEDED';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => 'LOCAL API';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'CLI ENGINE';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => 'UNIFIED CLOUD';

  @override
  String get ready_continue => 'READY TO CONTINUE';

  @override
  String get waiting_selection => 'WAITING FOR SELECTION';

  @override
  String get setup_connection => 'Setup Connection';

  @override
  String setup_connection_desc(String server) {
    return 'Configure your $server server to start chatting.';
  }

  @override
  String get server_name => 'Server Name';

  @override
  String get name_required => 'Name required';

  @override
  String get name_max_50 => 'Max 50 characters';

  @override
  String get host_label => 'Host / IP Address';

  @override
  String get host_required => 'Host required';

  @override
  String get port_label => 'Port';

  @override
  String get port_required => 'Port required';

  @override
  String get port_invalid => 'Must be a number';

  @override
  String get port_range => 'Enter a valid port (1-65535)';

  @override
  String get api_key_required => 'API Key *';

  @override
  String get api_key_optional => 'API Key (Optional)';

  @override
  String get api_key_required_openrouter => 'API Key required for OpenRouter';

  @override
  String get api_key_format => 'OpenRouter API keys start with sk-';

  @override
  String get my_server_hint => 'My Server';

  @override
  String get name_length_validation => 'Name must be 50 characters or less';

  @override
  String get host_valid => 'Enter a valid hostname or IP address';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => 'For authenticated servers';

  @override
  String get update_server => 'Update Server';

  @override
  String get save_server => 'Save Server';

  @override
  String get server_updated => 'Server updated';

  @override
  String get server_added => 'Server added';

  @override
  String get download_model_title => 'Download a Model';

  @override
  String get download_model_desc =>
      'Choose a model to download.\nIt will run locally on your device.';

  @override
  String get on_device_android_only =>
      'On-device inference is currently available on Android only.';

  @override
  String get total_ram => 'Total RAM';

  @override
  String get available => 'Available';

  @override
  String ram_min_required(String fileSize) {
    return '$fileSize GB RAM min';
  }

  @override
  String download_progress(String percent, String speed) {
    return '$percent% • $speed';
  }

  @override
  String eta_label(String eta) {
    return 'ETA: $eta';
  }

  @override
  String paused_progress(String percent) {
    return 'Paused - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return 'This model requires at least $ram GB RAM, but your device has $totalMemory. It may not run correctly or could cause the app to crash.';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return 'Your device has $availableRAM available RAM, but this model recommends at least $ram GB. Loading it might fail or cause instability.';
  }

  @override
  String get choose_theme => 'Choose Theme';

  @override
  String get choose_theme_desc =>
      'Personalize the app appearance. You can always change this later in settings.';

  @override
  String get theme_card_system => 'System';

  @override
  String get theme_card_system_sub => 'Matches your device settings';

  @override
  String get theme_card_light => 'Light';

  @override
  String get theme_card_light_sub => 'Clean and bright';

  @override
  String get theme_card_dark => 'Dark';

  @override
  String get theme_card_dark_sub => 'Easy on the eyes';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => 'A warm, peach-tinted theme';

  @override
  String get stay_updated => 'Stay Updated';

  @override
  String get stay_updated_desc =>
      'Get notified when your AI models finish downloading or when long-running tasks complete.';

  @override
  String get notification_benefit_downloads => 'Model download progress';

  @override
  String get notification_benefit_completions => 'Generation completions';

  @override
  String get notification_benefit_background => 'Background tasks status';

  @override
  String get allow_notifications => 'Allow Notifications';

  @override
  String get servers_title => 'Servers';

  @override
  String get no_servers_yet => 'No Servers Yet';

  @override
  String get no_servers_desc =>
      'Add your first server to start chatting with AI models.';

  @override
  String get add_server => 'Add Server';

  @override
  String switched_to_server(String name) {
    return 'Switched to $name';
  }

  @override
  String get edit_server => 'Edit Server';

  @override
  String get add_server_title => 'Add Server';

  @override
  String get server_type_label => 'Server Type';

  @override
  String get server_icon_label => 'Server Icon';

  @override
  String get default_icon => 'Default icon';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => 'OpenAI Compatible';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => 'On-Device';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => 'Local inference';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => 'Default';

  @override
  String get set_as_default => 'Set as Default';

  @override
  String get select_icon => 'Select Icon';

  @override
  String get select_icon_desc => 'Choose an icon for your server';

  @override
  String get search_icons_hint => 'Search icons...';

  @override
  String get server_icon_stack => 'Server Stack';

  @override
  String get server_icon_stack2 => 'Server Stack 02';

  @override
  String get server_icon_stack3 => 'Server Stack 03';

  @override
  String get server_icon_cloud => 'Cloud';

  @override
  String get server_icon_cloud_server => 'Cloud Server';

  @override
  String get server_icon_mcp => 'MCP Server';

  @override
  String get server_icon_database => 'Database';

  @override
  String get server_icon_database1 => 'Database 01';

  @override
  String get server_icon_database2 => 'Database 02';

  @override
  String get server_icon_cpu => 'CPU';

  @override
  String get server_icon_chip => 'Chip';

  @override
  String get server_icon_chip2 => 'Chip 02';

  @override
  String get server_icon_computer => 'Computer';

  @override
  String get server_icon_laptop => 'Laptop';

  @override
  String get server_icon_terminal => 'Computer Terminal';

  @override
  String get server_icon_code => 'Code';

  @override
  String get server_icon_ai_brain => 'AI Brain';

  @override
  String get server_icon_ai_brain2 => 'AI Brain 02';

  @override
  String get server_icon_ai_cloud => 'AI Cloud';

  @override
  String get server_icon_ai_network => 'AI Network';

  @override
  String get server_icon_ai_chat => 'AI Chat';

  @override
  String get server_icon_cellular => 'Cellular Network';

  @override
  String get server_icon_plug1 => 'Plug 01';

  @override
  String get server_icon_plug2 => 'Plug 02';

  @override
  String get server_icon_bot => 'Bot';

  @override
  String get server_icon_bot2 => 'Bot 02';

  @override
  String get server_icon_robotic => 'Robotic';

  @override
  String get server_icon_rocket => 'Rocket';

  @override
  String get server_icon_star => 'Star';

  @override
  String get server_icon_settings1 => 'Settings 01';

  @override
  String get server_icon_settings2 => 'Settings 02';

  @override
  String get server_icon_home1 => 'Home 01';

  @override
  String get server_icon_home2 => 'Home 02';

  @override
  String get server_icon_folder1 => 'Folder 01';

  @override
  String get server_icon_folder2 => 'Folder 02';

  @override
  String get server_icon_file1 => 'File 01';

  @override
  String get server_icon_lock => 'Lock';

  @override
  String get server_icon_key => 'Key 01';

  @override
  String get server_icon_link => 'Link 01';

  @override
  String get server_icon_globe => 'Globe';

  @override
  String get server_icon_api => 'API';

  @override
  String get server_icon_arrow_right => 'Arrow Right 01';

  @override
  String get server_icon_check => 'Check Circle';

  @override
  String get server_icon_alert => 'Alert Circle';

  @override
  String get server_icon_info => 'Info Circle';

  @override
  String get server_icon_zap => 'Zap';

  @override
  String get server_icon_cloud_upload => 'Cloud Upload';

  @override
  String get server_icon_cloud_download => 'Cloud Download';

  @override
  String get server_icon_refresh => 'Refresh';

  @override
  String get server_icon_hard_drive => 'Hard Drive';

  @override
  String get server_icon_drive => 'Drive';

  @override
  String get personas_title => 'Personas';

  @override
  String get persona_category_general => 'General';

  @override
  String get persona_category_coding => 'Coding';

  @override
  String get persona_category_education => 'Education';

  @override
  String get persona_category_creative => 'Creative';

  @override
  String get persona_builtin_section => 'BUILT-IN';

  @override
  String get persona_my_section => 'MY PERSONAS';

  @override
  String get clone_edit => 'Clone & Edit';

  @override
  String get builtin_badge => 'Built-in';

  @override
  String get no_personas_found => 'No personas found';

  @override
  String get no_personas_desc =>
      'Create your first persona to customize AI behavior.';

  @override
  String get edit_persona => 'Edit Persona';

  @override
  String get create_persona => 'Create Persona';

  @override
  String get create_persona_button => 'Create';

  @override
  String get emoji_label => 'Emoji';

  @override
  String get name_label => 'Name';

  @override
  String get my_persona_hint => 'My Persona';

  @override
  String get category_label => 'Category';

  @override
  String get description_optional => 'Description (optional)';

  @override
  String get description_hint => 'What this persona does...';

  @override
  String get system_prompt => 'System Prompt';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => 'No prompt yet...';

  @override
  String get prompt_hint => 'You are a helpful assistant...';

  @override
  String get prompt_required => 'System prompt is required';

  @override
  String get prompt_max_chars => 'Max 4000 characters';

  @override
  String get advanced_settings => 'Advanced Settings';

  @override
  String get temperature_label => 'Temperature (0.0-2.0)';

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
  String get persona_updated => 'Persona updated';

  @override
  String get persona_created => 'Persona created';

  @override
  String get tts_models_title => 'Text To Speech Models';

  @override
  String get always_available => 'Always available';

  @override
  String get tts_system_desc =>
      'Uses your device\'s built-in text-to-speech engine.\nNo downloads required. Voice selection uses your device\'s system settings.';

  @override
  String get downloading_status => 'Downloading...';

  @override
  String tts_kitten_desc(String size) {
    return 'Lightning-fast neural TTS with 8 expressive voices.\nRequires $size download.';
  }

  @override
  String tts_piper_desc(String size) {
    return 'Fast offline Piper voices with 2 expressive voices.\nRequires $size download per voice.';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb MB · $ramMb MB RAM · $voiceCount voices';
  }

  @override
  String get on_device_models_title => 'On-Device Models';

  @override
  String get available_models => 'Available Models';

  @override
  String get device_memory => 'Device Memory';

  @override
  String get ram_usage => 'RAM Usage';

  @override
  String get memory_healthy => 'Healthy';

  @override
  String get memory_critical => 'Critical';

  @override
  String get memory_low => 'Low';

  @override
  String ram_used(String percent) {
    return '$percent% used';
  }

  @override
  String get available_ram => 'Available RAM';

  @override
  String get total_capacity => 'Total Capacity';

  @override
  String get loaded_status => 'Loaded';

  @override
  String get inference_backend => 'Inference Backend';

  @override
  String get backend_ios_notice => 'Only CPU backend is available on iOS.';

  @override
  String get backend_cpu_desc => 'Works on all devices. Most compatible.';

  @override
  String get backend_gpu_desc =>
      'OpenCL acceleration. Faster on supported devices.';

  @override
  String get backend_npu_desc =>
      'Vendor NPU (Qualcomm/MediaTek). Fastest inference.';

  @override
  String get select_model_title => 'Select Model';

  @override
  String get refresh_models => 'Refresh models';

  @override
  String get search_models_hint => 'Search models...';

  @override
  String get no_server_connected => 'No server connected';

  @override
  String get add_server_first => 'Add a server first to see available models.';

  @override
  String get failed_load_models => 'Failed to load models';

  @override
  String get no_models_available => 'No models available';

  @override
  String no_models_match(String searchQuery) {
    return 'No models match \"$searchQuery\"';
  }

  @override
  String model_load_failed(String error) {
    return 'Failed to load model: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return '$name will be unloaded once the keep-alive time passes';
  }

  @override
  String model_unloaded_success(String name) {
    return '$name unloaded successfully';
  }

  @override
  String model_unload_failed(String error) {
    return 'Failed to unload model: $error';
  }

  @override
  String get unload_from_server => 'Unload from server';

  @override
  String context_chip(String ctx) {
    return '$ctx ctx';
  }

  @override
  String download_notification_title(String modelName) {
    return 'Downloading $modelName...';
  }

  @override
  String get download_complete_notification => 'Download complete!';

  @override
  String download_complete_body(String modelName) {
    return '$modelName has been downloaded successfully.';
  }

  @override
  String download_failed_notification(String error) {
    return 'Download failed: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return 'Failed to download $modelName.';
  }

  @override
  String get engine_name_system => 'System TTS';

  @override
  String get engine_tagline_system => 'Built-in device engine';

  @override
  String get engine_name_kitten => 'Kitten TTS';

  @override
  String get engine_tagline_kitten => 'High-speed neural TTS';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => 'Offline Piper voices';

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
  String get voice_lessac => 'Lessac (US)';

  @override
  String get voice_ryan => 'Ryan (US)';

  @override
  String get model_qwen_3 => 'Qwen 3 0.6B';

  @override
  String get model_qwen_3_desc =>
      'Smallest general-purpose chat model. Fast responses, low memory usage.';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc =>
      'Balanced quality and size. Good for general conversation.';

  @override
  String get model_deepseek => 'DeepSeek R1 Distill Qwen 1.5B';

  @override
  String get model_deepseek_desc =>
      'Reasoning and chain-of-thought model. Best for logical tasks.';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc =>
      'Google flagship model. Highest quality, requires more RAM.';

  @override
  String export_header(String date) {
    return '*Exported from LocalMind — $date*';
  }

  @override
  String get export_role_user => '## 👤 User';

  @override
  String get export_role_assistant => '## 🤖 Assistant';

  @override
  String get export_role_system => '## ⚙️ System';

  @override
  String get export_role_tool => '## 🔧 Tool';

  @override
  String get export_text_user => '[USER]';

  @override
  String get export_text_assistant => '[ASSISTANT]';

  @override
  String get export_text_system => '[SYSTEM]';

  @override
  String get export_text_tool => '[TOOL]';

  @override
  String get export_label_user => 'USER';

  @override
  String get export_label_assistant => 'ASSISTANT';

  @override
  String get export_label_system => 'SYSTEM';

  @override
  String get export_label_tool => 'TOOL';

  @override
  String get select_model_hint => 'Select a model to start chatting';

  @override
  String get test_notification_title => 'Test notification';

  @override
  String get test_notification_body =>
      'This is a test notification for model download progress.';
}
