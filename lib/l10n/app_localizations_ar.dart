// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => 'ذكاؤك. جهازك. قواعدك.';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get done => 'تم';

  @override
  String get continue_action => 'متابعة';

  @override
  String get skip => 'تخطي';

  @override
  String get install => 'تثبيت';

  @override
  String get download => 'تنزيل';

  @override
  String get resume => 'استئناف';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get stop => 'إيقاف';

  @override
  String get edit => 'تعديل';

  @override
  String get preview => 'معاينة';

  @override
  String get unload => 'تفريغ';

  @override
  String get load => 'تحميل';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get pin => 'تثبيت';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get share => 'مشاركة';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ!';

  @override
  String get copied_to_clipboard => 'تم النسخ إلى الحافظة';

  @override
  String get select => 'اختيار';

  @override
  String get active => 'نشط';

  @override
  String get all => 'الكل';

  @override
  String get none => 'لا شيء';

  @override
  String get none_selected => 'لم يتم اختيار شيء';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get error => 'خطأ';

  @override
  String get unknown_error => 'خطأ غير معروف';

  @override
  String get not_now => 'ليس الآن';

  @override
  String get enable => 'تفعيل';

  @override
  String get proceed_anyway => 'متابعة على أي حال';

  @override
  String get test_connection => 'اختبار الاتصال';

  @override
  String get testing => 'جارٍ الاختبار...';

  @override
  String get connection_successful => 'تم الاتصال بنجاح!';

  @override
  String get connection_failed => 'فشل الاتصال. تحقق من إعداداتك.';

  @override
  String get save_continue => 'حفظ ومتابعة';

  @override
  String get save_changes => 'حفظ التغييرات';

  @override
  String get finish_setup => 'إنهاء الإعداد';

  @override
  String get start_new_chat => 'بدء محادثة جديدة';

  @override
  String get cannot_undo => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get ram_warning => 'تحذير الذاكرة';

  @override
  String get recommended => 'موصى به';

  @override
  String get may_be_large => 'قد يكون كبيراً جداً لهذا الجهاز';

  @override
  String get calculating => 'جارٍ الحساب...';

  @override
  String get download_failed => 'فشل التنزيل';

  @override
  String get downloaded => 'تم التنزيل';

  @override
  String get not_downloaded => 'لم يتم التنزيل';

  @override
  String get installed => 'مثبت';

  @override
  String get not_installed => 'غير مثبت';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get thinking => 'تفكير';

  @override
  String get processing => 'جارٍ المعالجة...';

  @override
  String get initializing => 'جارٍ التهيئة...';

  @override
  String get ready => 'جاهز';

  @override
  String get preparing_app => 'جارٍ تجهيز التطبيق...';

  @override
  String get initializing_services => 'جارٍ تهيئة الخدمات...';

  @override
  String get configuring_server => 'جارٍ إعداد الخادم...';

  @override
  String get startup_failed => 'فشل بدء التشغيل';

  @override
  String get something_went_wrong => 'حدث خطأ ما';

  @override
  String get delete_model_title => 'حذف النموذج';

  @override
  String delete_model_body(String name) {
    return 'هل أنت متأكد من حذف $name؟';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return 'هل أنت متأكد من حذف $name؟ سيؤدي ذلك إلى تحرير مساحة تقارب $size.\n\nيمكنك تنزيل هذا النموذج مرة أخرى لاحقاً إذا احتجت إليه.';
  }

  @override
  String get delete_voice_title => 'حذف الصوت';

  @override
  String delete_voice_body(String name, String size) {
    return 'هل أنت متأكد من حذف $name؟ سيؤدي ذلك إلى تحرير مساحة تقارب $size.\n\nيمكنك تنزيل هذا الصوت مرة أخرى لاحقاً إذا احتجت إليه.';
  }

  @override
  String get delete_server_title => 'حذف الخادم';

  @override
  String delete_server_body(String name) {
    return 'هل أنت متأكد من حذف \"$name\"؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get delete_conversation_title => 'حذف المحادثة؟';

  @override
  String delete_conversation_body(String title) {
    return 'هل أنت متأكد من حذف \"$title\"؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get delete_message_title => 'حذف الرسالة؟';

  @override
  String delete_persona_title(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get delete_persona_body => 'لا يمكن التراجع عن هذا.';

  @override
  String get clear_conversation_title => 'مسح المحادثة؟';

  @override
  String get clear_conversation_body =>
      'سيؤدي هذا إلى حذف جميع الرسائل في هذه المحادثة.';

  @override
  String get clear => 'مسح';

  @override
  String label_completed(String label) {
    return 'اكتمل $label';
  }

  @override
  String error_with_message(String error) {
    return 'خطأ: $error';
  }

  @override
  String preview_failed(String error) {
    return 'فشلت المعاينة: $error';
  }

  @override
  String loading_model(String modelId) {
    return 'جارٍ تحميل $modelId...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return 'تم تحميل النموذج: $modelId ($backend)';
  }

  @override
  String get no_model_loaded =>
      'لم يتم تحميل أي نموذج. اضغط على \"إدارة النماذج المحلية\" لتنزيل وتحميل نموذج.';

  @override
  String loading_model_error(String error) {
    return 'خطأ: $error';
  }

  @override
  String get delete_conversation => 'حذف المحادثة؟';

  @override
  String get nav_history => 'السجل';

  @override
  String get nav_servers => 'الخوادم';

  @override
  String get nav_local_models => 'النماذج المحلية';

  @override
  String get nav_tts => 'تحويل النص إلى كلام';

  @override
  String get nav_personas => 'الشخصيات';

  @override
  String get nav_settings => 'الإعدادات';

  @override
  String get nav_new_chat => 'محادثة جديدة';

  @override
  String get search_hint => 'البحث في المحادثات...';

  @override
  String get no_server_selected => 'لم يتم تحديد خادم';

  @override
  String get switch_server => 'تغيير الخادم';

  @override
  String get switch_server_subtitle => 'اختر خادماً للاتصال به';

  @override
  String get manage_servers => 'إدارة الخوادم';

  @override
  String get open_source => 'مفتوح المصدر';

  @override
  String get open_source_desc =>
      'LocalMind هو تطبيق مفتوح المصدر. تابع تقدمنا أو ساهم على GitHub.';

  @override
  String get star_on_github => 'نجمة على GitHub';

  @override
  String get add_more => 'أضف المزيد';

  @override
  String get on_github => 'على GitHub';

  @override
  String get could_not_open_github => 'تعذر فتح GitHub.';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_appearance => 'المظهر';

  @override
  String get settings_language => 'اللغة';

  @override
  String get language_system_default => 'إعدادات النظام';

  @override
  String get settings_tts => 'تحويل النص إلى كلام';

  @override
  String get settings_behavior => 'السلوك';

  @override
  String get settings_on_device => 'الاستدلال المحلي';

  @override
  String get settings_default_server => 'الخادم الافتراضي';

  @override
  String get settings_default_persona => 'الشخصية الافتراضية';

  @override
  String get settings_privacy => 'الخصوصية';

  @override
  String get settings_data_management => 'إدارة البيانات';

  @override
  String get settings_about => 'حول';

  @override
  String get theme => 'السمة';

  @override
  String get theme_system => 'النظام';

  @override
  String get theme_light => 'فاتح';

  @override
  String get theme_dark => 'داكن';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => 'حجم الخط';

  @override
  String get font_size_desc => 'ضبط حجم النص في المحادثة.';

  @override
  String get font_preview => 'النص التجريبي لمعاينة حجم الخط الجديد.';

  @override
  String get code_theme_dark => 'سمة الكود (داكن)';

  @override
  String get code_theme_light => 'سمة الكود (فاتح)';

  @override
  String get code_theme_desc => 'اختر سمة تمييز الصياغة لكتل الأكواد.';

  @override
  String get tts_engine => 'محرك تحويل النص إلى كلام';

  @override
  String get tts_engine_system => 'محرك النظام';

  @override
  String get tts_engine_kitten => 'Kitten TTS';

  @override
  String get voice => 'الصوت';

  @override
  String get voice_female => 'أنثى';

  @override
  String get voice_male => 'ذكر';

  @override
  String get voice_other => 'آخر';

  @override
  String get tts_speed => 'سرعة القراءة';

  @override
  String get tts_speed_desc => 'ضبط معدل التشغيل.';

  @override
  String get manage_tts_models => 'إدارة نماذج TTS';

  @override
  String get manage_on_device_models => 'إدارة النماذج المحلية';

  @override
  String get enable_smart_reply => 'الردود الذكية المحلية';

  @override
  String get streaming_responses => 'الردود المتدفقة';

  @override
  String get auto_generate_titles => 'إنشاء العناوين تلقائياً';

  @override
  String get send_on_enter => 'إرسال عند الضغط على Enter';

  @override
  String get show_system_messages => 'إظهار رسائل النظام';

  @override
  String get haptic_feedback => 'الاستجابة اللمسية';

  @override
  String get enable_mcp => 'تفعيل MCP';

  @override
  String get new_chat_mcp_default => 'تفعيل MCP افتراضياً في المحادثات الجديدة';

  @override
  String get show_data_indicator => 'إظهار مؤشر البيانات';

  @override
  String get privacy_info => '\"LocalMind لا يطلع على بياناتك أبداً\"';

  @override
  String get delete_all_conversations => 'حذف جميع المحادثات';

  @override
  String get reset_settings_defaults => 'إعادة الإعدادات إلى الوضع الافتراضي';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => 'معلمات المحادثة';

  @override
  String get change_persona => 'تغيير الشخصية';

  @override
  String get set_persona => 'تعيين شخصية';

  @override
  String get remove_persona => 'إزالة الشخصية';

  @override
  String get clear_conversation => 'مسح المحادثة';

  @override
  String get connection_error => 'خطأ في الاتصال. تحقق من الخادم الخاص بك.';

  @override
  String get disconnected => 'تم قطع الاتصال بالخادم.';

  @override
  String get configure => 'إعداد';

  @override
  String get select_model => 'اختيار نموذج';

  @override
  String get select_persona => 'اختيار شخصية';

  @override
  String get start_conversation => 'ابدأ محادثة';

  @override
  String get recent_chats => 'المحادثات الأخيرة';

  @override
  String get see_all => 'عرض الكل';

  @override
  String get quick_write => 'ساعدني في كتابة دالة';

  @override
  String get quick_explain => 'اشرح هذا الكود';

  @override
  String get quick_debug => 'صحح لي هذا الخطأ';

  @override
  String get quick_async => 'كيف أستخدم async/await؟';

  @override
  String get history_missing_title => 'السجل مفقود';

  @override
  String get history_missing_desc =>
      'إما أن رسائل هذه المحادثة قد حُذفت أو أن سجل المحادثة تالف.';

  @override
  String get technical_details => 'التفاصيل التقنية';

  @override
  String get last_error => 'آخر خطأ:';

  @override
  String get copy_info => 'نسخ المعلومات';

  @override
  String get conversation_id => 'معرف المحادثة';

  @override
  String get created_at => 'تاريخ الإنشاء';

  @override
  String get expected_messages => 'الرسائل المتوقعة';

  @override
  String get debug_dialog_desc =>
      'معلومات تشخيصية للمساعدة في تحديد مشاكل المزامنة.';

  @override
  String get chat_input_hint => 'اسأل أي شيء';

  @override
  String get send_message_tooltip => 'إرسال الرسالة';

  @override
  String get stop_generation_tooltip => 'إيقاف التوليد';

  @override
  String get attach_images_tooltip => 'إرفاق صور';

  @override
  String get start_listening_tooltip => 'بدء الاستماع';

  @override
  String get stop_listening_tooltip => 'إيقاف الاستماع';

  @override
  String tool_label(String toolCallId) {
    return 'أداة: $toolCallId';
  }

  @override
  String get tool_unknown => 'أداة: غير معروفة';

  @override
  String get message_options => 'خيارات الرسالة';

  @override
  String get copy_markdown => 'نسخ كـ Markdown';

  @override
  String get copied_markdown => 'تم النسخ كـ Markdown';

  @override
  String get read_aloud => 'القراءة بصوت عالٍ';

  @override
  String get stop_reading => 'إيقاف القراءة';

  @override
  String get more => 'المزيد';

  @override
  String character_count(int length) {
    return '$length حرف';
  }

  @override
  String get edit_message => 'تعديل الرسالة';

  @override
  String get edit_message_desc =>
      'سيؤدي الحفظ إلى إزالة رد المساعد أدناه وإعادة التوليد.';

  @override
  String get save_regenerate => 'حفظ وإعادة التوليد';

  @override
  String get chat_settings_title => 'إعدادات المحادثة';

  @override
  String get reset_defaults => 'إعادة الإعدادات الافتراضية';

  @override
  String get parameters_tab => 'المعلمات';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get temperature_desc =>
      'التحكم في العشوائية: أعلى = إبداعي، أقل = مركز';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => 'حد أخذ العينات النووي';

  @override
  String get max_tokens => 'الحد الأقصى للرموز';

  @override
  String get max_tokens_desc => 'حد الاستجابة';

  @override
  String get context_length => 'طول السياق';

  @override
  String get context_length_desc => 'نافذة السجل';

  @override
  String get mcp_disabled_warning =>
      'MCP معطل عالمياً. فعّله في الإعدادات لاستخدام هذه الميزات.';

  @override
  String get mcp_enable_chat => 'تفعيل MCP لهذه المحادثة';

  @override
  String get auto_execute_tools => 'تشغيل الأدوات تلقائياً';

  @override
  String get beta_label => 'تجريبي';

  @override
  String get experimental_label => 'اختباري';

  @override
  String get add_ephemeral_mcp => 'إضافة خادم MCP مؤقت';

  @override
  String get mcp_label_placeholder => 'التسمية';

  @override
  String get mcp_url_placeholder => 'الرابط (https://...)';

  @override
  String get active_integrations => 'التكاملات النشطة';

  @override
  String get enable_notifications => 'تفعيل الإشعارات';

  @override
  String get enable_notifications_desc =>
      'احصل على إشعار عند اكتمال تنزيل النماذج.';

  @override
  String get chat_history_title => 'سجل المحادثات';

  @override
  String get conversation_just_now => 'الآن';

  @override
  String conversation_minutes_ago(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String conversation_hours_ago(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String get conversation_yesterday => 'أمس';

  @override
  String conversation_days_ago(int days) {
    return 'منذ $days يوم';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$year/$month/$day';
  }

  @override
  String get options_tooltip => 'خيارات';

  @override
  String get no_results_found => 'لا توجد نتائج';

  @override
  String get no_conversations_yet => 'لا توجد محادثات بعد';

  @override
  String get try_different_search => 'جرّب مصطلح بحث مختلف';

  @override
  String get start_new_conversation => 'ابدأ محادثة جديدة';

  @override
  String get rename_conversation => 'إعادة تسمية المحادثة';

  @override
  String get enter_new_title => 'أدخل عنواناً جديداً';

  @override
  String get pinned_section => 'مثبت';

  @override
  String get today_section => 'اليوم';

  @override
  String get yesterday_section => 'أمس';

  @override
  String get previous_7_days => 'آخر 7 أيام';

  @override
  String get previous_30_days => 'آخر 30 يوماً';

  @override
  String get older_section => 'الأقدم';

  @override
  String get onboarding_choose_language => 'اختر اللغة';

  @override
  String get onboarding_choose_language_desc =>
      'اختر لغتك المفضلة. يمكنك تغيير هذا في أي وقت من الإعدادات.';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => 'اتصل\nبخادمك';

  @override
  String get onboarding_connect_desc =>
      'اتصل بـ LM Studio أو Ollama أو\nOpenRouter لبدء تجربة الذكاء\nالاصطناعي الخاصة بك.';

  @override
  String get openai_compatible_api => 'واجهة متوافقة مع OpenAI';

  @override
  String get https_requires_ssl => 'يتطلب HTTPS استخدام SSL';

  @override
  String get most_local_setups_use_http =>
      'تستخدم معظم الإعدادات المحلية http://';

  @override
  String get onboarding_welcome => 'مرحباً بك في LocalMind';

  @override
  String get server_type_on_device => 'محلي';

  @override
  String get server_type_on_device_sub => 'لا يحتاج خادماً';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => 'API محلي';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'محرك أوامر';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => 'سحابة موحدة';

  @override
  String get ready_continue => 'جاهز للمتابعة';

  @override
  String get waiting_selection => 'بانتظار الاختيار';

  @override
  String get setup_connection => 'إعداد الاتصال';

  @override
  String setup_connection_desc(String server) {
    return 'قم بإعداد خادم $server لبدء المحادثة.';
  }

  @override
  String get server_name => 'اسم الخادم';

  @override
  String get name_required => 'الاسم مطلوب';

  @override
  String get name_max_50 => 'الحد الأقصى 50 حرفاً';

  @override
  String get host_label => 'المضيف / عنوان IP';

  @override
  String get host_required => 'المضيف مطلوب';

  @override
  String get port_label => 'المنفذ';

  @override
  String get port_required => 'المنفذ مطلوب';

  @override
  String get port_invalid => 'يجب أن يكون رقماً';

  @override
  String get port_range => 'أدخل منفذاً صالحاً (1-65535)';

  @override
  String get api_key_required => 'مفتاح API *';

  @override
  String get api_key_optional => 'مفتاح API (اختياري)';

  @override
  String get api_key_required_openrouter => 'مفتاح API مطلوب لـ OpenRouter';

  @override
  String get api_key_format => 'مفاتيح OpenRouter API تبدأ بـ sk-';

  @override
  String get my_server_hint => 'خادمي';

  @override
  String get name_length_validation => 'يجب ألا يتجاوز الاسم 50 حرفاً';

  @override
  String get host_valid => 'أدخل اسماً مضيفاً أو عنوان IP صالحاً';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => 'للخوادم الموثقة';

  @override
  String get update_server => 'تحديث الخادم';

  @override
  String get save_server => 'حفظ الخادم';

  @override
  String get server_updated => 'تم تحديث الخادم';

  @override
  String get server_added => 'تمت إضافة الخادم';

  @override
  String get download_model_title => 'تنزيل نموذج';

  @override
  String get download_model_desc =>
      'اختر نموذجاً للتنزيل.\nسيتم تشغيله محلياً على جهازك.';

  @override
  String get on_device_android_only =>
      'الاستدلال المحلي متاح حالياً على Android فقط.';

  @override
  String get total_ram => 'إجمالي الذاكرة';

  @override
  String get available => 'متاح';

  @override
  String ram_min_required(String fileSize) {
    return '$fileSize جيجابايت ذاكرة كحد أدنى';
  }

  @override
  String download_progress(String percent, String speed) {
    return '$percent% • $speed';
  }

  @override
  String eta_label(String eta) {
    return 'الوقت المتبقي: $eta';
  }

  @override
  String paused_progress(String percent) {
    return 'متوقف مؤقتاً - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return 'هذا النموذج يتطلب $ram جيجابايت ذاكرة على الأقل، ولكن جهازك يحتوي على $totalMemory. قد لا يعمل بشكل صحيح أو قد يتسبب في تعطل التطبيق.';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return 'جهازك يحتوي على $availableRAM ذاكرة متاحة، لكن هذا النموذج يوصي بـ $ram جيجابايت على الأقل. قد يفشل تحميله أو يسبب عدم استقرار.';
  }

  @override
  String get choose_theme => 'اختر السمة';

  @override
  String get choose_theme_desc =>
      'خصص مظهر التطبيق. يمكنك دائماً تغيير هذا لاحقاً في الإعدادات.';

  @override
  String get theme_card_system => 'النظام';

  @override
  String get theme_card_system_sub => 'يطابق إعدادات جهازك';

  @override
  String get theme_card_light => 'فاتح';

  @override
  String get theme_card_light_sub => 'نظيف ومشرق';

  @override
  String get theme_card_dark => 'داكن';

  @override
  String get theme_card_dark_sub => 'مريح للعينين';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => 'سمة دافئة بلون الخوخ';

  @override
  String get stay_updated => 'ابق على اطلاع';

  @override
  String get stay_updated_desc =>
      'احصل على إشعارات عند اكتمال تنزيل نماذج الذكاء الاصطناعي أو عند انتهاء المهام الطويلة.';

  @override
  String get notification_benefit_downloads => 'تقدم تنزيل النماذج';

  @override
  String get notification_benefit_completions => 'اكتمال التوليد';

  @override
  String get notification_benefit_background => 'حالة المهام الخلفية';

  @override
  String get allow_notifications => 'السماح بالإشعارات';

  @override
  String get servers_title => 'الخوادم';

  @override
  String get no_servers_yet => 'لا توجد خوادم بعد';

  @override
  String get no_servers_desc =>
      'أضف خادمك الأول لبدء المحادثة مع نماذج الذكاء الاصطناعي.';

  @override
  String get add_server => 'إضافة خادم';

  @override
  String switched_to_server(String name) {
    return 'تم التبديل إلى $name';
  }

  @override
  String get edit_server => 'تعديل الخادم';

  @override
  String get add_server_title => 'إضافة خادم';

  @override
  String get server_type_label => 'نوع الخادم';

  @override
  String get server_icon_label => 'أيقونة الخادم';

  @override
  String get default_icon => 'الأيقونة الافتراضية';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => 'متوافق مع OpenAI';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => 'محلي';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => 'استدلال محلي';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => 'افتراضي';

  @override
  String get set_as_default => 'تعيين كافتراضي';

  @override
  String get select_icon => 'اختيار أيقونة';

  @override
  String get select_icon_desc => 'اختر أيقونة لخادمك';

  @override
  String get search_icons_hint => 'البحث في الأيقونات...';

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
  String get personas_title => 'الشخصيات';

  @override
  String get persona_category_general => 'عام';

  @override
  String get persona_category_coding => 'برمجة';

  @override
  String get persona_category_education => 'تعليم';

  @override
  String get persona_category_creative => 'إبداعي';

  @override
  String get persona_builtin_section => 'مضمنة';

  @override
  String get persona_my_section => 'شخصياتي';

  @override
  String get clone_edit => 'نسخ وتعديل';

  @override
  String get builtin_badge => 'مضمنة';

  @override
  String get no_personas_found => 'لم يتم العثور على شخصيات';

  @override
  String get no_personas_desc =>
      'أنشئ شخصيتك الأولى لتخصيص سلوك الذكاء الاصطناعي.';

  @override
  String get edit_persona => 'تعديل الشخصية';

  @override
  String get create_persona => 'إنشاء شخصية';

  @override
  String get create_persona_button => 'إنشاء';

  @override
  String get emoji_label => 'رمز تعبيري';

  @override
  String get name_label => 'الاسم';

  @override
  String get my_persona_hint => 'شخصيتي';

  @override
  String get category_label => 'الفئة';

  @override
  String get description_optional => 'الوصف (اختياري)';

  @override
  String get description_hint => 'ماذا تفعل هذه الشخصية...';

  @override
  String get system_prompt => 'موجه النظام';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => 'لا يوجد موجه بعد...';

  @override
  String get prompt_hint => 'أنت مساعد مفيد...';

  @override
  String get prompt_required => 'موجه النظام مطلوب';

  @override
  String get prompt_max_chars => 'الحد الأقصى 4000 حرف';

  @override
  String get advanced_settings => 'الإعدادات المتقدمة';

  @override
  String get temperature_label => 'درجة الحرارة (0.0-2.0)';

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
  String get persona_updated => 'تم تحديث الشخصية';

  @override
  String get persona_created => 'تم إنشاء الشخصية';

  @override
  String get tts_models_title => 'نماذج تحويل النص إلى كلام';

  @override
  String get always_available => 'متاح دائماً';

  @override
  String get tts_system_desc =>
      'يستخدم محرك تحويل النص إلى كلام المدمج في جهازك.\nلا يتطلب أي تنزيلات. اختيار الصوت يستخدم إعدادات نظام جهازك.';

  @override
  String get downloading_status => 'جارٍ التنزيل...';

  @override
  String tts_kitten_desc(String size) {
    return 'TTS عصبي فائق السرعة مع 8 أصوات معبرة.\nيتطلب تنزيل $size.';
  }

  @override
  String tts_piper_desc(String size) {
    return 'أصوات Piper سريعة دون اتصال مع صوتين معبرين.\nيتطلب تنزيل $size لكل صوت.';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb ميجابايت · $ramMb ميجابايت ذاكرة · $voiceCount أصوات';
  }

  @override
  String get on_device_models_title => 'النماذج المحلية';

  @override
  String get available_models => 'النماذج المتاحة';

  @override
  String get device_memory => 'ذاكرة الجهاز';

  @override
  String get ram_usage => 'استخدام الذاكرة';

  @override
  String get memory_healthy => 'جيد';

  @override
  String get memory_critical => 'حرج';

  @override
  String get memory_low => 'منخفض';

  @override
  String ram_used(String percent) {
    return '$percent% مستخدم';
  }

  @override
  String get available_ram => 'الذاكرة المتاحة';

  @override
  String get total_capacity => 'السعة الإجمالية';

  @override
  String get loaded_status => 'تم التحميل';

  @override
  String get inference_backend => 'محطة الاستدلال';

  @override
  String get backend_ios_notice => 'محطة CPU فقط متاحة على iOS.';

  @override
  String get backend_cpu_desc => 'يعمل على جميع الأجهزة. الأكثر توافقاً.';

  @override
  String get backend_gpu_desc => 'تسريع OpenCL. أسرع على الأجهزة المدعومة.';

  @override
  String get backend_npu_desc =>
      'NPU من الشركة المصنعة (Qualcomm/MediaTek). أسرع استدلال.';

  @override
  String get select_model_title => 'اختيار نموذج';

  @override
  String get refresh_models => 'تحديث النماذج';

  @override
  String get search_models_hint => 'البحث في النماذج...';

  @override
  String get no_server_connected => 'لا يوجد خادم متصل';

  @override
  String get add_server_first => 'أضف خادماً أولاً لرؤية النماذج المتاحة.';

  @override
  String get failed_load_models => 'فشل تحميل النماذج';

  @override
  String get no_models_available => 'لا توجد نماذج متاحة';

  @override
  String no_models_match(String searchQuery) {
    return 'لا توجد نماذج تطابق \"$searchQuery\"';
  }

  @override
  String model_load_failed(String error) {
    return 'فشل تحميل النموذج: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return 'سيتم تفريغ $name بعد انتهاء وقت الاحتفاظ';
  }

  @override
  String model_unloaded_success(String name) {
    return 'تم تفريغ $name بنجاح';
  }

  @override
  String model_unload_failed(String error) {
    return 'فشل تفريغ النموذج: $error';
  }

  @override
  String get unload_from_server => 'تفريغ من الخادم';

  @override
  String context_chip(String ctx) {
    return '$ctx سياق';
  }

  @override
  String download_notification_title(String modelName) {
    return 'جارٍ تنزيل $modelName...';
  }

  @override
  String get download_complete_notification => 'اكتمل التنزيل!';

  @override
  String download_complete_body(String modelName) {
    return 'تم تنزيل $modelName بنجاح.';
  }

  @override
  String download_failed_notification(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return 'فشل تنزيل $modelName.';
  }

  @override
  String get engine_name_system => 'TTS النظام';

  @override
  String get engine_tagline_system => 'محرك الجهاز المدمج';

  @override
  String get engine_name_kitten => 'Kitten TTS';

  @override
  String get engine_tagline_kitten => 'TTS عصبي عالي السرعة';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => 'أصوات Piper دون اتصال';

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
  String get voice_lessac => 'Lessac (أمريكي)';

  @override
  String get voice_ryan => 'Ryan (أمريكي)';

  @override
  String get model_qwen_3 => 'Qwen 3 0.6B';

  @override
  String get model_qwen_3_desc =>
      'أصغر نموذج محادثة عام. استجابات سريعة، استخدام منخفض للذاكرة.';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc => 'جودة وحجم متوازنان. مناسب للمحادثة العامة.';

  @override
  String get model_deepseek => 'DeepSeek R1 Distill Qwen 1.5B';

  @override
  String get model_deepseek_desc =>
      'نموذج استدلال وسلسلة أفكار. الأفضل للمهام المنطقية.';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc =>
      'نموذج Google الرائد. أعلى جودة، يتطلب ذاكرة أكبر.';

  @override
  String export_header(String date) {
    return '*تم التصدير من LocalMind — $date*';
  }

  @override
  String get export_role_user => '## 👤 المستخدم';

  @override
  String get export_role_assistant => '## 🤖 المساعد';

  @override
  String get export_role_system => '## ⚙️ النظام';

  @override
  String get export_role_tool => '## 🔧 الأداة';

  @override
  String get export_text_user => '[المستخدم]';

  @override
  String get export_text_assistant => '[المساعد]';

  @override
  String get export_text_system => '[النظام]';

  @override
  String get export_text_tool => '[الأداة]';

  @override
  String get export_label_user => 'المستخدم';

  @override
  String get export_label_assistant => 'المساعد';

  @override
  String get export_label_system => 'النظام';

  @override
  String get export_label_tool => 'الأداة';

  @override
  String get select_model_hint => 'اختر نموذجاً لبدء المحادثة';

  @override
  String get test_notification_title => 'إشعار تجريبي';

  @override
  String get test_notification_body => 'هذا إشعار تجريبي لتقدم تنزيل النموذج.';

  @override
  String get tts_supports_background => 'يدعم التشغيل في الخلفية كصوت أصلي';

  @override
  String get tts_other_services_background_note =>
      'ملاحظة: تدعم خدمات TTS الأخرى التشغيل في الخلفية كصوت أصلي.';
}
