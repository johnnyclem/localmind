import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('zh'),
  ];

  /// Application display name
  ///
  /// In en, this message translates to:
  /// **'LocalMind'**
  String get app_name;

  /// Application tagline shown in settings and splash
  ///
  /// In en, this message translates to:
  /// **'Your AI. Your Device. Your Rules.'**
  String get app_tagline;

  /// Application version number
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get app_version;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_action;

  /// Generic skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Install action button
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Download action button
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Resume download button
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Pause download button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Stop action button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Edit action label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Preview action label
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Unload model action
  ///
  /// In en, this message translates to:
  /// **'Unload'**
  String get unload;

  /// Load model action
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// Rename action label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Pin conversation action
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// Unpin conversation action
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// Share action label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy action label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Copied confirmation text
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// Snackbar message after copy
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied_to_clipboard;

  /// Select action button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Active status badge
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// All filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No selection label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Dropdown placeholder when nothing selected
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get none_selected;

  /// Connection status online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Connection status offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Error status text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Fallback unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknown_error;

  /// Dismiss action for notifications
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get not_now;

  /// Enable action button
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// Proceed despite warning
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceed_anyway;

  /// Button to test server connection
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get test_connection;

  /// Button label while testing connection
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// Connection test success message
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connection_successful;

  /// Connection test failure message
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your settings.'**
  String get connection_failed;

  /// Save and proceed button
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get save_continue;

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// Complete onboarding button
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finish_setup;

  /// Button to start a new chat
  ///
  /// In en, this message translates to:
  /// **'Start New Chat'**
  String get start_new_chat;

  /// Warning for destructive actions
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannot_undo;

  /// RAM warning dialog title
  ///
  /// In en, this message translates to:
  /// **'RAM Warning'**
  String get ram_warning;

  /// Recommended badge on model cards
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommended;

  /// Warning when model may exceed device RAM
  ///
  /// In en, this message translates to:
  /// **'May be too large for this device'**
  String get may_be_large;

  /// ETA placeholder during download
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// Download failure status
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get download_failed;

  /// Download completed status
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// Model not yet downloaded
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get not_downloaded;

  /// Installed status
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// Not installed status
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get not_installed;

  /// Generic loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Model thinking indicator
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinking;

  /// Processing indicator text
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Initializing status
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// Ready status text
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// Bootstrap stage message
  ///
  /// In en, this message translates to:
  /// **'Preparing app...'**
  String get preparing_app;

  /// Bootstrap stage message
  ///
  /// In en, this message translates to:
  /// **'Initializing services...'**
  String get initializing_services;

  /// Bootstrap stage message
  ///
  /// In en, this message translates to:
  /// **'Configuring server...'**
  String get configuring_server;

  /// Bootstrap error message
  ///
  /// In en, this message translates to:
  /// **'Startup failed'**
  String get startup_failed;

  /// Generic error heading on bootstrap screen
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong;

  /// Delete model dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get delete_model_title;

  /// Delete model confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String delete_model_body(String name);

  /// Delete model dialog body with size info
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This will free up approximately {size} of space.\n\nYou can download this model again later if needed.'**
  String delete_model_body_with_size(String name, String size);

  /// Delete voice confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Voice'**
  String get delete_voice_title;

  /// Delete voice confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This will free up approximately {size} of space.\n\nYou can download this voice again later if needed.'**
  String delete_voice_body(String name, String size);

  /// Delete server confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Server'**
  String get delete_server_title;

  /// Delete server confirmation body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String delete_server_body(String name);

  /// Delete conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get delete_conversation_title;

  /// Delete conversation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String delete_conversation_body(String title);

  /// Delete message dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get delete_message_title;

  /// Delete persona dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String delete_persona_title(String name);

  /// Delete persona dialog body
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get delete_persona_body;

  /// Clear conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear conversation?'**
  String get clear_conversation_title;

  /// Clear conversation confirmation body
  ///
  /// In en, this message translates to:
  /// **'This will delete all messages in this conversation.'**
  String get clear_conversation_body;

  /// Clear action button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Completion status message
  ///
  /// In en, this message translates to:
  /// **'{label} completed'**
  String label_completed(String label);

  /// Error display with message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_with_message(String error);

  /// Audio preview failed message
  ///
  /// In en, this message translates to:
  /// **'Preview failed: {error}'**
  String preview_failed(String error);

  /// Model loading status
  ///
  /// In en, this message translates to:
  /// **'Loading {modelId}...'**
  String loading_model(String modelId);

  /// Model loaded status in settings
  ///
  /// In en, this message translates to:
  /// **'Model loaded: {modelId} ({backend})'**
  String model_loaded(String modelId, String backend);

  /// Status when no on-device model is loaded
  ///
  /// In en, this message translates to:
  /// **'No model loaded. Tap \"Manage On-Device Models\" to download and load a model.'**
  String get no_model_loaded;

  /// Model loading error status
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String loading_model_error(String error);

  /// Delete conversation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get delete_conversation;

  /// Navigation item for chat history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get nav_history;

  /// Navigation item for servers
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get nav_servers;

  /// Navigation item for local on-device models
  ///
  /// In en, this message translates to:
  /// **'Local Models'**
  String get nav_local_models;

  /// Navigation item for TTS models
  ///
  /// In en, this message translates to:
  /// **'Text To Speech'**
  String get nav_tts;

  /// Navigation item for personas
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get nav_personas;

  /// Navigation item for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// Button to start a new chat
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get nav_new_chat;

  /// Search field placeholder for conversations
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get search_hint;

  /// Placeholder when no server is selected
  ///
  /// In en, this message translates to:
  /// **'No server selected'**
  String get no_server_selected;

  /// Switch server sheet title
  ///
  /// In en, this message translates to:
  /// **'Switch Server'**
  String get switch_server;

  /// Switch server sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose a server to connect to'**
  String get switch_server_subtitle;

  /// Button to manage servers list
  ///
  /// In en, this message translates to:
  /// **'Manage Servers'**
  String get manage_servers;

  /// GitHub repo card title
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get open_source;

  /// GitHub repo card description
  ///
  /// In en, this message translates to:
  /// **'LocalMind is open source. Follow our progress or contribute on GitHub.'**
  String get open_source_desc;

  /// Button to star repo on GitHub
  ///
  /// In en, this message translates to:
  /// **'Star on GitHub'**
  String get star_on_github;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Settings section header for appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// Settings section label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// Option to use the device's system language
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get language_system_default;

  /// Settings section header for TTS
  ///
  /// In en, this message translates to:
  /// **'Text-to-Speech'**
  String get settings_tts;

  /// Settings section header for behavior
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get settings_behavior;

  /// Settings section header for on-device
  ///
  /// In en, this message translates to:
  /// **'On-Device Inference'**
  String get settings_on_device;

  /// Settings section header for default server
  ///
  /// In en, this message translates to:
  /// **'Default Server'**
  String get settings_default_server;

  /// Settings section header for default persona
  ///
  /// In en, this message translates to:
  /// **'Default Persona'**
  String get settings_default_persona;

  /// Settings section header for privacy
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settings_privacy;

  /// Settings section header for data management
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settings_data_management;

  /// Settings section header for about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// Theme selection label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// Claude theme option
  ///
  /// In en, this message translates to:
  /// **'Claude'**
  String get theme_claude;

  /// Font size slider label
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get font_size;

  /// Font size setting description
  ///
  /// In en, this message translates to:
  /// **'Adjust text size in chat.'**
  String get font_size_desc;

  /// Font preview sample text
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog.'**
  String get font_preview;

  /// Dark code theme dropdown label
  ///
  /// In en, this message translates to:
  /// **'Code Theme (Dark)'**
  String get code_theme_dark;

  /// Light code theme dropdown label
  ///
  /// In en, this message translates to:
  /// **'Code Theme (Light)'**
  String get code_theme_light;

  /// Code theme setting description
  ///
  /// In en, this message translates to:
  /// **'Choose syntax highlighting theme for code blocks.'**
  String get code_theme_desc;

  /// TTS engine dropdown label
  ///
  /// In en, this message translates to:
  /// **'TTS Engine'**
  String get tts_engine;

  /// System TTS engine option
  ///
  /// In en, this message translates to:
  /// **'System TTS'**
  String get tts_engine_system;

  /// Kitten TTS engine option
  ///
  /// In en, this message translates to:
  /// **'Kitten TTS'**
  String get tts_engine_kitten;

  /// Voice selection label
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// Female voice gender label
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get voice_female;

  /// Male voice gender label
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get voice_male;

  /// Other voice gender label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get voice_other;

  /// TTS speed slider label
  ///
  /// In en, this message translates to:
  /// **'TTS Speed'**
  String get tts_speed;

  /// TTS speed setting description
  ///
  /// In en, this message translates to:
  /// **'Adjust the playback rate.'**
  String get tts_speed_desc;

  /// Button to manage TTS models
  ///
  /// In en, this message translates to:
  /// **'Manage TTS Models'**
  String get manage_tts_models;

  /// Button to manage on-device models
  ///
  /// In en, this message translates to:
  /// **'Manage On-Device Models'**
  String get manage_on_device_models;

  /// Toggle for on-device smart reply suggestions
  ///
  /// In en, this message translates to:
  /// **'On-Device Smart Replies'**
  String get enable_smart_reply;

  /// Toggle for streaming responses
  ///
  /// In en, this message translates to:
  /// **'Streaming Responses'**
  String get streaming_responses;

  /// Toggle for auto-generating conversation titles
  ///
  /// In en, this message translates to:
  /// **'Auto-generate Titles'**
  String get auto_generate_titles;

  /// Toggle for send on enter behavior
  ///
  /// In en, this message translates to:
  /// **'Send on Enter'**
  String get send_on_enter;

  /// Toggle for system messages visibility
  ///
  /// In en, this message translates to:
  /// **'Show System Messages'**
  String get show_system_messages;

  /// Toggle for haptic feedback
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get haptic_feedback;

  /// Toggle for MCP feature
  ///
  /// In en, this message translates to:
  /// **'Enable MCP'**
  String get enable_mcp;

  /// Toggle for MCP default in new chats
  ///
  /// In en, this message translates to:
  /// **'New Chat MCP Default'**
  String get new_chat_mcp_default;

  /// Toggle for data indicator visibility
  ///
  /// In en, this message translates to:
  /// **'Show Data Indicator'**
  String get show_data_indicator;

  /// Privacy information text
  ///
  /// In en, this message translates to:
  /// **'\"LocalMind never sees your data\"'**
  String get privacy_info;

  /// Dangerous action button to clear all conversations
  ///
  /// In en, this message translates to:
  /// **'Delete All Conversations'**
  String get delete_all_conversations;

  /// Button to reset all settings
  ///
  /// In en, this message translates to:
  /// **'Reset Settings to Defaults'**
  String get reset_settings_defaults;

  /// Fallback chat screen title
  ///
  /// In en, this message translates to:
  /// **'LocalMind'**
  String get chat_title;

  /// Tooltip for chat parameters button
  ///
  /// In en, this message translates to:
  /// **'Chat Parameters'**
  String get chat_parameters_tooltip;

  /// Menu item to change persona
  ///
  /// In en, this message translates to:
  /// **'Change Persona'**
  String get change_persona;

  /// Menu item to set persona
  ///
  /// In en, this message translates to:
  /// **'Set Persona'**
  String get set_persona;

  /// Menu item to remove persona
  ///
  /// In en, this message translates to:
  /// **'Remove Persona'**
  String get remove_persona;

  /// Menu item to clear conversation
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation'**
  String get clear_conversation;

  /// Connection error banner text
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your server.'**
  String get connection_error;

  /// Disconnected banner text
  ///
  /// In en, this message translates to:
  /// **'Disconnected from server.'**
  String get disconnected;

  /// Configure action button
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// Model selection placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get select_model;

  /// Persona selection sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Persona'**
  String get select_persona;

  /// Empty state heading
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get start_conversation;

  /// Recent chats section label
  ///
  /// In en, this message translates to:
  /// **'Recent chats'**
  String get recent_chats;

  /// See all link text
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get see_all;

  /// Quick prompt chip text
  ///
  /// In en, this message translates to:
  /// **'Help me write a function'**
  String get quick_write;

  /// Quick prompt chip text
  ///
  /// In en, this message translates to:
  /// **'Explain this code'**
  String get quick_explain;

  /// Quick prompt chip text
  ///
  /// In en, this message translates to:
  /// **'Debug this for me'**
  String get quick_debug;

  /// Quick prompt chip text
  ///
  /// In en, this message translates to:
  /// **'How do I use async/await?'**
  String get quick_async;

  /// Corrupted chat error title
  ///
  /// In en, this message translates to:
  /// **'History Missing'**
  String get history_missing_title;

  /// Corrupted chat error description
  ///
  /// In en, this message translates to:
  /// **'Either the messages in this chat were deleted or the history record is corrupted.'**
  String get history_missing_desc;

  /// Button for debug details
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get technical_details;

  /// Diagnostic label
  ///
  /// In en, this message translates to:
  /// **'Last Error:'**
  String get last_error;

  /// Button to copy debug info
  ///
  /// In en, this message translates to:
  /// **'Copy Info'**
  String get copy_info;

  /// Debug row label
  ///
  /// In en, this message translates to:
  /// **'Conversation ID'**
  String get conversation_id;

  /// Debug row label
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get created_at;

  /// Debug row label
  ///
  /// In en, this message translates to:
  /// **'Expected Messages'**
  String get expected_messages;

  /// Debug dialog description
  ///
  /// In en, this message translates to:
  /// **'Diagnostic information to help identify synchronization issues.'**
  String get debug_dialog_desc;

  /// Chat input field hint
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get chat_input_hint;

  /// Tooltip for send button
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get send_message_tooltip;

  /// Tooltip for stop button
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get stop_generation_tooltip;

  /// Tooltip for attach button
  ///
  /// In en, this message translates to:
  /// **'Attach images'**
  String get attach_images_tooltip;

  /// Tool call label in chat bubble
  ///
  /// In en, this message translates to:
  /// **'Tool: {toolCallId}'**
  String tool_label(String toolCallId);

  /// Unknown tool call fallback
  ///
  /// In en, this message translates to:
  /// **'Tool: Unknown'**
  String get tool_unknown;

  /// Message actions sheet title
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get message_options;

  /// Copy as markdown option
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get copy_markdown;

  /// Copied as markdown snackbar
  ///
  /// In en, this message translates to:
  /// **'Copied as Markdown'**
  String get copied_markdown;

  /// Read aloud action
  ///
  /// In en, this message translates to:
  /// **'Read Aloud'**
  String get read_aloud;

  /// Stop reading action
  ///
  /// In en, this message translates to:
  /// **'Stop Reading'**
  String get stop_reading;

  /// More actions label
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Character count display
  ///
  /// In en, this message translates to:
  /// **'{length} characters'**
  String character_count(int length);

  /// Edit message dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get edit_message;

  /// Edit message dialog description
  ///
  /// In en, this message translates to:
  /// **'Saving will remove the assistant response below and regenerate.'**
  String get edit_message_desc;

  /// Save and regenerate button
  ///
  /// In en, this message translates to:
  /// **'Save & regenerate'**
  String get save_regenerate;

  /// Chat settings sheet title
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chat_settings_title;

  /// Reset to defaults button
  ///
  /// In en, this message translates to:
  /// **'Reset Defaults'**
  String get reset_defaults;

  /// Chat settings parameters tab
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters_tab;

  /// Chat settings MCP tab
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get mcp_tab;

  /// Temperature slider label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Temperature description
  ///
  /// In en, this message translates to:
  /// **'Controls randomness: Higher = Creative, Lower = Focused'**
  String get temperature_desc;

  /// Top P slider label
  ///
  /// In en, this message translates to:
  /// **'Top P'**
  String get top_p;

  /// Top P description
  ///
  /// In en, this message translates to:
  /// **'Nucleus sampling threshold'**
  String get top_p_desc;

  /// Max tokens input label
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get max_tokens;

  /// Max tokens description
  ///
  /// In en, this message translates to:
  /// **'Response limit'**
  String get max_tokens_desc;

  /// Context length input label
  ///
  /// In en, this message translates to:
  /// **'Context Length'**
  String get context_length;

  /// Context length description
  ///
  /// In en, this message translates to:
  /// **'History window'**
  String get context_length_desc;

  /// Warning when MCP is disabled
  ///
  /// In en, this message translates to:
  /// **'MCP is disabled globally. Enable it in Settings to use these features.'**
  String get mcp_disabled_warning;

  /// Toggle to enable MCP for current chat
  ///
  /// In en, this message translates to:
  /// **'Enable MCP for this chat'**
  String get mcp_enable_chat;

  /// Toggle for auto-executing tools
  ///
  /// In en, this message translates to:
  /// **'Auto-execute tools'**
  String get auto_execute_tools;

  /// Section label for adding temp MCP server
  ///
  /// In en, this message translates to:
  /// **'Add Ephemeral MCP Server'**
  String get add_ephemeral_mcp;

  /// MCP label field placeholder
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get mcp_label_placeholder;

  /// MCP URL field placeholder
  ///
  /// In en, this message translates to:
  /// **'URL (https://...)'**
  String get mcp_url_placeholder;

  /// Active MCP integrations section
  ///
  /// In en, this message translates to:
  /// **'Active Integrations'**
  String get active_integrations;

  /// Notification banner title
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enable_notifications;

  /// Notification banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified when models finish downloading.'**
  String get enable_notifications_desc;

  /// Chat history screen title
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chat_history_title;

  /// Recent conversation timestamp
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get conversation_just_now;

  /// Minutes ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String conversation_minutes_ago(int minutes);

  /// Hours ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String conversation_hours_ago(int hours);

  /// Yesterday timestamp
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get conversation_yesterday;

  /// Days ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String conversation_days_ago(int days);

  /// Full date timestamp
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}/{year}'**
  String conversation_date(int month, int day, int year);

  /// Options menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options_tooltip;

  /// Search empty state
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get no_results_found;

  /// Empty conversations state
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get no_conversations_yet;

  /// Search empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get try_different_search;

  /// Empty state subtitle when no conversations
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation'**
  String get start_new_conversation;

  /// Rename dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get rename_conversation;

  /// Rename text field hint
  ///
  /// In en, this message translates to:
  /// **'Enter new title'**
  String get enter_new_title;

  /// Pinned conversations section header
  ///
  /// In en, this message translates to:
  /// **'PINNED'**
  String get pinned_section;

  /// Today section header
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today_section;

  /// Yesterday section header
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterday_section;

  /// Previous 7 days section header
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS 7 DAYS'**
  String get previous_7_days;

  /// Previous 30 days section header
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS 30 DAYS'**
  String get previous_30_days;

  /// Older conversations section header
  ///
  /// In en, this message translates to:
  /// **'OLDER'**
  String get older_section;

  /// Onboarding screen branding text
  ///
  /// In en, this message translates to:
  /// **'LOCALMIND'**
  String get onboarding_localmind;

  /// Onboarding heading for server connection
  ///
  /// In en, this message translates to:
  /// **'Connect Your\nServer'**
  String get onboarding_connect_server;

  /// Onboarding server connection description
  ///
  /// In en, this message translates to:
  /// **'Connect to LM Studio, Ollama, or\nOpenRouter to start your private AI\nexperience.'**
  String get onboarding_connect_desc;

  /// On-device server type card title
  ///
  /// In en, this message translates to:
  /// **'On-Device'**
  String get server_type_on_device;

  /// On-device server type card subtitle
  ///
  /// In en, this message translates to:
  /// **'NO SERVER NEEDED'**
  String get server_type_on_device_sub;

  /// LM Studio server type card title
  ///
  /// In en, this message translates to:
  /// **'LM Studio'**
  String get server_type_lm_studio;

  /// LM Studio server type card subtitle
  ///
  /// In en, this message translates to:
  /// **'LOCAL API'**
  String get server_type_lm_studio_sub;

  /// Ollama server type card title
  ///
  /// In en, this message translates to:
  /// **'Ollama'**
  String get server_type_ollama;

  /// Ollama server type card subtitle
  ///
  /// In en, this message translates to:
  /// **'CLI ENGINE'**
  String get server_type_ollama_sub;

  /// OpenRouter server type card title
  ///
  /// In en, this message translates to:
  /// **'OpenRouter'**
  String get server_type_openrouter;

  /// OpenRouter server type card subtitle
  ///
  /// In en, this message translates to:
  /// **'UNIFIED CLOUD'**
  String get server_type_openrouter_sub;

  /// Onboarding ready status
  ///
  /// In en, this message translates to:
  /// **'READY TO CONTINUE'**
  String get ready_continue;

  /// Onboarding waiting status
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR SELECTION'**
  String get waiting_selection;

  /// Onboarding setup screen title
  ///
  /// In en, this message translates to:
  /// **'Setup Connection'**
  String get setup_connection;

  /// Onboarding setup description
  ///
  /// In en, this message translates to:
  /// **'Configure your {server} server to start chatting.'**
  String setup_connection_desc(String server);

  /// Server name field label
  ///
  /// In en, this message translates to:
  /// **'Server Name'**
  String get server_name;

  /// Validation: name required
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get name_required;

  /// Validation: max 50 chars
  ///
  /// In en, this message translates to:
  /// **'Max 50 characters'**
  String get name_max_50;

  /// Host field label
  ///
  /// In en, this message translates to:
  /// **'Host / IP Address'**
  String get host_label;

  /// Validation: host required
  ///
  /// In en, this message translates to:
  /// **'Host required'**
  String get host_required;

  /// Port field label
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port_label;

  /// Validation: port required
  ///
  /// In en, this message translates to:
  /// **'Port required'**
  String get port_required;

  /// Validation: invalid port number
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get port_invalid;

  /// Validation: port range
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port (1-65535)'**
  String get port_range;

  /// Required API key label
  ///
  /// In en, this message translates to:
  /// **'API Key *'**
  String get api_key_required;

  /// Optional API key label
  ///
  /// In en, this message translates to:
  /// **'API Key (Optional)'**
  String get api_key_optional;

  /// Validation: API key for OpenRouter
  ///
  /// In en, this message translates to:
  /// **'API Key required for OpenRouter'**
  String get api_key_required_openrouter;

  /// Validation: API key format
  ///
  /// In en, this message translates to:
  /// **'OpenRouter API keys start with sk-'**
  String get api_key_format;

  /// Server name field hint
  ///
  /// In en, this message translates to:
  /// **'My Server'**
  String get my_server_hint;

  /// Validation: name too long
  ///
  /// In en, this message translates to:
  /// **'Name must be 50 characters or less'**
  String get name_length_validation;

  /// Validation: invalid host
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hostname or IP address'**
  String get host_valid;

  /// OpenRouter API key hint
  ///
  /// In en, this message translates to:
  /// **'sk-...'**
  String get api_key_hint_openrouter;

  /// Generic API key hint
  ///
  /// In en, this message translates to:
  /// **'For authenticated servers'**
  String get api_key_hint_generic;

  /// Update server button
  ///
  /// In en, this message translates to:
  /// **'Update Server'**
  String get update_server;

  /// Save server button
  ///
  /// In en, this message translates to:
  /// **'Save Server'**
  String get save_server;

  /// Server update snackbar
  ///
  /// In en, this message translates to:
  /// **'Server updated'**
  String get server_updated;

  /// Server added snackbar
  ///
  /// In en, this message translates to:
  /// **'Server added'**
  String get server_added;

  /// Onboarding download model screen title
  ///
  /// In en, this message translates to:
  /// **'Download a Model'**
  String get download_model_title;

  /// Onboarding download model description
  ///
  /// In en, this message translates to:
  /// **'Choose a model to download.\nIt will run locally on your device.'**
  String get download_model_desc;

  /// Platform limitation notice
  ///
  /// In en, this message translates to:
  /// **'On-device inference is currently available on Android only.'**
  String get on_device_android_only;

  /// Total RAM label
  ///
  /// In en, this message translates to:
  /// **'Total RAM'**
  String get total_ram;

  /// Available label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Minimum RAM requirement label
  ///
  /// In en, this message translates to:
  /// **'{fileSize} GB RAM min'**
  String ram_min_required(String fileSize);

  /// Download progress display
  ///
  /// In en, this message translates to:
  /// **'{percent}% • {speed}'**
  String download_progress(String percent, String speed);

  /// Estimated time remaining label
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String eta_label(String eta);

  /// Paused download status with progress
  ///
  /// In en, this message translates to:
  /// **'Paused - {percent}%'**
  String paused_progress(String percent);

  /// RAM warning during download
  ///
  /// In en, this message translates to:
  /// **'This model requires at least {ram} GB RAM, but your device has {totalMemory}. It may not run correctly or could cause the app to crash.'**
  String ram_warning_body_download(String ram, String totalMemory);

  /// RAM warning during model load
  ///
  /// In en, this message translates to:
  /// **'Your device has {availableRAM} available RAM, but this model recommends at least {ram} GB. Loading it might fail or cause instability.'**
  String ram_warning_body_load(String availableRAM, String ram);

  /// Onboarding theme selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get choose_theme;

  /// Onboarding theme selection description
  ///
  /// In en, this message translates to:
  /// **'Personalize the app appearance. You can always change this later in settings.'**
  String get choose_theme_desc;

  /// System theme card title
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_card_system;

  /// System theme card subtitle
  ///
  /// In en, this message translates to:
  /// **'Matches your device settings'**
  String get theme_card_system_sub;

  /// Light theme card title
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_card_light;

  /// Light theme card subtitle
  ///
  /// In en, this message translates to:
  /// **'Clean and bright'**
  String get theme_card_light_sub;

  /// Dark theme card title
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_card_dark;

  /// Dark theme card subtitle
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get theme_card_dark_sub;

  /// Claude theme card title
  ///
  /// In en, this message translates to:
  /// **'Claude'**
  String get theme_card_claude;

  /// Claude theme card subtitle
  ///
  /// In en, this message translates to:
  /// **'A warm, peach-tinted theme'**
  String get theme_card_claude_sub;

  /// Onboarding notification screen heading
  ///
  /// In en, this message translates to:
  /// **'Stay Updated'**
  String get stay_updated;

  /// Onboarding notification screen description
  ///
  /// In en, this message translates to:
  /// **'Get notified when your AI models finish downloading or when long-running tasks complete.'**
  String get stay_updated_desc;

  /// Notification benefit list item
  ///
  /// In en, this message translates to:
  /// **'Model download progress'**
  String get notification_benefit_downloads;

  /// Notification benefit list item
  ///
  /// In en, this message translates to:
  /// **'Generation completions'**
  String get notification_benefit_completions;

  /// Notification benefit list item
  ///
  /// In en, this message translates to:
  /// **'Background tasks status'**
  String get notification_benefit_background;

  /// Allow notifications button
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get allow_notifications;

  /// Server list screen title
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers_title;

  /// Empty server list title
  ///
  /// In en, this message translates to:
  /// **'No Servers Yet'**
  String get no_servers_yet;

  /// Empty server list description
  ///
  /// In en, this message translates to:
  /// **'Add your first server to start chatting with AI models.'**
  String get no_servers_desc;

  /// Add server button
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get add_server;

  /// Server switch snackbar
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String switched_to_server(String name);

  /// Edit server screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Server'**
  String get edit_server;

  /// Add server screen title
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get add_server_title;

  /// Server type section label
  ///
  /// In en, this message translates to:
  /// **'Server Type'**
  String get server_type_label;

  /// Server icon section label
  ///
  /// In en, this message translates to:
  /// **'Server Icon'**
  String get server_icon_label;

  /// Default icon fallback text
  ///
  /// In en, this message translates to:
  /// **'Default icon'**
  String get default_icon;

  /// LM Studio server type display
  ///
  /// In en, this message translates to:
  /// **'LM Studio'**
  String get server_type_lm_studio_display;

  /// OpenAI compatible server type display
  ///
  /// In en, this message translates to:
  /// **'OpenAI Compatible'**
  String get server_type_openai_display;

  /// Ollama server type display
  ///
  /// In en, this message translates to:
  /// **'Ollama'**
  String get server_type_ollama_display;

  /// OpenRouter server type display
  ///
  /// In en, this message translates to:
  /// **'OpenRouter'**
  String get server_type_openrouter_display;

  /// On-device server type display
  ///
  /// In en, this message translates to:
  /// **'On-Device'**
  String get server_type_on_device_display;

  /// OpenRouter default address
  ///
  /// In en, this message translates to:
  /// **'openrouter.ai'**
  String get server_address_openrouter;

  /// On-device server address
  ///
  /// In en, this message translates to:
  /// **'Local inference'**
  String get server_address_on_device;

  /// Server address display format
  ///
  /// In en, this message translates to:
  /// **'{host}:{port}'**
  String server_address_format(String host, String port);

  /// Default server badge
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default_badge;

  /// Set as default menu item
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get set_as_default;

  /// Icon picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get select_icon;

  /// Icon picker sheet description
  ///
  /// In en, this message translates to:
  /// **'Choose an icon for your server'**
  String get select_icon_desc;

  /// Icon search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search icons...'**
  String get search_icons_hint;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Server Stack'**
  String get server_icon_stack;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Server Stack 02'**
  String get server_icon_stack2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Server Stack 03'**
  String get server_icon_stack3;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get server_icon_cloud;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Cloud Server'**
  String get server_icon_cloud_server;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'MCP Server'**
  String get server_icon_mcp;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get server_icon_database;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Database 01'**
  String get server_icon_database1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Database 02'**
  String get server_icon_database2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get server_icon_cpu;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Chip'**
  String get server_icon_chip;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Chip 02'**
  String get server_icon_chip2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get server_icon_computer;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get server_icon_laptop;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Computer Terminal'**
  String get server_icon_terminal;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get server_icon_code;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'AI Brain'**
  String get server_icon_ai_brain;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'AI Brain 02'**
  String get server_icon_ai_brain2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'AI Cloud'**
  String get server_icon_ai_cloud;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'AI Network'**
  String get server_icon_ai_network;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get server_icon_ai_chat;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Cellular Network'**
  String get server_icon_cellular;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Plug 01'**
  String get server_icon_plug1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Plug 02'**
  String get server_icon_plug2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get server_icon_bot;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Bot 02'**
  String get server_icon_bot2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Robotic'**
  String get server_icon_robotic;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Rocket'**
  String get server_icon_rocket;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get server_icon_star;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Settings 01'**
  String get server_icon_settings1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Settings 02'**
  String get server_icon_settings2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Home 01'**
  String get server_icon_home1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Home 02'**
  String get server_icon_home2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Folder 01'**
  String get server_icon_folder1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Folder 02'**
  String get server_icon_folder2;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'File 01'**
  String get server_icon_file1;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get server_icon_lock;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Key 01'**
  String get server_icon_key;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Link 01'**
  String get server_icon_link;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Globe'**
  String get server_icon_globe;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get server_icon_api;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Arrow Right 01'**
  String get server_icon_arrow_right;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Check Circle'**
  String get server_icon_check;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Alert Circle'**
  String get server_icon_alert;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Info Circle'**
  String get server_icon_info;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Zap'**
  String get server_icon_zap;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Cloud Upload'**
  String get server_icon_cloud_upload;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Cloud Download'**
  String get server_icon_cloud_download;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get server_icon_refresh;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Hard Drive'**
  String get server_icon_hard_drive;

  /// Server icon name
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get server_icon_drive;

  /// Persona list screen title
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get personas_title;

  /// General persona category
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get persona_category_general;

  /// Coding persona category
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get persona_category_coding;

  /// Education persona category
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get persona_category_education;

  /// Creative persona category
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get persona_category_creative;

  /// Built-in personas section label
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN'**
  String get persona_builtin_section;

  /// My personas section label
  ///
  /// In en, this message translates to:
  /// **'MY PERSONAS'**
  String get persona_my_section;

  /// Clone and edit persona action
  ///
  /// In en, this message translates to:
  /// **'Clone & Edit'**
  String get clone_edit;

  /// Built-in persona badge
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtin_badge;

  /// Empty persona list title
  ///
  /// In en, this message translates to:
  /// **'No personas found'**
  String get no_personas_found;

  /// Empty persona list subtitle
  ///
  /// In en, this message translates to:
  /// **'Create your first persona to customize AI behavior.'**
  String get no_personas_desc;

  /// Edit persona screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Persona'**
  String get edit_persona;

  /// Create persona screen title
  ///
  /// In en, this message translates to:
  /// **'Create Persona'**
  String get create_persona;

  /// Create persona action button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create_persona_button;

  /// Emoji selection label
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji_label;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name_label;

  /// Persona name hint
  ///
  /// In en, this message translates to:
  /// **'My Persona'**
  String get my_persona_hint;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category_label;

  /// Optional description label
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description_optional;

  /// Description field hint
  ///
  /// In en, this message translates to:
  /// **'What this persona does...'**
  String get description_hint;

  /// System prompt section label
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get system_prompt;

  /// Character counter for system prompt
  ///
  /// In en, this message translates to:
  /// **'{currentLen}/4000'**
  String character_count_max(int currentLen);

  /// Preview placeholder when no prompt
  ///
  /// In en, this message translates to:
  /// **'No prompt yet...'**
  String get no_prompt_placeholder;

  /// System prompt text field hint
  ///
  /// In en, this message translates to:
  /// **'You are a helpful assistant...'**
  String get prompt_hint;

  /// Validation: prompt required
  ///
  /// In en, this message translates to:
  /// **'System prompt is required'**
  String get prompt_required;

  /// Validation: prompt max chars
  ///
  /// In en, this message translates to:
  /// **'Max 4000 characters'**
  String get prompt_max_chars;

  /// Expandable advanced settings section
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advanced_settings;

  /// Temperature field label in personas
  ///
  /// In en, this message translates to:
  /// **'Temperature (0.0-2.0)'**
  String get temperature_label;

  /// Top P field label in personas
  ///
  /// In en, this message translates to:
  /// **'Top P (0.0-1.0)'**
  String get top_p_label;

  /// Temperature field hint
  ///
  /// In en, this message translates to:
  /// **'0.7'**
  String get temp_hint;

  /// Top P field hint
  ///
  /// In en, this message translates to:
  /// **'0.9'**
  String get top_p_hint;

  /// Range validation error (temperature)
  ///
  /// In en, this message translates to:
  /// **'0.0-2.0'**
  String get range_0_2;

  /// Range validation error (top P)
  ///
  /// In en, this message translates to:
  /// **'0.0-1.0'**
  String get range_0_1;

  /// Persona update snackbar
  ///
  /// In en, this message translates to:
  /// **'Persona updated'**
  String get persona_updated;

  /// Persona creation snackbar
  ///
  /// In en, this message translates to:
  /// **'Persona created'**
  String get persona_created;

  /// TTS model manager screen title
  ///
  /// In en, this message translates to:
  /// **'Text To Speech Models'**
  String get tts_models_title;

  /// Always available status
  ///
  /// In en, this message translates to:
  /// **'Always available'**
  String get always_available;

  /// System TTS engine description
  ///
  /// In en, this message translates to:
  /// **'Uses your device\'s built-in text-to-speech engine.\nNo downloads required. Voice selection uses your device\'s system settings.'**
  String get tts_system_desc;

  /// Downloading status text
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading_status;

  /// Kitten TTS engine description
  ///
  /// In en, this message translates to:
  /// **'Lightning-fast neural TTS with 8 expressive voices.\nRequires {size} download.'**
  String tts_kitten_desc(String size);

  /// Piper TTS engine description
  ///
  /// In en, this message translates to:
  /// **'Fast offline Piper voices with 2 expressive voices.\nRequires {size} download per voice.'**
  String tts_piper_desc(String size);

  /// Engine specification display
  ///
  /// In en, this message translates to:
  /// **'{sizeMb} MB · {ramMb} MB RAM · {voiceCount} voices'**
  String engine_spec(String sizeMb, String ramMb, int voiceCount);

  /// On-device model manager screen title
  ///
  /// In en, this message translates to:
  /// **'On-Device Models'**
  String get on_device_models_title;

  /// Available models section title
  ///
  /// In en, this message translates to:
  /// **'Available Models'**
  String get available_models;

  /// Device memory card title
  ///
  /// In en, this message translates to:
  /// **'Device Memory'**
  String get device_memory;

  /// RAM usage label
  ///
  /// In en, this message translates to:
  /// **'RAM Usage'**
  String get ram_usage;

  /// Memory status healthy
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get memory_healthy;

  /// Memory status critical
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get memory_critical;

  /// Memory status low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get memory_low;

  /// RAM usage percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String ram_used(String percent);

  /// Available RAM stat label
  ///
  /// In en, this message translates to:
  /// **'Available RAM'**
  String get available_ram;

  /// Total capacity stat label
  ///
  /// In en, this message translates to:
  /// **'Total Capacity'**
  String get total_capacity;

  /// Model loaded status
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get loaded_status;

  /// Backend selector section title
  ///
  /// In en, this message translates to:
  /// **'Inference Backend'**
  String get inference_backend;

  /// iOS backend limitation notice
  ///
  /// In en, this message translates to:
  /// **'Only CPU backend is available on iOS.'**
  String get backend_ios_notice;

  /// CPU backend description
  ///
  /// In en, this message translates to:
  /// **'Works on all devices. Most compatible.'**
  String get backend_cpu_desc;

  /// GPU backend description
  ///
  /// In en, this message translates to:
  /// **'OpenCL acceleration. Faster on supported devices.'**
  String get backend_gpu_desc;

  /// NPU backend description
  ///
  /// In en, this message translates to:
  /// **'Vendor NPU (Qualcomm/MediaTek). Fastest inference.'**
  String get backend_npu_desc;

  /// Model picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get select_model_title;

  /// Refresh models tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh models'**
  String get refresh_models;

  /// Model search field hint
  ///
  /// In en, this message translates to:
  /// **'Search models...'**
  String get search_models_hint;

  /// Model picker empty state title
  ///
  /// In en, this message translates to:
  /// **'No server connected'**
  String get no_server_connected;

  /// Model picker empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add a server first to see available models.'**
  String get add_server_first;

  /// Model load error title
  ///
  /// In en, this message translates to:
  /// **'Failed to load models'**
  String get failed_load_models;

  /// Empty models state
  ///
  /// In en, this message translates to:
  /// **'No models available'**
  String get no_models_available;

  /// No search results for models
  ///
  /// In en, this message translates to:
  /// **'No models match \"{searchQuery}\"'**
  String no_models_match(String searchQuery);

  /// Model load failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to load model: {error}'**
  String model_load_failed(String error);

  /// Ollama model unloaded status
  ///
  /// In en, this message translates to:
  /// **'{name} will be unloaded once the keep-alive time passes'**
  String model_unloaded_ollama(String name);

  /// Model unloaded success snackbar
  ///
  /// In en, this message translates to:
  /// **'{name} unloaded successfully'**
  String model_unloaded_success(String name);

  /// Model unload failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to unload model: {error}'**
  String model_unload_failed(String error);

  /// Unload model tooltip
  ///
  /// In en, this message translates to:
  /// **'Unload from server'**
  String get unload_from_server;

  /// Context length chip
  ///
  /// In en, this message translates to:
  /// **'{ctx} ctx'**
  String context_chip(String ctx);

  /// Download notification title
  ///
  /// In en, this message translates to:
  /// **'Downloading {modelName}...'**
  String download_notification_title(String modelName);

  /// Download complete notification title
  ///
  /// In en, this message translates to:
  /// **'Download complete!'**
  String get download_complete_notification;

  /// Download complete notification body
  ///
  /// In en, this message translates to:
  /// **'{modelName} has been downloaded successfully.'**
  String download_complete_body(String modelName);

  /// Download failed notification title
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String download_failed_notification(String error);

  /// Download failed notification body
  ///
  /// In en, this message translates to:
  /// **'Failed to download {modelName}.'**
  String download_failed_body(String modelName);

  /// System TTS engine display name
  ///
  /// In en, this message translates to:
  /// **'System TTS'**
  String get engine_name_system;

  /// System TTS engine tagline
  ///
  /// In en, this message translates to:
  /// **'Built-in device engine'**
  String get engine_tagline_system;

  /// Kitten TTS engine display name
  ///
  /// In en, this message translates to:
  /// **'Kitten TTS'**
  String get engine_name_kitten;

  /// Kitten TTS engine tagline
  ///
  /// In en, this message translates to:
  /// **'High-speed neural TTS'**
  String get engine_tagline_kitten;

  /// Sherpa ONNX engine display name
  ///
  /// In en, this message translates to:
  /// **'Sherpa ONNX VITS'**
  String get engine_name_sherpa;

  /// Sherpa ONNX engine tagline
  ///
  /// In en, this message translates to:
  /// **'Offline Piper voices'**
  String get engine_tagline_sherpa;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Jasper'**
  String get voice_jasper;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Bella'**
  String get voice_bella;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Bruno'**
  String get voice_bruno;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Luna'**
  String get voice_luna;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Hugo'**
  String get voice_hugo;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Rosie'**
  String get voice_rosie;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get voice_leo;

  /// Kitten TTS voice name
  ///
  /// In en, this message translates to:
  /// **'Kiki'**
  String get voice_kiki;

  /// Piper voice name
  ///
  /// In en, this message translates to:
  /// **'Lessac (US)'**
  String get voice_lessac;

  /// Piper voice name
  ///
  /// In en, this message translates to:
  /// **'Ryan (US)'**
  String get voice_ryan;

  /// On-device model name
  ///
  /// In en, this message translates to:
  /// **'Qwen 3 0.6B'**
  String get model_qwen_3;

  /// Qwen 3 model description
  ///
  /// In en, this message translates to:
  /// **'Smallest general-purpose chat model. Fast responses, low memory usage.'**
  String get model_qwen_3_desc;

  /// Apache license label
  ///
  /// In en, this message translates to:
  /// **'Apache-2.0'**
  String get model_license_apache;

  /// On-device model name
  ///
  /// In en, this message translates to:
  /// **'Qwen 2.5 1.5B Instruct'**
  String get model_qwen_25;

  /// Qwen 2.5 model description
  ///
  /// In en, this message translates to:
  /// **'Balanced quality and size. Good for general conversation.'**
  String get model_qwen_25_desc;

  /// On-device model name
  ///
  /// In en, this message translates to:
  /// **'DeepSeek R1 Distill Qwen 1.5B'**
  String get model_deepseek;

  /// DeepSeek model description
  ///
  /// In en, this message translates to:
  /// **'Reasoning and chain-of-thought model. Best for logical tasks.'**
  String get model_deepseek_desc;

  /// MIT license label
  ///
  /// In en, this message translates to:
  /// **'MIT'**
  String get model_license_mit;

  /// On-device model name
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B Instruct'**
  String get model_gemma;

  /// Gemma model description
  ///
  /// In en, this message translates to:
  /// **'Google flagship model. Highest quality, requires more RAM.'**
  String get model_gemma_desc;

  /// Markdown export header
  ///
  /// In en, this message translates to:
  /// **'*Exported from LocalMind — {date}*'**
  String export_header(String date);

  /// Markdown export user role label
  ///
  /// In en, this message translates to:
  /// **'## 👤 User'**
  String get export_role_user;

  /// Markdown export assistant role label
  ///
  /// In en, this message translates to:
  /// **'## 🤖 Assistant'**
  String get export_role_assistant;

  /// Markdown export system role label
  ///
  /// In en, this message translates to:
  /// **'## ⚙️ System'**
  String get export_role_system;

  /// Markdown export tool role label
  ///
  /// In en, this message translates to:
  /// **'## 🔧 Tool'**
  String get export_role_tool;

  /// Text export user role prefix
  ///
  /// In en, this message translates to:
  /// **'[USER]'**
  String get export_text_user;

  /// Text export assistant role prefix
  ///
  /// In en, this message translates to:
  /// **'[ASSISTANT]'**
  String get export_text_assistant;

  /// Text export system role prefix
  ///
  /// In en, this message translates to:
  /// **'[SYSTEM]'**
  String get export_text_system;

  /// Text export tool role prefix
  ///
  /// In en, this message translates to:
  /// **'[TOOL]'**
  String get export_text_tool;

  /// Export user role label
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get export_label_user;

  /// Export assistant role label
  ///
  /// In en, this message translates to:
  /// **'ASSISTANT'**
  String get export_label_assistant;

  /// Export system role label
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get export_label_system;

  /// Export tool role label
  ///
  /// In en, this message translates to:
  /// **'TOOL'**
  String get export_label_tool;

  /// Fallback text when no model is selected
  ///
  /// In en, this message translates to:
  /// **'Select a model to start chatting'**
  String get select_model_hint;

  /// Test notification title
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get test_notification_title;

  /// Test notification body
  ///
  /// In en, this message translates to:
  /// **'This is a test notification for model download progress.'**
  String get test_notification_body;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'en',
    'es',
    'hi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
