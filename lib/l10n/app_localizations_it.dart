// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => 'La tua IA. Il tuo dispositivo. Le tue regole.';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get retry => 'Riprova';

  @override
  String get close => 'Chiudi';

  @override
  String get done => 'Done';

  @override
  String get continue_action => 'Continua';

  @override
  String get skip => 'Salta';

  @override
  String get install => 'Installa';

  @override
  String get download => 'Download';

  @override
  String get resume => 'Riprendi';

  @override
  String get pause => 'Pausa';

  @override
  String get stop => 'Stop';

  @override
  String get edit => 'Modificare';

  @override
  String get preview => 'Anteprima';

  @override
  String get unload => 'Scarico';

  @override
  String get load => 'Carico';

  @override
  String get rename => 'Rinomina';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Sblocca';

  @override
  String get share => 'Condividi';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato!';

  @override
  String get copied_to_clipboard => 'Copiato negli appunti';

  @override
  String get select => 'Seleziona';

  @override
  String get active => 'Attivo';

  @override
  String get all => 'Tutto';

  @override
  String get none => 'Nessuna';

  @override
  String get none_selected => 'Nessuna selezione';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get error => 'Errore';

  @override
  String get unknown_error => 'Errore sconosciuto';

  @override
  String get not_now => 'Non ora';

  @override
  String get enable => 'Abilita';

  @override
  String get proceed_anyway => 'Procedi Comunque';

  @override
  String get test_connection => 'Connessione di prova';

  @override
  String get testing => 'Collaudo';

  @override
  String get connection_successful => 'Connessione effettuata con successo!';

  @override
  String get connection_failed =>
      'Connessione non riuscita. Controlla le impostazioni.';

  @override
  String get save_continue => 'Salva e continua';

  @override
  String get save_changes => 'Salva modifiche';

  @override
  String get finish_setup => 'Fine impostazioni';

  @override
  String get start_new_chat => 'Avvia una nuova sessione di chat';

  @override
  String get cannot_undo => 'Non sarà possibile annullare questa operazione.';

  @override
  String get ram_warning => 'Avviso RAM';

  @override
  String get recommended => 'CONSIGLIATO';

  @override
  String get may_be_large =>
      'Potrebbe essere troppo grande per questo dispositivo';

  @override
  String get calculating => 'Calcolo in corso...';

  @override
  String get download_failed => 'Download non riuscito';

  @override
  String get downloaded => 'Scaricato';

  @override
  String get not_downloaded => 'Non scaricato';

  @override
  String get installed => 'Presente';

  @override
  String get not_installed => 'Non installata';

  @override
  String get loading => 'Caricamento in corso...';

  @override
  String get thinking => 'Pensiero';

  @override
  String get processing => 'Elaborazione in corso';

  @override
  String get initializing => 'Inizializzazione in corso...';

  @override
  String get ready => 'Pronto';

  @override
  String get preparing_app => 'Preparazione dell\'app in corso...';

  @override
  String get initializing_services => 'Inizializzazione servizi in corso...';

  @override
  String get configuring_server => 'Configurazione del server in corso ...';

  @override
  String get startup_failed => 'Avvio non riuscito';

  @override
  String get something_went_wrong => 'Qualcosa non ha funzionato';

  @override
  String get delete_model_title => 'ELIMINARE UN MODELLO.';

  @override
  String delete_model_body(String name) {
    return 'Eliminare';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return 'Sei sicuro di voler eliminare $name? In questo modo libererai circa $size di spazio.\n\nÈ possibile scaricare nuovamente questo modello in seguito, se necessario.';
  }

  @override
  String get delete_voice_title => 'Elimina tag vocale';

  @override
  String delete_voice_body(String name, String size) {
    return 'Sei sicuro di voler eliminare $name? In questo modo libererai circa $size di spazio.\n\nPuoi scaricare di nuovo questa voce in un secondo momento, se necessario.';
  }

  @override
  String get delete_server_title => 'Elimina server';

  @override
  String delete_server_body(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"? L\'operazione non può essere annullata.';
  }

  @override
  String get delete_conversation_title => 'Eliminare la conversazione?';

  @override
  String delete_conversation_body(String title) {
    return 'Sei sicuro di voler eliminare \"$title\"? L\'operazione non può essere annullata.';
  }

  @override
  String get delete_message_title => 'Eliminare il messaggio?';

  @override
  String delete_persona_title(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get delete_persona_body => 'L\'operazione non può essere annullata.';

  @override
  String get clear_conversation_title => 'Conversazioni chiare?';

  @override
  String get clear_conversation_body =>
      'Questo eliminerà tutti i messaggi in questa conversazione.';

  @override
  String get clear => 'Cancella';

  @override
  String label_completed(String label) {
    return '$label completato';
  }

  @override
  String error_with_message(String error) {
    return 'Errore: $error';
  }

  @override
  String preview_failed(String error) {
    return 'Anteprima non riuscita: $error';
  }

  @override
  String loading_model(String modelId) {
    return 'Caricamento di $modelId...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return 'Modello caricato: $modelId ($backend)';
  }

  @override
  String get no_model_loaded =>
      'Nessun modello caricato. Tocca \"Gestisci modelli sul dispositivo\" per scaricare e caricare un modello.';

  @override
  String loading_model_error(String error) {
    return 'Errore: $error';
  }

  @override
  String get delete_conversation => 'Eliminare la conversazione?';

  @override
  String get nav_history => 'Storia';

  @override
  String get nav_servers => 'Server';

  @override
  String get nav_local_models => 'Modelli locali';

  @override
  String get nav_tts => 'Sintesi vocale';

  @override
  String get nav_personas => 'Personas';

  @override
  String get nav_settings => 'Impostazioni';

  @override
  String get nav_new_chat => 'Nuova chat';

  @override
  String get search_hint => 'Cerca conversazioni...';

  @override
  String get no_server_selected => 'Nessun server selezionato';

  @override
  String get switch_server => 'Cambia server';

  @override
  String get switch_server_subtitle => 'Scegli un server a cui connetterti';

  @override
  String get manage_servers => 'Gestisci server';

  @override
  String get open_source => 'Open Source';

  @override
  String get open_source_desc =>
      'LocalMind è open source. Segui i nostri progressi o contribuisci su GitHub.';

  @override
  String get star_on_github => 'Metti in evidenza su GitHub';

  @override
  String get settings_title => 'Impostazioni';

  @override
  String get settings_appearance => 'Aspetto';

  @override
  String get settings_language => 'Lingua';

  @override
  String get language_system_default => 'Predefinito di sistema';

  @override
  String get settings_tts => 'Sintesi vocale';

  @override
  String get settings_behavior => 'Comportamento';

  @override
  String get settings_on_device => 'Inferenza sul dispositivo';

  @override
  String get settings_default_server => 'Server predefinito';

  @override
  String get settings_default_persona => 'Persona predefinita';

  @override
  String get settings_privacy => 'Privacy';

  @override
  String get settings_data_management => 'Gestione dei dati';

  @override
  String get settings_about => 'Informazioni su';

  @override
  String get theme => 'Tema';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Luce';

  @override
  String get theme_dark => 'Scuro';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => 'Dimensione carattere';

  @override
  String get font_size_desc => 'Regola le dimensioni del testo in chat.';

  @override
  String get font_preview => 'La veloce volpe marrone salta sul cane pigro.';

  @override
  String get code_theme_dark => 'Tema codice (scuro)';

  @override
  String get code_theme_light => 'Tema codice (chiaro)';

  @override
  String get code_theme_desc =>
      'Scegli il tema di evidenziazione della sintassi per i blocchi di codice.';

  @override
  String get tts_engine => 'Motore TTS';

  @override
  String get tts_engine_system => 'System TTS';

  @override
  String get tts_engine_kitten => 'Gattino TTS';

  @override
  String get voice => 'Voce';

  @override
  String get voice_female => 'Donna';

  @override
  String get voice_male => 'Uomo';

  @override
  String get voice_other => 'Altro';

  @override
  String get tts_speed => 'Velocità TTS';

  @override
  String get tts_speed_desc => 'Regola la velocità di riproduzione.';

  @override
  String get manage_tts_models => 'Gestisci modelli TTS';

  @override
  String get manage_on_device_models => 'Gestisci modelli sul dispositivo';

  @override
  String get enable_smart_reply => 'Risposte intelligenti sul dispositivo';

  @override
  String get streaming_responses => 'Risposte in streaming';

  @override
  String get auto_generate_titles => 'Genera automaticamente titoli';

  @override
  String get send_on_enter => 'Invia su Invio';

  @override
  String get show_system_messages => 'Mostra messaggi di sistema';

  @override
  String get haptic_feedback => 'Feedback aptico';

  @override
  String get enable_mcp => 'Abilita MCP';

  @override
  String get new_chat_mcp_default => 'Nuova chat MCP predefinita';

  @override
  String get show_data_indicator => 'Mostra indicatore dati';

  @override
  String get privacy_info => '\"LocalMind non vede mai i tuoi dati\"';

  @override
  String get delete_all_conversations => 'Elimina tutte le conversazioni';

  @override
  String get reset_settings_defaults => 'Ripristina impostazioni predefinite';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => 'Parametri della chat';

  @override
  String get change_persona => 'Cambia persona';

  @override
  String get set_persona => 'Imposta persona';

  @override
  String get remove_persona => 'Rimuovi Persona';

  @override
  String get clear_conversation => 'Cancella conversazione';

  @override
  String get connection_error =>
      'Errore di connessione. Controlla il tuo server.';

  @override
  String get disconnected => 'Disconnesso dal server.';

  @override
  String get configure => 'Configura';

  @override
  String get select_model => 'Seleziona modello';

  @override
  String get select_persona => 'Seleziona Persona';

  @override
  String get start_conversation => 'Avvia una conversazione';

  @override
  String get recent_chats => 'Chat recenti';

  @override
  String get see_all => 'Vedi tutto';

  @override
  String get quick_write => 'Aiutami a scrivere una funzione';

  @override
  String get quick_explain => 'Spiega questo codice';

  @override
  String get quick_debug => 'Esegui il debug per me';

  @override
  String get quick_async => 'Come si usa async/await?';

  @override
  String get history_missing_title => 'Cronologia mancante';

  @override
  String get history_missing_desc =>
      'I messaggi in questa chat sono stati eliminati o il record della cronologia è danneggiato.';

  @override
  String get technical_details => 'Dati tecnici';

  @override
  String get last_error => 'Ultimo errore:';

  @override
  String get copy_info => 'Copia informazioni';

  @override
  String get conversation_id => 'ID conversazione';

  @override
  String get created_at => 'Creato il';

  @override
  String get expected_messages => 'Messaggi previsti';

  @override
  String get debug_dialog_desc =>
      'Informazioni diagnostiche per aiutare a identificare i problemi di sincronizzazione.';

  @override
  String get chat_input_hint => 'Chiedi qualsiasi cosa';

  @override
  String get send_message_tooltip => 'Invia messaggio';

  @override
  String get stop_generation_tooltip => 'Interrompi generazione';

  @override
  String get attach_images_tooltip => 'Allega immagini';

  @override
  String tool_label(String toolCallId) {
    return 'Strumento: $toolCallId';
  }

  @override
  String get tool_unknown => 'Strumento: sconosciuto';

  @override
  String get message_options => 'Opzioni messaggio';

  @override
  String get copy_markdown => 'Copia come sconto';

  @override
  String get copied_markdown => 'Copiato come Markdown';

  @override
  String get read_aloud => 'Leggi ad alta voce';

  @override
  String get stop_reading => 'Smetti di leggere';

  @override
  String get more => 'Altro';

  @override
  String character_count(int length) {
    return '$length caratteri';
  }

  @override
  String get edit_message => 'Modifica messaggio';

  @override
  String get edit_message_desc =>
      'Il salvataggio rimuoverà la risposta dell\'assistente sottostante e la rigenererà.';

  @override
  String get save_regenerate => 'Salva e rigenera';

  @override
  String get chat_settings_title => 'Impostazioni chat';

  @override
  String get reset_defaults => 'Ripristina predefiniti';

  @override
  String get parameters_tab => 'Parametri';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => 'Temperatura';

  @override
  String get temperature_desc =>
      'Controlla la casualità: Più alto = Creativo, Più basso = Concentrato';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => 'Soglia di campionamento del nucleo';

  @override
  String get max_tokens => 'Numero massimo di token';

  @override
  String get max_tokens_desc => 'Limite di risposta';

  @override
  String get context_length => 'Lunghezza del contesto';

  @override
  String get context_length_desc => 'Finestra Cronologia';

  @override
  String get mcp_disabled_warning =>
      'MCP è disabilitato a livello globale. Abilitalo nelle Impostazioni per utilizzare queste funzionalità.';

  @override
  String get mcp_enable_chat => 'Abilita MCP per questa chat';

  @override
  String get auto_execute_tools => 'Esecuzione automatica degli strumenti';

  @override
  String get beta_label => 'Beta';

  @override
  String get experimental_label => 'Sperimentale';

  @override
  String get add_ephemeral_mcp => 'Aggiungi server MCP effimero';

  @override
  String get mcp_label_placeholder => 'Etichetta';

  @override
  String get mcp_url_placeholder => 'URL (https://...)';

  @override
  String get active_integrations => 'Integrazioni attive';

  @override
  String get enable_notifications => 'Abilita notifiche';

  @override
  String get enable_notifications_desc =>
      'Ricevi una notifica quando i modelli terminano il download.';

  @override
  String get chat_history_title => 'Cronologia chat';

  @override
  String get conversation_just_now => 'Proprio ora';

  @override
  String conversation_minutes_ago(int minutes) {
    return '${minutes}m fa';
  }

  @override
  String conversation_hours_ago(int hours) {
    return '${hours}h fa';
  }

  @override
  String get conversation_yesterday => 'Ieri';

  @override
  String conversation_days_ago(int days) {
    return '${days}d fa';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get options_tooltip => 'Opzioni';

  @override
  String get no_results_found => 'Nessun risultato trovato';

  @override
  String get no_conversations_yet => 'Ancora nessuna conversazione';

  @override
  String get try_different_search => 'Prova un altro termine di ricerca';

  @override
  String get start_new_conversation => 'Inizia una nuova conversazione';

  @override
  String get rename_conversation => 'Rinomina conversazione';

  @override
  String get enter_new_title => 'Inserisci un nuovo titolo';

  @override
  String get pinned_section => 'BLOCCATO';

  @override
  String get today_section => 'OGGI';

  @override
  String get yesterday_section => 'IERI';

  @override
  String get previous_7_days => '7 GIORNI PRECEDENTI';

  @override
  String get previous_30_days => '30 GIORNI PRECEDENTI';

  @override
  String get older_section => 'PRECEDENTE';

  @override
  String get onboarding_choose_language => 'Scegli la lingua';

  @override
  String get onboarding_choose_language_desc =>
      'Seleziona la tua lingua preferita. Puoi modificarlo in qualsiasi momento nelle impostazioni.';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => 'Collega il tuo\nServer';

  @override
  String get onboarding_connect_desc =>
      'Connettiti a LM Studio, Ollama o\nOpenRouter per avviare la tua IA privata\nesperienza.';

  @override
  String get onboarding_welcome => 'Benvenuto in LocalMind';

  @override
  String get server_type_on_device => 'On-Device';

  @override
  String get server_type_on_device_sub => 'NESSUN SERVER NECESSARIO';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => 'API LOCALE';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'MOTORE CLI';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => 'CLOUD UNIFICATO';

  @override
  String get ready_continue => 'PRONTO A CONTINUARE';

  @override
  String get waiting_selection => 'IN ATTESA DI SELEZIONE';

  @override
  String get setup_connection => 'Configura connessione';

  @override
  String setup_connection_desc(String server) {
    return 'Configura il tuo server $server per iniziare a chattare.';
  }

  @override
  String get server_name => 'Nome server';

  @override
  String get name_required => 'Nome obbligatorio';

  @override
  String get name_max_50 => 'Max 50 caratteri';

  @override
  String get host_label => 'Indirizzo host / IP';

  @override
  String get host_required => 'Host obbligatorio';

  @override
  String get port_label => 'Porta';

  @override
  String get port_required => 'Porta richiesta';

  @override
  String get port_invalid => 'Deve essere un numero';

  @override
  String get port_range => 'Inserisci una porta valida (1-65535)';

  @override
  String get api_key_required => 'Chiave API *';

  @override
  String get api_key_optional => 'Chiave API (opzionale)';

  @override
  String get api_key_required_openrouter =>
      'Chiave API richiesta per OpenRouter';

  @override
  String get api_key_format => 'Le chiavi API OpenRouter iniziano con sk-';

  @override
  String get my_server_hint => 'Il mio server';

  @override
  String get name_length_validation =>
      'Il nome deve contenere al massimo 50 caratteri';

  @override
  String get host_valid => 'Inserisci un nome host o un indirizzo IP valido';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => 'Per server autenticati';

  @override
  String get update_server => 'Aggiorna server';

  @override
  String get save_server => 'Salva server';

  @override
  String get server_updated => 'Server aggiornato';

  @override
  String get server_added => 'Server aggiunto';

  @override
  String get download_model_title => 'Scarica un modello';

  @override
  String get download_model_desc =>
      'Scegli un modello da scaricare.\nVerrà eseguito localmente sul tuo dispositivo.';

  @override
  String get on_device_android_only =>
      'L\'inferenza sul dispositivo è attualmente disponibile solo su Android.';

  @override
  String get total_ram => 'RAM totale';

  @override
  String get available => 'Disponibile';

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
    return 'In pausa - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return 'Questo modello richiede almeno $ram GB di RAM, ma il suo dispositivo dispone di $totalMemory. Potrebbe non funzionare correttamente o causare l\'arresto anomalo dell\'app.';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return 'Il suo dispositivo ha $availableRAM RAM disponibile, ma questo modello consiglia almeno $ram GB. Il caricamento potrebbe non riuscire o causare instabilità.';
  }

  @override
  String get choose_theme => 'Scegli tema';

  @override
  String get choose_theme_desc =>
      'Personalizza l\'aspetto dell\'app. Puoi sempre modificarlo in seguito nelle impostazioni.';

  @override
  String get theme_card_system => 'Sistema';

  @override
  String get theme_card_system_sub =>
      'Corrisponde alle impostazioni del tuo dispositivo';

  @override
  String get theme_card_light => 'Luce';

  @override
  String get theme_card_light_sub => 'Pulito e luminoso';

  @override
  String get theme_card_dark => 'Scuro';

  @override
  String get theme_card_dark_sub => 'Occhi facili';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => 'Un tema caldo color\n pesca';

  @override
  String get stay_updated => 'Resta aggiornato';

  @override
  String get stay_updated_desc =>
      'Ricevi una notifica quando i tuoi modelli di intelligenza artificiale terminano il download o quando le attività di lunga durata vengono completate.';

  @override
  String get notification_benefit_downloads => 'Avanzamento download modello';

  @override
  String get notification_benefit_completions =>
      'Completamenti della generazione';

  @override
  String get notification_benefit_background =>
      'Stato delle attività in background';

  @override
  String get allow_notifications => 'Consenti notifiche';

  @override
  String get servers_title => 'Server';

  @override
  String get no_servers_yet => 'Ancora nessun server';

  @override
  String get no_servers_desc =>
      'Aggiungi il tuo primo server per iniziare a chattare con i modelli di intelligenza artificiale.';

  @override
  String get add_server => 'Aggiungi server';

  @override
  String switched_to_server(String name) {
    return 'Passato a $name';
  }

  @override
  String get edit_server => 'Modifica server';

  @override
  String get add_server_title => 'Aggiungi server';

  @override
  String get server_type_label => 'Tipo di server';

  @override
  String get server_icon_label => 'Icona del server';

  @override
  String get default_icon => 'Icona predefinita';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => 'Compatibile con OpenAI';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => 'On-Device';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => 'Inferenza locale';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => 'Predefinito';

  @override
  String get set_as_default => 'Imposta come predefinito';

  @override
  String get select_icon => 'Seleziona icona';

  @override
  String get select_icon_desc => 'Scegli un\'icona per il tuo server';

  @override
  String get search_icons_hint => 'Cerca icone...';

  @override
  String get server_icon_stack => 'Stack di server';

  @override
  String get server_icon_stack2 => 'Server Stack 02';

  @override
  String get server_icon_stack3 => 'Server Stack 03';

  @override
  String get server_icon_cloud => 'Cloud';

  @override
  String get server_icon_cloud_server => 'Cloud Server';

  @override
  String get server_icon_mcp => 'Server MCP';

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
  String get server_icon_terminal => 'Terminale informatico';

  @override
  String get server_icon_code => 'Codice';

  @override
  String get server_icon_ai_brain => 'Cervello AI';

  @override
  String get server_icon_ai_brain2 => 'AI Brain 02';

  @override
  String get server_icon_ai_cloud => 'AI Cloud';

  @override
  String get server_icon_ai_network => 'Rete AI';

  @override
  String get server_icon_ai_chat => 'AI Chat';

  @override
  String get server_icon_cellular => 'Rete cellulare';

  @override
  String get server_icon_plug1 => 'Plug 01';

  @override
  String get server_icon_plug2 => 'Plug 02';

  @override
  String get server_icon_bot => 'Bot';

  @override
  String get server_icon_bot2 => 'Bot 02';

  @override
  String get server_icon_robotic => 'Robotica';

  @override
  String get server_icon_rocket => 'Razzo';

  @override
  String get server_icon_star => 'Stella';

  @override
  String get server_icon_settings1 => 'Impostazioni 01';

  @override
  String get server_icon_settings2 => 'Impostazioni 02';

  @override
  String get server_icon_home1 => 'Home 01';

  @override
  String get server_icon_home2 => 'Home 02';

  @override
  String get server_icon_folder1 => 'Cartella 01';

  @override
  String get server_icon_folder2 => 'Cartella 02';

  @override
  String get server_icon_file1 => 'File 01';

  @override
  String get server_icon_lock => 'Blocca';

  @override
  String get server_icon_key => 'Chiave 01';

  @override
  String get server_icon_link => 'Link 01';

  @override
  String get server_icon_globe => 'Globe';

  @override
  String get server_icon_api => 'API';

  @override
  String get server_icon_arrow_right => 'Freccia destra 01';

  @override
  String get server_icon_check => 'Cerchio di controllo';

  @override
  String get server_icon_alert => 'Cerchio di allerta';

  @override
  String get server_icon_info => 'Info Circle';

  @override
  String get server_icon_zap => 'Zap';

  @override
  String get server_icon_cloud_upload => 'Caricamento cloud';

  @override
  String get server_icon_cloud_download => 'Cloud Download';

  @override
  String get server_icon_refresh => 'Aggiorna';

  @override
  String get server_icon_hard_drive => 'Disco rigido';

  @override
  String get server_icon_drive => 'Guida';

  @override
  String get personas_title => 'Personas';

  @override
  String get persona_category_general => 'Generale';

  @override
  String get persona_category_coding => 'Codifica';

  @override
  String get persona_category_education => 'Istruzione';

  @override
  String get persona_category_creative => 'Creativo';

  @override
  String get persona_builtin_section => 'INTEGRATO';

  @override
  String get persona_my_section => 'LE MIE PERSONAS';

  @override
  String get clone_edit => 'Clona e modifica';

  @override
  String get builtin_badge => 'Integrato';

  @override
  String get no_personas_found => 'Nessuna persona trovata';

  @override
  String get no_personas_desc =>
      'Crea la tua prima persona per personalizzare il comportamento dell\'IA.';

  @override
  String get edit_persona => 'Modifica Persona';

  @override
  String get create_persona => 'Crea persona';

  @override
  String get create_persona_button => 'Crea';

  @override
  String get emoji_label => 'Emoji';

  @override
  String get name_label => 'Nome';

  @override
  String get my_persona_hint => 'La mia Persona';

  @override
  String get category_label => 'Categoria';

  @override
  String get description_optional => 'Descrizione (opzionale)';

  @override
  String get description_hint => 'Cosa fa questo personaggio...';

  @override
  String get system_prompt => 'Prompt di sistema';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => 'Ancora nessun prompt...';

  @override
  String get prompt_hint => 'Sei un assistente utile...';

  @override
  String get prompt_required => 'Il prompt di sistema è obbligatorio';

  @override
  String get prompt_max_chars => 'Max 4000 caratteri';

  @override
  String get advanced_settings => 'Impostazioni avanzate';

  @override
  String get temperature_label => 'Temperatura (0,0-2,0)';

  @override
  String get top_p_label => 'Top P (0,0-1,0)';

  @override
  String get temp_hint => '0.7';

  @override
  String get top_p_hint => '0,9';

  @override
  String get range_0_2 => '0,0-2,0';

  @override
  String get range_0_1 => '0,0-1,0';

  @override
  String get persona_updated => 'Persona aggiornata';

  @override
  String get persona_created => 'Persona creata';

  @override
  String get tts_models_title => 'Modelli di sintesi vocale';

  @override
  String get always_available => 'Sempre disponibile';

  @override
  String get tts_system_desc =>
      'Utilizza il motore di sintesi vocale integrato nel dispositivo.\nNessun download richiesto. La selezione vocale utilizza le impostazioni di sistema del tuo dispositivo.';

  @override
  String get downloading_status => 'Download in corso...';

  @override
  String tts_kitten_desc(String size) {
    return 'TTS neurale fulmineo con 8 voci espressive.\nRichiede il download di $size.';
  }

  @override
  String tts_piper_desc(String size) {
    return 'Veloce voce Piper offline con 2 voci espressive.\nRichiede $size download per voce.';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb MB · $ramMb MB RAM · $voiceCount voci';
  }

  @override
  String get on_device_models_title => 'Modelli sul dispositivo';

  @override
  String get available_models => 'Modelli disponibili';

  @override
  String get device_memory => 'Memoria del dispositivo';

  @override
  String get ram_usage => 'Utilizzo della RAM';

  @override
  String get memory_healthy => 'Sano';

  @override
  String get memory_critical => 'Critico';

  @override
  String get memory_low => 'Basso';

  @override
  String ram_used(String percent) {
    return '$percent% utilizzato';
  }

  @override
  String get available_ram => 'RAM disponibile';

  @override
  String get total_capacity => 'Capacità totale';

  @override
  String get loaded_status => 'Caricato';

  @override
  String get inference_backend => 'Backend di inferenza';

  @override
  String get backend_ios_notice =>
      'Solo il back-end della CPU è disponibile su iOS.';

  @override
  String get backend_cpu_desc =>
      'Funziona su tutti i dispositivi. Più compatibile.';

  @override
  String get backend_gpu_desc =>
      'Accelerazione OpenCL. Più veloce sui dispositivi supportati.';

  @override
  String get backend_npu_desc =>
      'NPU del fornitore (Qualcomm/MediaTek). L\'inferenza più veloce.';

  @override
  String get select_model_title => 'Seleziona modello';

  @override
  String get refresh_models => 'Aggiorna modelli';

  @override
  String get search_models_hint => 'Cerca modelli...';

  @override
  String get no_server_connected => 'Nessun server connesso';

  @override
  String get add_server_first =>
      'Aggiungi prima un server per vedere i modelli disponibili.';

  @override
  String get failed_load_models => 'Impossibile caricare i modelli';

  @override
  String get no_models_available => 'Nessun modello disponibile';

  @override
  String no_models_match(String searchQuery) {
    return 'Nessun modello corrisponde a \"$searchQuery\"';
  }

  @override
  String model_load_failed(String error) {
    return 'Impossibile caricare il modello: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return '$name verrà scaricato una volta trascorso il tempo di mantenimento in vita';
  }

  @override
  String model_unloaded_success(String name) {
    return '$name scaricato correttamente';
  }

  @override
  String model_unload_failed(String error) {
    return 'Impossibile scaricare il modello: $error';
  }

  @override
  String get unload_from_server => 'Scarica dal server';

  @override
  String context_chip(String ctx) {
    return '$ctx ctx';
  }

  @override
  String download_notification_title(String modelName) {
    return 'Download di $modelName in corso...';
  }

  @override
  String get download_complete_notification => 'Download completato!';

  @override
  String download_complete_body(String modelName) {
    return '$modelName è stato scaricato correttamente.';
  }

  @override
  String download_failed_notification(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return 'Impossibile scaricare $modelName.';
  }

  @override
  String get engine_name_system => 'System TTS';

  @override
  String get engine_tagline_system => 'Motore del dispositivo integrato';

  @override
  String get engine_name_kitten => 'Gattino TTS';

  @override
  String get engine_tagline_kitten => 'TTS neurale ad alta velocità';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => 'Voci Piper offline';

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
  String get voice_leo => 'Leone';

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
      'Il più piccolo modello di chat generico. Risposte rapide, basso utilizzo della memoria.';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc =>
      'Qualità e dimensioni equilibrate. Ottimo per una conversazione generale.';

  @override
  String get model_deepseek => 'Distillato DeepSeek R1 Qwen 1.5B';

  @override
  String get model_deepseek_desc =>
      'Modello di ragionamento e catena di pensiero. Ideale per attività logiche.';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc =>
      'Modello di punta di Google. Massima qualità, richiede più RAM.';

  @override
  String export_header(String date) {
    return '*Esportato da LocalMind — $date*';
  }

  @override
  String get export_role_user => '## 👤 Utente';

  @override
  String get export_role_assistant => '## 🤖 Assistente';

  @override
  String get export_role_system => '## ⚙️ Sistema';

  @override
  String get export_role_tool => '## 🔧 Strumento';

  @override
  String get export_text_user => '[USER]';

  @override
  String get export_text_assistant => '[ASSISTENTE]';

  @override
  String get export_text_system => '[SISTEMA]';

  @override
  String get export_text_tool => '[STRUMENTO]';

  @override
  String get export_label_user => 'UTENTE';

  @override
  String get export_label_assistant => 'ASSISTENTE';

  @override
  String get export_label_system => 'SISTEMA';

  @override
  String get export_label_tool => 'STRUMENTO';

  @override
  String get select_model_hint =>
      'Seleziona un modello per iniziare a chattare';

  @override
  String get test_notification_title => 'Notifica di prova';

  @override
  String get test_notification_body =>
      'Questa è una notifica di prova per l\'avanzamento del download del modello.';
}
