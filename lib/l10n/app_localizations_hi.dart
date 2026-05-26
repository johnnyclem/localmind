// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => 'आपका AI. आपका डिवाइस. आपके नियम।';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get close => 'बंद करें';

  @override
  String get done => 'पूर्ण';

  @override
  String get continue_action => 'जारी रखें';

  @override
  String get skip => 'छोड़ें';

  @override
  String get install => 'इंस्टॉल करें';

  @override
  String get download => 'डाउनलोड करें';

  @override
  String get resume => 'फिर से शुरू करें';

  @override
  String get pause => 'विराम दें';

  @override
  String get stop => 'रोकें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get preview => 'पूर्वावलोकन';

  @override
  String get unload => 'अनलोड करें';

  @override
  String get load => 'लोड करें';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get pin => 'पिन करें';

  @override
  String get unpin => 'अनपिन करें';

  @override
  String get share => 'साझा करें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copied => 'कॉपी किया गया!';

  @override
  String get copied_to_clipboard => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get select => 'चुनें';

  @override
  String get active => 'सक्रिय';

  @override
  String get all => 'सभी';

  @override
  String get none => 'कोई नहीं';

  @override
  String get none_selected => 'कोई चयनित नहीं है';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get error => 'त्रुटि';

  @override
  String get unknown_error => 'अज्ञात त्रुटि';

  @override
  String get not_now => 'अभी नहीं';

  @override
  String get enable => 'सक्षम करें';

  @override
  String get proceed_anyway => 'वैसे भी आगे बढ़ें';

  @override
  String get test_connection => 'कनेक्शन का परीक्षण करें';

  @override
  String get testing => 'परीक्षण किया जा रहा है...';

  @override
  String get connection_successful => 'कनेक्शन सफल रहा!';

  @override
  String get connection_failed =>
      'कनेक्शन विफल रहा। अपनी सेटिंग्स की जांच करें।';

  @override
  String get save_continue => 'सहेजें और जारी रखें';

  @override
  String get save_changes => 'बदलाव सहेजें';

  @override
  String get finish_setup => 'सेटअप पूर्ण करें';

  @override
  String get start_new_chat => 'नई चैट शुरू करें';

  @override
  String get cannot_undo => 'इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get ram_warning => 'रैम चेतावनी';

  @override
  String get recommended => 'अनुशंसित';

  @override
  String get may_be_large => 'इस डिवाइस के लिए बहुत बड़ा हो सकता है';

  @override
  String get calculating => 'गणना की जा रही है...';

  @override
  String get download_failed => 'डाउनलोड विफल';

  @override
  String get downloaded => 'डाउनलोड किया गया';

  @override
  String get not_downloaded => 'डाउनलोड नहीं किया गया';

  @override
  String get installed => 'इंस्टॉल किया गया';

  @override
  String get not_installed => 'इंस्टॉल नहीं किया गया';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get thinking => 'सोच रहा है';

  @override
  String get processing => 'प्रसंस्करण किया जा रहा है...';

  @override
  String get initializing => 'प्रारंभ किया जा रहा है...';

  @override
  String get ready => 'तैयार';

  @override
  String get preparing_app => 'ऐप तैयार किया जा रहा है...';

  @override
  String get initializing_services => 'सेवाएं प्रारंभ की जा रही हैं...';

  @override
  String get configuring_server => 'सर्वर कॉन्फ़िगर किया जा रहा है...';

  @override
  String get startup_failed => 'स्टार्टअप विफल रहा';

  @override
  String get something_went_wrong => 'कुछ गलत हो गया';

  @override
  String get delete_model_title => 'मॉडल हटाएं';

  @override
  String delete_model_body(String name) {
    return 'क्या आप निश्चित रूप से $name को हटाना चाहते हैं?';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return 'क्या आप निश्चित रूप से $name को हटाना चाहते हैं? इससे लगभग $size स्थान खाली हो जाएगा।\n\nयदि आवश्यकता हो तो आप बाद में इस मॉडल को फिर से डाउनलोड कर सकते हैं।';
  }

  @override
  String get delete_voice_title => 'आवाज हटाएं';

  @override
  String delete_voice_body(String name, String size) {
    return 'क्या आप निश्चित रूप से $name को हटाना चाहते हैं? इससे लगभग $size स्थान खाली हो जाएगा।\n\nयदि आवश्यकता हो तो आप बाद में इस आवाज को फिर से डाउनलोड कर सकते हैं।';
  }

  @override
  String get delete_server_title => 'सर्वर हटाएं';

  @override
  String delete_server_body(String name) {
    return 'क्या आप निश्चित रूप से \"$name\" को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get delete_conversation_title => 'बातचीत हटाएं?';

  @override
  String delete_conversation_body(String title) {
    return 'क्या आप निश्चित रूप से \"$title\" को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get delete_message_title => 'संदेश हटाएं?';

  @override
  String delete_persona_title(String name) {
    return '\"$name\" हटाएं?';
  }

  @override
  String get delete_persona_body => 'इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get clear_conversation_title => 'बातचीत साफ़ करें?';

  @override
  String get clear_conversation_body =>
      'यह इस बातचीत के सभी संदेशों को हटा देगा।';

  @override
  String get clear => 'साफ़ करें';

  @override
  String label_completed(String label) {
    return '$label पूर्ण';
  }

  @override
  String error_with_message(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String preview_failed(String error) {
    return 'पूर्वावलोकन विफल: $error';
  }

  @override
  String loading_model(String modelId) {
    return '$modelId लोड किया जा रहा है...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return 'मॉडल लोड किया गया: $modelId ($backend)';
  }

  @override
  String get no_model_loaded =>
      'कोई मॉडल लोड नहीं है। मॉडल डाउनलोड और लोड करने के लिए \"ऑन-डिवाइस मॉडल प्रबंधित करें\" पर टैप करें।';

  @override
  String loading_model_error(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get delete_conversation => 'बातचीत हटाएं?';

  @override
  String get nav_history => 'इतिहास';

  @override
  String get nav_servers => 'सर्वर';

  @override
  String get nav_local_models => 'स्थानीय मॉडल';

  @override
  String get nav_tts => 'टेक्स्ट टू स्पीच';

  @override
  String get nav_personas => 'चरित्र (Personas)';

  @override
  String get nav_settings => 'सेटिंग्स';

  @override
  String get nav_new_chat => 'नई चैट';

  @override
  String get search_hint => 'बातचीत खोजें...';

  @override
  String get no_server_selected => 'कोई सर्वर चयनित नहीं है';

  @override
  String get switch_server => 'सर्वर बदलें';

  @override
  String get switch_server_subtitle => 'कनेक्ट करने के लिए एक सर्वर चुनें';

  @override
  String get manage_servers => 'सर्वर प्रबंधित करें';

  @override
  String get open_source => 'ओपन सोर्स';

  @override
  String get open_source_desc =>
      'LocalMind ओपन सोर्स है। गिटहब (GitHub) पर हमारी प्रगति का अनुसरण करें या योगदान दें।';

  @override
  String get star_on_github => 'GitHub पर स्टार दें';

  @override
  String get settings_title => 'सेटिंग्स';

  @override
  String get settings_appearance => 'दिखावट';

  @override
  String get settings_language => 'भाषा';

  @override
  String get language_system_default => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get settings_tts => 'टेक्स्ट-टू-स्पीच';

  @override
  String get settings_behavior => 'व्यवहार';

  @override
  String get settings_on_device => 'ऑन-डिवाइस अनुमान (On-Device Inference)';

  @override
  String get settings_default_server => 'डिफ़ॉल्ट सर्वर';

  @override
  String get settings_default_persona => 'डिफ़ॉल्ट चरित्र';

  @override
  String get settings_privacy => 'गोपनीयता';

  @override
  String get settings_data_management => 'डेटा प्रबंधन';

  @override
  String get settings_about => 'परिचय';

  @override
  String get theme => 'थीम';

  @override
  String get theme_system => 'सिस्टम';

  @override
  String get theme_light => 'लाइट';

  @override
  String get theme_dark => 'डार्क';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => 'फ़ॉन्ट का आकार';

  @override
  String get font_size_desc => 'चैट में टेक्स्ट का आकार समायोजित करें।';

  @override
  String get font_preview =>
      'त्वरित भूरी लोमड़ी आलसी कुत्ते के ऊपर से कूदती है।';

  @override
  String get code_theme_dark => 'कोड थीम (डार्क)';

  @override
  String get code_theme_light => 'कोड थीम (लाइट)';

  @override
  String get code_theme_desc =>
      'कोड ब्लॉक के लिए सिंटैक्स हाइलाइटिंग थीम चुनें।';

  @override
  String get tts_engine => 'TTS इंजन';

  @override
  String get tts_engine_system => 'सिस्टम TTS';

  @override
  String get tts_engine_kitten => 'Kitten TTS';

  @override
  String get voice => 'आवाज';

  @override
  String get voice_female => 'महिला';

  @override
  String get voice_male => 'पुरुष';

  @override
  String get voice_other => 'अन्य';

  @override
  String get tts_speed => 'TTS गति';

  @override
  String get tts_speed_desc => 'प्लेबैक की गति समायोजित करें।';

  @override
  String get manage_tts_models => 'TTS मॉडल प्रबंधित करें';

  @override
  String get manage_on_device_models => 'ऑन-डिवाइस मॉडल प्रबंधित करें';

  @override
  String get enable_smart_reply => 'ऑन-डिवाइस स्मार्ट रिप्लाइ';

  @override
  String get streaming_responses => 'प्रतिक्रियाएं स्ट्रीम करें';

  @override
  String get auto_generate_titles => 'स्वचालित रूप से शीर्षक उत्पन्न करें';

  @override
  String get send_on_enter => 'एंटर (Enter) दबाने पर भेजें';

  @override
  String get show_system_messages => 'सिस्टम संदेश दिखाएं';

  @override
  String get haptic_feedback => 'हैप्टिक फीडबैक';

  @override
  String get enable_mcp => 'MCP सक्षम करें';

  @override
  String get new_chat_mcp_default => 'नई चैट MCP डिफ़ॉल्ट';

  @override
  String get show_data_indicator => 'डेटा सूचक दिखाएं';

  @override
  String get privacy_info => '\"LocalMind आपके डेटा को कभी नहीं देखता है\"';

  @override
  String get delete_all_conversations => 'सभी बातचीत हटाएं';

  @override
  String get reset_settings_defaults => 'सेटिंग्स को डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => 'चैट पैरामीटर';

  @override
  String get change_persona => 'चरित्र बदलें';

  @override
  String get set_persona => 'चरित्र सेट करें';

  @override
  String get remove_persona => 'चरित्र हटाएं';

  @override
  String get clear_conversation => 'बातचीत साफ़ करें';

  @override
  String get connection_error => 'कनेक्शन त्रुटि। अपने सर्वर की जांच करें।';

  @override
  String get disconnected => 'सर्वर से कनेक्शन टूट गया।';

  @override
  String get configure => 'कॉन्फ़िगर करें';

  @override
  String get select_model => 'मॉडल चुनें';

  @override
  String get select_persona => 'चरित्र चुनें';

  @override
  String get start_conversation => 'बातचीत शुरू करें';

  @override
  String get recent_chats => 'हालिया चैट';

  @override
  String get see_all => 'सभी देखें';

  @override
  String get quick_write => 'मुझे एक फ़ंक्शन लिखने में मदद करें';

  @override
  String get quick_explain => 'इस कोड को समझाएं';

  @override
  String get quick_debug => 'इसे मेरे लिए डीबग करें';

  @override
  String get quick_async => 'मैं async/await का उपयोग कैसे करूं?';

  @override
  String get history_missing_title => 'इतिहास गायब है';

  @override
  String get history_missing_desc =>
      'या तो इस चैट के संदेश हटा दिए गए थे या इतिहास रिकॉर्ड दूषित हो गया है।';

  @override
  String get technical_details => 'तकनीकी विवरण';

  @override
  String get last_error => 'अंतिम त्रुटि:';

  @override
  String get copy_info => 'जानकारी कॉपी करें';

  @override
  String get conversation_id => 'बातचीत आईडी';

  @override
  String get created_at => 'निर्माण का समय';

  @override
  String get expected_messages => 'अपेक्षित संदेश';

  @override
  String get debug_dialog_desc =>
      'सिंक्रनाइज़ेशन समस्याओं की पहचान करने में सहायता के लिए नैदानिक जानकारी।';

  @override
  String get chat_input_hint => 'कुछ भी पूछें';

  @override
  String get send_message_tooltip => 'संदेश भेजें';

  @override
  String get stop_generation_tooltip => 'उत्पादन रोकें';

  @override
  String get attach_images_tooltip => 'छवियाँ संलग्न करें';

  @override
  String tool_label(String toolCallId) {
    return 'उपकरण: $toolCallId';
  }

  @override
  String get tool_unknown => 'उपकरण: अज्ञात';

  @override
  String get message_options => 'संदेश विकल्प';

  @override
  String get copy_markdown => 'Markdown के रूप में कॉपी करें';

  @override
  String get copied_markdown => 'Markdown के रूप में कॉपी किया गया';

  @override
  String get read_aloud => 'ज़ोर से पढ़ें';

  @override
  String get stop_reading => 'पढ़ना बंद करें';

  @override
  String get more => 'अधिक';

  @override
  String character_count(int length) {
    return '$length वर्ण';
  }

  @override
  String get edit_message => 'संदेश संपादित करें';

  @override
  String get edit_message_desc =>
      'सहेजने से नीचे सहायक की प्रतिक्रिया हट जाएगी और पुनः उत्पन्न होगी।';

  @override
  String get save_regenerate => 'सहेजें और पुनः उत्पन्न करें';

  @override
  String get chat_settings_title => 'चैट सेटिंग्स';

  @override
  String get reset_defaults => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get parameters_tab => 'पैरामीटर';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => 'तापमान';

  @override
  String get temperature_desc =>
      'यादृच्छिकता को नियंत्रित करता है: उच्च = रचनात्मक, निम्न = केंद्रित';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => 'न्यूक्लियस सैंपलिंग थ्रेशोल्ड';

  @override
  String get max_tokens => 'अधिकतम टोकन';

  @override
  String get max_tokens_desc => 'प्रतिक्रिया सीमा';

  @override
  String get context_length => 'संदर्भ लंबाई (Context Length)';

  @override
  String get context_length_desc => 'इतिहास विंडो';

  @override
  String get mcp_disabled_warning =>
      'MCP वैश्विक रूप से अक्षम है। इन सुविधाओं का उपयोग करने के लिए सेटिंग्स में इसे सक्षम करें।';

  @override
  String get mcp_enable_chat => 'इस चैट के लिए MCP सक्षम करें';

  @override
  String get auto_execute_tools => 'स्वचालित रूप से उपकरण निष्पादित करें';

  @override
  String get beta_label => 'बीटा';

  @override
  String get experimental_label => 'प्रायोगिक';

  @override
  String get add_ephemeral_mcp => 'अस्थायी MCP सर्वर जोड़ें';

  @override
  String get mcp_label_placeholder => 'लेबल';

  @override
  String get mcp_url_placeholder => 'URL (https://...)';

  @override
  String get active_integrations => 'सक्रिय एकीकरण';

  @override
  String get enable_notifications => 'सूचनाएं सक्षम करें';

  @override
  String get enable_notifications_desc =>
      'मॉडल डाउनलोड पूरा होने पर सूचित किया जाए।';

  @override
  String get chat_history_title => 'चैट इतिहास';

  @override
  String get conversation_just_now => 'अभी-अभी';

  @override
  String conversation_minutes_ago(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String conversation_hours_ago(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String get conversation_yesterday => 'कल';

  @override
  String conversation_days_ago(int days) {
    return '$days दिन पहले';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get options_tooltip => 'विकल्प';

  @override
  String get no_results_found => 'कोई परिणाम नहीं मिला';

  @override
  String get no_conversations_yet => 'अभी तक कोई बातचीत नहीं';

  @override
  String get try_different_search => 'कोई अन्य खोज शब्द आज़माएं';

  @override
  String get start_new_conversation => 'नई बातचीत शुरू करें';

  @override
  String get rename_conversation => 'बातचीत का नाम बदलें';

  @override
  String get enter_new_title => 'नया शीर्षक दर्ज करें';

  @override
  String get pinned_section => 'पिन किया गया';

  @override
  String get today_section => 'आज';

  @override
  String get yesterday_section => 'कल';

  @override
  String get previous_7_days => 'पिछले 7 दिन';

  @override
  String get previous_30_days => 'पिछले 30 दिन';

  @override
  String get older_section => 'पुराने';

  @override
  String get onboarding_choose_language => 'भाषा चुनें';

  @override
  String get onboarding_choose_language_desc =>
      'अपनी पसंदीदा भाषा चुनें। आप इसे सेटिंग्स में कभी भी बदल सकते हैं।';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => 'अपना सर्वर\nकनेक्ट करें';

  @override
  String get onboarding_connect_desc =>
      'अपना निजी AI अनुभव शुरू करने के लिए\nLM Studio, Ollama, या OpenRouter से\nकनेक्ट करें।';

  @override
  String get onboarding_welcome => 'LocalMind में आपका स्वागत है';

  @override
  String get server_type_on_device => 'ऑन-डिवाइस';

  @override
  String get server_type_on_device_sub => 'किसी सर्वर की आवश्यकता नहीं है';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => 'स्थानीय API';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'CLI इंजन';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => 'एकीकृत क्लाउड';

  @override
  String get ready_continue => 'जारी रखने के लिए तैयार';

  @override
  String get waiting_selection => 'चयन की प्रतीक्षा की जा रही है';

  @override
  String get setup_connection => 'कनेक्शन सेटअप करें';

  @override
  String setup_connection_desc(String server) {
    return 'चैटिंग शुरू करने के लिए अपने $server सर्वर को कॉन्फ़िगर करें।';
  }

  @override
  String get server_name => 'सर्वर का नाम';

  @override
  String get name_required => 'नाम आवश्यक है';

  @override
  String get name_max_50 => 'अधिकतम 50 वर्ण';

  @override
  String get host_label => 'होस्ट / IP पता';

  @override
  String get host_required => 'होस्ट आवश्यक है';

  @override
  String get port_label => 'पोर्ट';

  @override
  String get port_required => 'पोर्ट आवश्यक है';

  @override
  String get port_invalid => 'एक संख्या होनी चाहिए';

  @override
  String get port_range => 'एक वैध पोर्ट दर्ज करें (1-65535)';

  @override
  String get api_key_required => 'API कुंजी *';

  @override
  String get api_key_optional => 'API कुंजी (वैकल्पिक)';

  @override
  String get api_key_required_openrouter =>
      'OpenRouter के लिए API कुंजी आवश्यक है';

  @override
  String get api_key_format => 'OpenRouter API कुंजियाँ sk- से शुरू होती हैं';

  @override
  String get my_server_hint => 'मेरा सर्वर';

  @override
  String get name_length_validation => 'नाम 50 वर्ण या उससे कम होना चाहिए';

  @override
  String get host_valid => 'एक वैध होस्टनाम या IP पता दर्ज करें';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => 'प्रमाणित सर्वर के लिए';

  @override
  String get update_server => 'सर्वर अपडेट करें';

  @override
  String get save_server => 'सर्वर सहेजें';

  @override
  String get server_updated => 'सर्वर अपडेट किया गया';

  @override
  String get server_added => 'सर्वर जोड़ा गया';

  @override
  String get download_model_title => 'मॉडल डाउनलोड करें';

  @override
  String get download_model_desc =>
      'डाउनलोड करने के लिए एक मॉडल चुनें।\nयह आपके डिवाइस पर स्थानीय रूप से चलेगा।';

  @override
  String get on_device_android_only =>
      'ऑन-डिवाइस अनुमान वर्तमान में केवल Android पर उपलब्ध है।';

  @override
  String get total_ram => 'कुल रैम';

  @override
  String get available => 'उपलब्ध';

  @override
  String ram_min_required(String fileSize) {
    return 'न्यूनतम $fileSize GB रैम (RAM) आवश्यक';
  }

  @override
  String download_progress(String percent, String speed) {
    return '$percent% • $speed';
  }

  @override
  String eta_label(String eta) {
    return 'शेष समय (ETA): $eta';
  }

  @override
  String paused_progress(String percent) {
    return 'रोका गया - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return 'इस मॉडल के लिए कम से कम $ram GB रैम की आवश्यकता है, लेकिन आपके डिवाइस में $totalMemory है। यह सही ढंग से काम नहीं कर सकता है या ऐप क्रैश हो सकता है।';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return 'आपके डिवाइस में $availableRAM उपलब्ध रैम है, लेकिन यह मॉडल कम से कम $ram GB की सिफारिश करता है। इसे लोड करना विफल हो सकता है या अस्थिरता पैदा कर सकता है।';
  }

  @override
  String get choose_theme => 'थीम चुनें';

  @override
  String get choose_theme_desc =>
      'ऐप के रूप को निजीकृत करें। आप इसे बाद में सेटिंग्स में कभी भी बदल सकते हैं।';

  @override
  String get theme_card_system => 'सिस्टम';

  @override
  String get theme_card_system_sub => 'आपके डिवाइस की सेटिंग्स से मेल खाता है';

  @override
  String get theme_card_light => 'लाइट';

  @override
  String get theme_card_light_sub => 'साफ़ और उज्ज्वल';

  @override
  String get theme_card_dark => 'डार्क';

  @override
  String get theme_card_dark_sub => 'आँखों के लिए आरामदायक';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => 'एक हल्का नारंगी-पीला (peach) थीम';

  @override
  String get stay_updated => 'अपडेट रहें';

  @override
  String get stay_updated_desc =>
      'जब आपके AI मॉडल डाउनलोड हो जाएं या लंबे समय तक चलने वाले कार्य पूरे हो जाएं तो सूचित किया जाए।';

  @override
  String get notification_benefit_downloads => 'मॉडल डाउनलोड प्रगति';

  @override
  String get notification_benefit_completions => 'उत्पादन पूर्णता';

  @override
  String get notification_benefit_background => 'पृष्ठभूमि कार्यों की स्थिति';

  @override
  String get allow_notifications => 'सूचनाओं की अनुमति दें';

  @override
  String get servers_title => 'सर्वर';

  @override
  String get no_servers_yet => 'अभी तक कोई सर्वर नहीं है';

  @override
  String get no_servers_desc =>
      'AI मॉडल के साथ चैट करना शुरू करने के लिए अपना पहला सर्वर जोड़ें।';

  @override
  String get add_server => 'सर्वर जोड़ें';

  @override
  String switched_to_server(String name) {
    return '$name पर स्विच किया गया';
  }

  @override
  String get edit_server => 'सर्वर संपादित करें';

  @override
  String get add_server_title => 'सर्वर जोड़ें';

  @override
  String get server_type_label => 'सर्वर का प्रकार';

  @override
  String get server_icon_label => 'सर्वर आइकन';

  @override
  String get default_icon => 'डिफ़ॉल्ट आइकन';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => 'OpenAI संगत';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => 'ऑन-डिवाइस';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => 'स्थानीय अनुमान (Local Inference)';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => 'डिफ़ॉल्ट';

  @override
  String get set_as_default => 'डिफ़ॉल्ट रूप में सेट करें';

  @override
  String get select_icon => 'आइकन चुनें';

  @override
  String get select_icon_desc => 'अपने सर्वर के लिए एक आइकन चुनें';

  @override
  String get search_icons_hint => 'आइकन खोजें...';

  @override
  String get server_icon_stack => 'सर्वर स्टैक';

  @override
  String get server_icon_stack2 => 'सर्वर स्टैक 02';

  @override
  String get server_icon_stack3 => 'सर्वर स्टैक 03';

  @override
  String get server_icon_cloud => 'क्लाउड';

  @override
  String get server_icon_cloud_server => 'क्लाउड सर्वर';

  @override
  String get server_icon_mcp => 'MCP सर्वर';

  @override
  String get server_icon_database => 'डेटाबेस';

  @override
  String get server_icon_database1 => 'डेटाबेस 01';

  @override
  String get server_icon_database2 => 'डेटाबेस 02';

  @override
  String get server_icon_cpu => 'CPU';

  @override
  String get server_icon_chip => 'चिप';

  @override
  String get server_icon_chip2 => 'चिप 02';

  @override
  String get server_icon_computer => 'कंप्यूटर';

  @override
  String get server_icon_laptop => 'लैपटॉप';

  @override
  String get server_icon_terminal => 'कंप्यूटर टर्मिनल';

  @override
  String get server_icon_code => 'कोड';

  @override
  String get server_icon_ai_brain => 'AI ब्रेन';

  @override
  String get server_icon_ai_brain2 => 'AI ब्रेन 02';

  @override
  String get server_icon_ai_cloud => 'AI क्लाउड';

  @override
  String get server_icon_ai_network => 'AI नेटवर्क';

  @override
  String get server_icon_ai_chat => 'AI चैट';

  @override
  String get server_icon_cellular => 'सेलुलर नेटवर्क';

  @override
  String get server_icon_plug1 => 'प्लग 01';

  @override
  String get server_icon_plug2 => 'प्लग 02';

  @override
  String get server_icon_bot => 'बॉट';

  @override
  String get server_icon_bot2 => 'बॉट 02';

  @override
  String get server_icon_robotic => 'रोबोटिक';

  @override
  String get server_icon_rocket => 'रॉकेट';

  @override
  String get server_icon_star => 'स्टार';

  @override
  String get server_icon_settings1 => 'सेटिंग्स 01';

  @override
  String get server_icon_settings2 => 'सेटिंग्स 02';

  @override
  String get server_icon_home1 => 'होम 01';

  @override
  String get server_icon_home2 => 'होम 02';

  @override
  String get server_icon_folder1 => 'फ़ोल्डर 01';

  @override
  String get server_icon_folder2 => 'फ़ोल्डर 02';

  @override
  String get server_icon_file1 => 'फ़ाइल 01';

  @override
  String get server_icon_lock => 'लॉक';

  @override
  String get server_icon_key => 'कुंजी 01';

  @override
  String get server_icon_link => 'लिंक 01';

  @override
  String get server_icon_globe => 'ग्लोब';

  @override
  String get server_icon_api => 'API';

  @override
  String get server_icon_arrow_right => 'दायाँ तीर 01';

  @override
  String get server_icon_check => 'सत्यापन वृत्त';

  @override
  String get server_icon_alert => 'चेतावनी वृत्त';

  @override
  String get server_icon_info => 'सूचना वृत्त';

  @override
  String get server_icon_zap => 'जैप';

  @override
  String get server_icon_cloud_upload => 'क्लाउड अपलोड';

  @override
  String get server_icon_cloud_download => 'क्लाउड डाउनलोड';

  @override
  String get server_icon_refresh => 'रीफ्रेश करें';

  @override
  String get server_icon_hard_drive => 'हार्ड ड्राइव';

  @override
  String get server_icon_drive => 'ड्राइव';

  @override
  String get personas_title => 'चरित्र (Personas)';

  @override
  String get persona_category_general => 'सामान्य';

  @override
  String get persona_category_coding => 'कोडिंग';

  @override
  String get persona_category_education => 'शिक्षा';

  @override
  String get persona_category_creative => 'रचनात्मक';

  @override
  String get persona_builtin_section => 'इन-बिल्ट';

  @override
  String get persona_my_section => 'मेरे चरित्र (Personas)';

  @override
  String get clone_edit => 'क्लोन और संपादित करें';

  @override
  String get builtin_badge => 'इन-बिल्ट';

  @override
  String get no_personas_found => 'कोई चरित्र नहीं मिला';

  @override
  String get no_personas_desc =>
      'AI के व्यवहार को अनुकूलित करने के लिए अपना पहला चरित्र बनाएं।';

  @override
  String get edit_persona => 'चरित्र संपादित करें';

  @override
  String get create_persona => 'चरित्र बनाएं';

  @override
  String get create_persona_button => 'बनाएं';

  @override
  String get emoji_label => 'इमोजी';

  @override
  String get name_label => 'नाम';

  @override
  String get my_persona_hint => 'मेरा चरित्र';

  @override
  String get category_label => 'श्रेणी';

  @override
  String get description_optional => 'विवरण (वैकल्पिक)';

  @override
  String get description_hint => 'यह चरित्र क्या करता है...';

  @override
  String get system_prompt => 'सिस्टम प्रॉम्ट';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => 'अभी तक कोई प्रॉम्ट नहीं...';

  @override
  String get prompt_hint => 'आप एक सहायक हैं...';

  @override
  String get prompt_required => 'सिस्टम प्रॉम्ट आवश्यक है';

  @override
  String get prompt_max_chars => 'अधिकतम 4000 वर्ण';

  @override
  String get advanced_settings => 'उन्नत सेटिंग्स';

  @override
  String get temperature_label => 'तापमान (0.0-2.0)';

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
  String get persona_updated => 'चरित्र अद्यतित (updated)';

  @override
  String get persona_created => 'चरित्र निर्मित';

  @override
  String get tts_models_title => 'टेक्स्ट टू स्पीच मॉडल';

  @override
  String get always_available => 'हमेशा उपलब्ध';

  @override
  String get tts_system_desc =>
      'आपके डिवाइस के इन-बिल्ट टेक्स्ट-टू-स्पीच इंजन का उपयोग करता है।\nकिसी डाउनलोड की आवश्यकता नहीं है। आवाज चयन आपके डिवाइस की सिस्टम सेटिंग्स का उपयोग करता है।';

  @override
  String get downloading_status => 'डाउनलोड किया जा रहा है...';

  @override
  String tts_kitten_desc(String size) {
    return '8 अभिव्यंजक आवाज़ों के साथ बिजली की तरह तेज़ न्यूरल TTS।\n$size डाउनलोड की आवश्यकता है।';
  }

  @override
  String tts_piper_desc(String size) {
    return '2 अभिव्यंजक आवाज़ों के साथ तेज़ ऑफ़लाइन पाइपर (Piper) आवाज़ें।\nप्रति आवाज़ $size डाउनलोड की आवश्यकता है।';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb MB · $ramMb MB रैम · $voiceCount आवाजें';
  }

  @override
  String get on_device_models_title => 'ऑन-डिवाइस मॉडल';

  @override
  String get available_models => 'उपलब्ध मॉडल';

  @override
  String get device_memory => 'डिवाइस मेमोरी';

  @override
  String get ram_usage => 'रैम का उपयोग';

  @override
  String get memory_healthy => 'स्वस्थ';

  @override
  String get memory_critical => 'महत्वपूर्ण';

  @override
  String get memory_low => 'कम';

  @override
  String ram_used(String percent) {
    return '$percent% प्रयुक्त';
  }

  @override
  String get available_ram => 'उपलब्ध रैम (RAM)';

  @override
  String get total_capacity => 'कुल क्षमता';

  @override
  String get loaded_status => 'लोड किया गया';

  @override
  String get inference_backend => 'अनुमान बैकएंड (Inference Backend)';

  @override
  String get backend_ios_notice => 'iOS पर केवल CPU बैकएंड उपलब्ध है।';

  @override
  String get backend_cpu_desc => 'सभी उपकरणों पर काम करता है। सबसे अनुकूल।';

  @override
  String get backend_gpu_desc => 'OpenCL त्वरण। समर्थित उपकरणों पर तेज़।';

  @override
  String get backend_npu_desc =>
      'विक्रेता NPU (Qualcomm/MediaTek)। सबसे तेज़ अनुमान।';

  @override
  String get select_model_title => 'मॉडल चुनें';

  @override
  String get refresh_models => 'मॉडल रीफ्रेश करें';

  @override
  String get search_models_hint => 'मॉडल खोजें...';

  @override
  String get no_server_connected => 'कोई सर्वर कनेक्ट नहीं है';

  @override
  String get add_server_first =>
      'उपलब्ध मॉडल देखने के लिए पहले एक सर्वर जोड़ें।';

  @override
  String get failed_load_models => 'मॉडल लोड करने में विफल';

  @override
  String get no_models_available => 'कोई मॉडल उपलब्ध नहीं है';

  @override
  String no_models_match(String searchQuery) {
    return '\"$searchQuery\" से मेल खाने वाला कोई मॉडल नहीं मिला';
  }

  @override
  String model_load_failed(String error) {
    return 'मॉडल लोड करने में विफल: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return 'कीप-अलाइव (keep-alive) समय बीतने के बाद $name को अनलोड कर दिया जाएगा';
  }

  @override
  String model_unloaded_success(String name) {
    return '$name सफलतापूर्वक अनलोड हो गया';
  }

  @override
  String model_unload_failed(String error) {
    return 'मॉडल अनलोड करने में विफल: $error';
  }

  @override
  String get unload_from_server => 'सर्वर से अनलोड करें';

  @override
  String context_chip(String ctx) {
    return '$ctx संदर्भ (ctx)';
  }

  @override
  String download_notification_title(String modelName) {
    return '$modelName डाउनलोड किया जा रहा है...';
  }

  @override
  String get download_complete_notification => 'डाउनलोड पूर्ण!';

  @override
  String download_complete_body(String modelName) {
    return '$modelName सफलतापूर्वक डाउनलोड हो गया है।';
  }

  @override
  String download_failed_notification(String error) {
    return 'डाउनलोड विफल: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return '$modelName डाउनलोड करने में विफल।';
  }

  @override
  String get engine_name_system => 'सिस्टम TTS';

  @override
  String get engine_tagline_system => 'इन-बिल्ट डिवाइस इंजन';

  @override
  String get engine_name_kitten => 'Kitten TTS';

  @override
  String get engine_tagline_kitten => 'उच्च गति न्यूरल TTS';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => 'ऑफ़लाइन पाइपर (Piper) आवाज़ें';

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
      'सबसे छोटा सामान्य प्रयोजन चैट मॉडल। त्वरित प्रतिक्रियाएं, कम मेमोरी उपयोग।';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc =>
      'संतुलित गुणवत्ता और आकार। सामान्य बातचीत के लिए अच्छा है।';

  @override
  String get model_deepseek => 'DeepSeek R1 Distill Qwen 1.5B';

  @override
  String get model_deepseek_desc =>
      'तर्क और विचार-श्रृंखला मॉडल। तार्किक कार्यों के लिए सर्वोत्तम।';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc =>
      'गूगल का फ्लैगशिप मॉडल। उच्चतम गुणवत्ता, अधिक रैम की आवश्यकता है।';

  @override
  String export_header(String date) {
    return '*LocalMind से निर्यात किया गया — $date*';
  }

  @override
  String get export_role_user => '## 👤 उपयोगकर्ता';

  @override
  String get export_role_assistant => '## 🤖 सहायक';

  @override
  String get export_role_system => '## ⚙️ सिस्टम';

  @override
  String get export_role_tool => '## 🔧 उपकरण';

  @override
  String get export_text_user => '[उपयोगकर्ता]';

  @override
  String get export_text_assistant => '[सहायक]';

  @override
  String get export_text_system => '[सिस्टम]';

  @override
  String get export_text_tool => '[उपकरण]';

  @override
  String get export_label_user => 'उपयोगकर्ता';

  @override
  String get export_label_assistant => 'सहायक';

  @override
  String get export_label_system => 'सिस्टम';

  @override
  String get export_label_tool => 'उपकरण';

  @override
  String get select_model_hint => 'चैटिंग शुरू करने के लिए एक मॉडल चुनें';

  @override
  String get test_notification_title => 'परीक्षण सूचना';

  @override
  String get test_notification_body =>
      'यह मॉडल डाउनलोड प्रगति के लिए एक परीक्षण सूचना है।';
}
