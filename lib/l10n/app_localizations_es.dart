// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_name => 'LocalMind';

  @override
  String get app_tagline => 'Su IA. Su dispositivo. Sus normas.';

  @override
  String get app_version => '1.0.0';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get done => 'Listo';

  @override
  String get continue_action => 'Continuar';

  @override
  String get skip => 'Omitir';

  @override
  String get install => 'Instalar';

  @override
  String get download => 'Descargar';

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Detener';

  @override
  String get edit => 'Editar';

  @override
  String get preview => 'Vista previa';

  @override
  String get unload => 'Liberar de memoria';

  @override
  String get load => 'Cargar';

  @override
  String get rename => 'Renombrar';

  @override
  String get pin => 'Fijar';

  @override
  String get unpin => 'Desfijar';

  @override
  String get share => 'Compartir';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => '¡Copiado!';

  @override
  String get copied_to_clipboard => 'Copiado al portapapeles';

  @override
  String get select => 'Seleccionar';

  @override
  String get active => 'Activo';

  @override
  String get all => 'Todo';

  @override
  String get none => 'Ninguno';

  @override
  String get none_selected => 'Ninguno seleccionado';

  @override
  String get online => 'En línea';

  @override
  String get offline => 'Sin conexión';

  @override
  String get error => 'Error';

  @override
  String get unknown_error => 'Error desconocido';

  @override
  String get not_now => 'Ahora no';

  @override
  String get enable => 'Habilitar';

  @override
  String get proceed_anyway => 'Proceder de todos modos';

  @override
  String get test_connection => 'Probar conexión';

  @override
  String get testing => 'Probando...';

  @override
  String get connection_successful => '¡Conexión exitosa!';

  @override
  String get connection_failed => 'Conexión fallida. Compruebe sus ajustes.';

  @override
  String get save_continue => 'Guardar y continuar';

  @override
  String get save_changes => 'Guardar cambios';

  @override
  String get finish_setup => 'Finalizar configuración';

  @override
  String get start_new_chat => 'Comenzar nuevo chat';

  @override
  String get cannot_undo => 'Esta acción no se puede deshacer.';

  @override
  String get ram_warning => 'Advertencia de RAM';

  @override
  String get recommended => 'RECOMENDADO';

  @override
  String get may_be_large => 'Puede ser demasiado grande para este dispositivo';

  @override
  String get calculating => 'Calculando...';

  @override
  String get download_failed => 'Descarga fallida';

  @override
  String get downloaded => 'Descargado';

  @override
  String get not_downloaded => 'No descargado';

  @override
  String get installed => 'Instalado';

  @override
  String get not_installed => 'No instalado';

  @override
  String get loading => 'Cargando...';

  @override
  String get thinking => 'Pensando';

  @override
  String get processing => 'Procesando...';

  @override
  String get initializing => 'Inicializando...';

  @override
  String get ready => 'Listo';

  @override
  String get preparing_app => 'Preparando aplicación...';

  @override
  String get initializing_services => 'Inicializando servicios...';

  @override
  String get configuring_server => 'Configurando servidor...';

  @override
  String get startup_failed => 'Fallo en el inicio';

  @override
  String get something_went_wrong => 'Algo salió mal';

  @override
  String get delete_model_title => 'Eliminar modelo';

  @override
  String delete_model_body(String name) {
    return '¿Está seguro de que desea eliminar $name?';
  }

  @override
  String delete_model_body_with_size(String name, String size) {
    return '¿Está seguro de que desea eliminar $name? Esto liberará aproximadamente $size de espacio.\n\nPuede volver a descargar este modelo más tarde si es necesario.';
  }

  @override
  String get delete_voice_title => 'Eliminar voz';

  @override
  String delete_voice_body(String name, String size) {
    return '¿Está seguro de que desea eliminar $name? Esto liberará aproximadamente $size de espacio.\n\nPuede volver a descargar esta voz más tarde si es necesario.';
  }

  @override
  String get delete_server_title => 'Eliminar servidor';

  @override
  String delete_server_body(String name) {
    return '¿Está seguro de que desea eliminar \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String get delete_conversation_title => '¿Eliminar conversación?';

  @override
  String delete_conversation_body(String title) {
    return '¿Está seguro de que desea eliminar \"$title\"? Esto no se puede deshacer.';
  }

  @override
  String get delete_message_title => '¿Eliminar mensaje?';

  @override
  String delete_persona_title(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get delete_persona_body => 'Esto no se puede deshacer.';

  @override
  String get clear_conversation_title => '¿Limpiar conversación?';

  @override
  String get clear_conversation_body =>
      'Esto eliminará todos los mensajes de esta conversación.';

  @override
  String get clear => 'Limpiar';

  @override
  String label_completed(String label) {
    return '$label completado';
  }

  @override
  String error_with_message(String error) {
    return 'Error: $error';
  }

  @override
  String preview_failed(String error) {
    return 'Vista previa fallida: $error';
  }

  @override
  String loading_model(String modelId) {
    return 'Cargando $modelId...';
  }

  @override
  String model_loaded(String modelId, String backend) {
    return 'Modelo cargado: $modelId ($backend)';
  }

  @override
  String get no_model_loaded =>
      'Ningún modelo cargado. Toque \"Gestionar modelos locales\" para descargar y cargar un modelo.';

  @override
  String loading_model_error(String error) {
    return 'Error: $error';
  }

  @override
  String get delete_conversation => '¿Eliminar conversación?';

  @override
  String get nav_history => 'Historial';

  @override
  String get nav_servers => 'Servidores';

  @override
  String get nav_local_models => 'Modelos locales';

  @override
  String get nav_tts => 'Texto a voz';

  @override
  String get nav_personas => 'Personajes';

  @override
  String get nav_settings => 'Ajustes';

  @override
  String get nav_new_chat => 'Nuevo chat';

  @override
  String get search_hint => 'Buscar conversaciones...';

  @override
  String get no_server_selected => 'Ningún servidor seleccionado';

  @override
  String get switch_server => 'Cambiar de servidor';

  @override
  String get switch_server_subtitle => 'Elija un servidor al que conectarse';

  @override
  String get manage_servers => 'Gestionar servidores';

  @override
  String get open_source => 'Código abierto';

  @override
  String get open_source_desc =>
      'LocalMind es de código abierto. Siga nuestro progreso o contribuya en GitHub.';

  @override
  String get star_on_github => 'Dar estrella en GitHub';

  @override
  String get add_more => 'Añadir más';

  @override
  String get on_github => 'en GitHub';

  @override
  String get could_not_open_github => 'No se pudo abrir GitHub.';

  @override
  String get settings_title => 'Ajustes';

  @override
  String get settings_appearance => 'Apariencia';

  @override
  String get settings_language => 'Idioma';

  @override
  String get language_system_default => 'Predeterminado del sistema';

  @override
  String get settings_tts => 'Texto a voz';

  @override
  String get settings_behavior => 'Comportamiento';

  @override
  String get settings_on_device => 'Inferencia local';

  @override
  String get settings_default_server => 'Servidor predeterminado';

  @override
  String get settings_default_persona => 'Personaje predeterminado';

  @override
  String get settings_privacy => 'Privacidad';

  @override
  String get settings_data_management => 'Gestión de datos';

  @override
  String get settings_about => 'Acerca de';

  @override
  String get theme => 'Tema';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Oscuro';

  @override
  String get theme_claude => 'Claude';

  @override
  String get font_size => 'Tamaño de fuente';

  @override
  String get font_size_desc => 'Ajustar el tamaño del texto en el chat.';

  @override
  String get font_preview =>
      'El rápido zorro marrón salta sobre el perro perezoso.';

  @override
  String get code_theme_dark => 'Tema de código (Oscuro)';

  @override
  String get code_theme_light => 'Tema de código (Claro)';

  @override
  String get code_theme_desc =>
      'Elija el tema de resaltado de sintaxis para los bloques de código.';

  @override
  String get tts_engine => 'Motor TTS';

  @override
  String get tts_engine_system => 'TTS del sistema';

  @override
  String get tts_engine_kitten => 'Kitten TTS';

  @override
  String get voice => 'Voz';

  @override
  String get voice_female => 'Femenino';

  @override
  String get voice_male => 'Masculino';

  @override
  String get voice_other => 'Otro';

  @override
  String get tts_speed => 'Velocidad de TTS';

  @override
  String get tts_speed_desc => 'Ajustar la velocidad de reproducción.';

  @override
  String get manage_tts_models => 'Gestionar modelos TTS';

  @override
  String get manage_on_device_models => 'Gestionar modelos locales';

  @override
  String get enable_smart_reply => 'Respuestas inteligentes locales';

  @override
  String get streaming_responses => 'Respuestas en tiempo real (streaming)';

  @override
  String get auto_generate_titles => 'Autogenerar títulos';

  @override
  String get send_on_enter => 'Enviar al presionar Enter';

  @override
  String get show_system_messages => 'Mostrar mensajes del sistema';

  @override
  String get haptic_feedback => 'Comentarios hápticos';

  @override
  String get enable_mcp => 'Habilitar MCP';

  @override
  String get new_chat_mcp_default => 'Nuevo chat MCP predeterminado';

  @override
  String get show_data_indicator => 'Mostrar indicador de datos';

  @override
  String get privacy_info => '\"LocalMind nunca ve sus datos\"';

  @override
  String get delete_all_conversations => 'Eliminar todas las conversaciones';

  @override
  String get reset_settings_defaults =>
      'Restablecer ajustes a los predeterminados';

  @override
  String get chat_title => 'LocalMind';

  @override
  String get chat_parameters_tooltip => 'Parámetros del chat';

  @override
  String get change_persona => 'Cambiar personaje';

  @override
  String get set_persona => 'Establecer personaje';

  @override
  String get remove_persona => 'Eliminar personaje';

  @override
  String get clear_conversation => 'Limpiar conversación';

  @override
  String get connection_error => 'Error de conexión. Compruebe su servidor.';

  @override
  String get disconnected => 'Desconectado del servidor.';

  @override
  String get configure => 'Configurar';

  @override
  String get select_model => 'Seleccionar modelo';

  @override
  String get select_persona => 'Seleccionar personaje';

  @override
  String get start_conversation => 'Comenzar una conversación';

  @override
  String get recent_chats => 'Chats recientes';

  @override
  String get see_all => 'Ver todo';

  @override
  String get quick_write => 'Ayúdame a escribir una función';

  @override
  String get quick_explain => 'Explica este código';

  @override
  String get quick_debug => 'Depura esto por mí';

  @override
  String get quick_async => '¿Cómo uso async/await?';

  @override
  String get history_missing_title => 'Historial faltante';

  @override
  String get history_missing_desc =>
      'O bien los mensajes de este chat fueron eliminados o el registro de historial está dañado.';

  @override
  String get technical_details => 'Detalles técnicos';

  @override
  String get last_error => 'Último error:';

  @override
  String get copy_info => 'Copiar información';

  @override
  String get conversation_id => 'ID de conversación';

  @override
  String get created_at => 'Creado el';

  @override
  String get expected_messages => 'Mensajes esperados';

  @override
  String get debug_dialog_desc =>
      'Información de diagnóstico para ayudar a identificar problemas de sincronización.';

  @override
  String get chat_input_hint => 'Pregunte cualquier cosa';

  @override
  String get send_message_tooltip => 'Enviar mensaje';

  @override
  String get stop_generation_tooltip => 'Detener generación';

  @override
  String get attach_images_tooltip => 'Adjuntar imágenes';

  @override
  String tool_label(String toolCallId) {
    return 'Herramienta: $toolCallId';
  }

  @override
  String get tool_unknown => 'Herramienta: Desconocida';

  @override
  String get message_options => 'Opciones de mensaje';

  @override
  String get copy_markdown => 'Copiar como Markdown';

  @override
  String get copied_markdown => 'Copiado como Markdown';

  @override
  String get read_aloud => 'Leer en voz alta';

  @override
  String get stop_reading => 'Detener lectura';

  @override
  String get more => 'Más';

  @override
  String character_count(int length) {
    return '$length caracteres';
  }

  @override
  String get edit_message => 'Editar mensaje';

  @override
  String get edit_message_desc =>
      'Al guardar se eliminará la respuesta del asistente que aparece a continuación y se volverá a generar.';

  @override
  String get save_regenerate => 'Guardar y regenerar';

  @override
  String get chat_settings_title => 'Ajustes de chat';

  @override
  String get reset_defaults => 'Restablecer valores predeterminados';

  @override
  String get parameters_tab => 'Parámetros';

  @override
  String get mcp_tab => 'MCP';

  @override
  String get temperature => 'Temperatura';

  @override
  String get temperature_desc =>
      'Controla la aleatoriedad: Mayor = Creativo, Menor = Enfocado';

  @override
  String get top_p => 'Top P';

  @override
  String get top_p_desc => 'Umbral de muestreo de núcleo';

  @override
  String get max_tokens => 'Máximo de tokens';

  @override
  String get max_tokens_desc => 'Límite de respuesta';

  @override
  String get context_length => 'Longitud del contexto';

  @override
  String get context_length_desc => 'Ventana de historial';

  @override
  String get mcp_disabled_warning =>
      'MCP está deshabilitado globalmente. Habilítelo en Ajustes para usar estas funciones.';

  @override
  String get mcp_enable_chat => 'Habilitar MCP para este chat';

  @override
  String get auto_execute_tools => 'Ejecutar herramientas automáticamente';

  @override
  String get beta_label => 'Beta';

  @override
  String get experimental_label => 'Experimental';

  @override
  String get add_ephemeral_mcp => 'Añadir servidor MCP efímero';

  @override
  String get mcp_label_placeholder => 'Etiqueta';

  @override
  String get mcp_url_placeholder => 'URL (https://...)';

  @override
  String get active_integrations => 'Integraciones activas';

  @override
  String get enable_notifications => 'Habilitar notificaciones';

  @override
  String get enable_notifications_desc =>
      'Reciba notificaciones cuando los modelos terminen de descargarse.';

  @override
  String get chat_history_title => 'Historial de chat';

  @override
  String get conversation_just_now => 'Hace un momento';

  @override
  String conversation_minutes_ago(int minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String conversation_hours_ago(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String get conversation_yesterday => 'Ayer';

  @override
  String conversation_days_ago(int days) {
    return 'hace ${days}d';
  }

  @override
  String conversation_date(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get options_tooltip => 'Opciones';

  @override
  String get no_results_found => 'No se encontraron resultados';

  @override
  String get no_conversations_yet => 'Aún sin conversaciones';

  @override
  String get try_different_search =>
      'Pruebe con un término de búsqueda diferente';

  @override
  String get start_new_conversation => 'Comenzar una nueva conversación';

  @override
  String get rename_conversation => 'Renombrar conversación';

  @override
  String get enter_new_title => 'Introduzca un nuevo título';

  @override
  String get pinned_section => 'FIJADOS';

  @override
  String get today_section => 'HOY';

  @override
  String get yesterday_section => 'AYER';

  @override
  String get previous_7_days => 'ÚLTIMOS 7 DÍAS';

  @override
  String get previous_30_days => 'ÚLTIMOS 30 DÍAS';

  @override
  String get older_section => 'MÁS ANTIGUOS';

  @override
  String get onboarding_choose_language => 'Elija el idioma';

  @override
  String get onboarding_choose_language_desc =>
      'Seleccione su idioma preferido. Puede cambiar esto en cualquier momento en la configuración.';

  @override
  String get onboarding_localmind => 'LOCALMIND';

  @override
  String get onboarding_connect_server => 'Conecte su\nservidor';

  @override
  String get onboarding_connect_desc =>
      'Conéctese a LM Studio, Ollama o\nOpenRouter para comenzar su experiencia\nprivada de IA.';

  @override
  String get openai_compatible_api => 'API compatible con OpenAI';

  @override
  String get https_requires_ssl => 'HTTPS requiere SSL';

  @override
  String get most_local_setups_use_http =>
      'La mayoría de las configuraciones locales usan http://';

  @override
  String get onboarding_welcome => 'Bienvenido a LocalMind';

  @override
  String get server_type_on_device => 'Local';

  @override
  String get server_type_on_device_sub => 'NO SE REQUIERE SERVIDOR';

  @override
  String get server_type_lm_studio => 'LM Studio';

  @override
  String get server_type_lm_studio_sub => 'API LOCAL';

  @override
  String get server_type_ollama => 'Ollama';

  @override
  String get server_type_ollama_sub => 'MOTOR CLI';

  @override
  String get server_type_openrouter => 'OpenRouter';

  @override
  String get server_type_openrouter_sub => 'NUBE UNIFICADA';

  @override
  String get ready_continue => 'LISTO PARA CONTINUAR';

  @override
  String get waiting_selection => 'ESPERANDO SELECCIÓN';

  @override
  String get setup_connection => 'Configurar conexión';

  @override
  String setup_connection_desc(String server) {
    return 'Configure su servidor $server para comenzar a chatear.';
  }

  @override
  String get server_name => 'Nombre de servidor';

  @override
  String get name_required => 'Nombre requerido';

  @override
  String get name_max_50 => 'Máx. 50 caracteres';

  @override
  String get host_label => 'Host / Dirección IP';

  @override
  String get host_required => 'Host requerido';

  @override
  String get port_label => 'Puerto';

  @override
  String get port_required => 'Puerto requerido';

  @override
  String get port_invalid => 'Debe ser un número';

  @override
  String get port_range => 'Introduzca un puerto válido (1-65535)';

  @override
  String get api_key_required => 'Clave API *';

  @override
  String get api_key_optional => 'Clave API (Opcional)';

  @override
  String get api_key_required_openrouter =>
      'Clave API requerida para OpenRouter';

  @override
  String get api_key_format =>
      'Las claves de API de OpenRouter comienzan con sk-';

  @override
  String get my_server_hint => 'Mi servidor';

  @override
  String get name_length_validation =>
      'El nombre debe tener 50 caracteres o menos';

  @override
  String get host_valid => 'Introduzca un nombre de host o dirección IP válida';

  @override
  String get api_key_hint_openrouter => 'sk-...';

  @override
  String get api_key_hint_generic => 'Para servidores autenticados';

  @override
  String get update_server => 'Actualizar servidor';

  @override
  String get save_server => 'Guardar servidor';

  @override
  String get server_updated => 'Servidor actualizado';

  @override
  String get server_added => 'Servidor añadido';

  @override
  String get download_model_title => 'Descargar un modelo';

  @override
  String get download_model_desc =>
      'Elija un modelo para descargar.\nSe ejecutará localmente en su dispositivo.';

  @override
  String get on_device_android_only =>
      'La inferencia local está disponible actualmente solo en Android.';

  @override
  String get total_ram => 'RAM total';

  @override
  String get available => 'Disponible';

  @override
  String ram_min_required(String fileSize) {
    return '$fileSize GB de RAM mín.';
  }

  @override
  String download_progress(String percent, String speed) {
    return '$percent% • $speed';
  }

  @override
  String eta_label(String eta) {
    return 'Tiempo restante: $eta';
  }

  @override
  String paused_progress(String percent) {
    return 'Pausado - $percent%';
  }

  @override
  String ram_warning_body_download(String ram, String totalMemory) {
    return 'Este modelo requiere al menos $ram GB de RAM, pero su dispositivo tiene $totalMemory. Es posible que no se ejecute correctamente o que cause el cierre de la aplicación.';
  }

  @override
  String ram_warning_body_load(String availableRAM, String ram) {
    return 'Su dispositivo tiene $availableRAM de RAM disponible, pero este modelo recomienda al menos $ram GB. Cargarlo podría fallar o causar inestabilidad.';
  }

  @override
  String get choose_theme => 'Elegir tema';

  @override
  String get choose_theme_desc =>
      'Personalice la apariencia de la aplicación. Siempre puede cambiar esto más tarde en los ajustes.';

  @override
  String get theme_card_system => 'Sistema';

  @override
  String get theme_card_system_sub =>
      'Coincide con los ajustes de su dispositivo';

  @override
  String get theme_card_light => 'Claro';

  @override
  String get theme_card_light_sub => 'Limpio y brillante';

  @override
  String get theme_card_dark => 'Oscuro';

  @override
  String get theme_card_dark_sub => 'Fácil para los ojos';

  @override
  String get theme_card_claude => 'Claude';

  @override
  String get theme_card_claude_sub => 'Un tema cálido con tonos durazno';

  @override
  String get stay_updated => 'Manténgase al día';

  @override
  String get stay_updated_desc =>
      'Reciba notificaciones cuando sus modelos de IA terminen de descargarse o cuando se completen tareas largas.';

  @override
  String get notification_benefit_downloads =>
      'Progreso de descarga del modelo';

  @override
  String get notification_benefit_completions => 'Completados de generación';

  @override
  String get notification_benefit_background =>
      'Estado de las tareas en segundo plano';

  @override
  String get allow_notifications => 'Permitir notificaciones';

  @override
  String get servers_title => 'Servidores';

  @override
  String get no_servers_yet => 'Aún sin servidores';

  @override
  String get no_servers_desc =>
      'Añada su primer servidor para comenzar a chatear con modelos de IA.';

  @override
  String get add_server => 'Añadir servidor';

  @override
  String switched_to_server(String name) {
    return 'Cambiado a $name';
  }

  @override
  String get edit_server => 'Editar servidor';

  @override
  String get add_server_title => 'Añadir servidor';

  @override
  String get server_type_label => 'Tipo de servidor';

  @override
  String get server_icon_label => 'Icono de servidor';

  @override
  String get default_icon => 'Icono predeterminado';

  @override
  String get server_type_lm_studio_display => 'LM Studio';

  @override
  String get server_type_openai_display => 'Compatible con OpenAI';

  @override
  String get server_type_ollama_display => 'Ollama';

  @override
  String get server_type_openrouter_display => 'OpenRouter';

  @override
  String get server_type_on_device_display => 'Local';

  @override
  String get server_address_openrouter => 'openrouter.ai';

  @override
  String get server_address_on_device => 'Inferencia local';

  @override
  String server_address_format(String host, String port) {
    return '$host:$port';
  }

  @override
  String get default_badge => 'Predeterminado';

  @override
  String get set_as_default => 'Establecer como predeterminado';

  @override
  String get select_icon => 'Seleccionar icono';

  @override
  String get select_icon_desc => 'Elija un icono para su servidor';

  @override
  String get search_icons_hint => 'Buscar iconos...';

  @override
  String get server_icon_stack => 'Pila de servidores';

  @override
  String get server_icon_stack2 => 'Pila de servidores 02';

  @override
  String get server_icon_stack3 => 'Pila de servidores 03';

  @override
  String get server_icon_cloud => 'Nube';

  @override
  String get server_icon_cloud_server => 'Servidor en la nube';

  @override
  String get server_icon_mcp => 'Servidor MCP';

  @override
  String get server_icon_database => 'Base de datos';

  @override
  String get server_icon_database1 => 'Base de datos 01';

  @override
  String get server_icon_database2 => 'Base de datos 02';

  @override
  String get server_icon_cpu => 'CPU';

  @override
  String get server_icon_chip => 'Chip';

  @override
  String get server_icon_chip2 => 'Chip 02';

  @override
  String get server_icon_computer => 'Computadora';

  @override
  String get server_icon_laptop => 'Laptop';

  @override
  String get server_icon_terminal => 'Terminal de computadora';

  @override
  String get server_icon_code => 'Código';

  @override
  String get server_icon_ai_brain => 'Cerebro de IA';

  @override
  String get server_icon_ai_brain2 => 'Cerebro de IA 02';

  @override
  String get server_icon_ai_cloud => 'Nube de IA';

  @override
  String get server_icon_ai_network => 'Red de IA';

  @override
  String get server_icon_ai_chat => 'Chat de IA';

  @override
  String get server_icon_cellular => 'Red celular';

  @override
  String get server_icon_plug1 => 'Enchufe 01';

  @override
  String get server_icon_plug2 => 'Enchufe 02';

  @override
  String get server_icon_bot => 'Bot';

  @override
  String get server_icon_bot2 => 'Bot 02';

  @override
  String get server_icon_robotic => 'Robótico';

  @override
  String get server_icon_rocket => 'Cohete';

  @override
  String get server_icon_star => 'Estrella';

  @override
  String get server_icon_settings1 => 'Ajustes 01';

  @override
  String get server_icon_settings2 => 'Ajustes 02';

  @override
  String get server_icon_home1 => 'Inicio 01';

  @override
  String get server_icon_home2 => 'Inicio 02';

  @override
  String get server_icon_folder1 => 'Carpeta 01';

  @override
  String get server_icon_folder2 => 'Carpeta 02';

  @override
  String get server_icon_file1 => 'Archivo 01';

  @override
  String get server_icon_lock => 'Bloqueo';

  @override
  String get server_icon_key => 'Clave 01';

  @override
  String get server_icon_link => 'Enlace 01';

  @override
  String get server_icon_globe => 'Globo';

  @override
  String get server_icon_api => 'API';

  @override
  String get server_icon_arrow_right => 'Flecha derecha 01';

  @override
  String get server_icon_check => 'Círculo de verificación';

  @override
  String get server_icon_alert => 'Círculo de alerta';

  @override
  String get server_icon_info => 'Círculo de información';

  @override
  String get server_icon_zap => 'Zap';

  @override
  String get server_icon_cloud_upload => 'Subida a la nube';

  @override
  String get server_icon_cloud_download => 'Descarga en la nube';

  @override
  String get server_icon_refresh => 'Actualizar';

  @override
  String get server_icon_hard_drive => 'Disco duro';

  @override
  String get server_icon_drive => 'Unidad';

  @override
  String get personas_title => 'Personajes';

  @override
  String get persona_category_general => 'General';

  @override
  String get persona_category_coding => 'Programación';

  @override
  String get persona_category_education => 'Educación';

  @override
  String get persona_category_creative => 'Creativo';

  @override
  String get persona_builtin_section => 'INTEGRADO';

  @override
  String get persona_my_section => 'MIS PERSONAJES';

  @override
  String get clone_edit => 'Clonar y editar';

  @override
  String get builtin_badge => 'Integrado';

  @override
  String get no_personas_found => 'No se encontraron personajes';

  @override
  String get no_personas_desc =>
      'Cree su primer personaje para personalizar el comportamiento de la IA.';

  @override
  String get edit_persona => 'Editar personaje';

  @override
  String get create_persona => 'Crear personaje';

  @override
  String get create_persona_button => 'Crear';

  @override
  String get emoji_label => 'Emoji';

  @override
  String get name_label => 'Nombre';

  @override
  String get my_persona_hint => 'Mi personaje';

  @override
  String get category_label => 'Categoría';

  @override
  String get description_optional => 'Descripción (opcional)';

  @override
  String get description_hint => 'Lo que hace este personaje...';

  @override
  String get system_prompt => 'Instrucción del sistema';

  @override
  String character_count_max(int currentLen) {
    return '$currentLen/4000';
  }

  @override
  String get no_prompt_placeholder => 'Aún sin indicaciones...';

  @override
  String get prompt_hint => 'Usted es un asistente servicial...';

  @override
  String get prompt_required => 'La instrucción del sistema es requerida';

  @override
  String get prompt_max_chars => 'Máx. 4000 caracteres';

  @override
  String get advanced_settings => 'Ajustes avanzados';

  @override
  String get temperature_label => 'Temperatura (0.0-2.0)';

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
  String get persona_updated => 'Personaje actualizado';

  @override
  String get persona_created => 'Personaje creado';

  @override
  String get tts_models_title => 'Modelos de texto a voz';

  @override
  String get always_available => 'Siempre disponible';

  @override
  String get tts_system_desc =>
      'Utiliza el motor de texto a voz integrado de su dispositivo.\nNo requiere descargas. La selección de voz utiliza los ajustes del sistema de su dispositivo.';

  @override
  String get downloading_status => 'Descargando...';

  @override
  String tts_kitten_desc(String size) {
    return 'TTS neural ultrarrápido con 8 voces expresivas.\nRequiere descarga de $size.';
  }

  @override
  String tts_piper_desc(String size) {
    return 'Voces Piper sin conexión rápidas con 2 voces expresivas.\nRequiere una descarga de $size por voz.';
  }

  @override
  String engine_spec(String sizeMb, String ramMb, int voiceCount) {
    return '$sizeMb MB · $ramMb MB de RAM · $voiceCount voces';
  }

  @override
  String get on_device_models_title => 'Modelos locales';

  @override
  String get available_models => 'Modelos disponibles';

  @override
  String get device_memory => 'Memoria del dispositivo';

  @override
  String get ram_usage => 'Uso de RAM';

  @override
  String get memory_healthy => 'Saludable';

  @override
  String get memory_critical => 'Crítico';

  @override
  String get memory_low => 'Bajo';

  @override
  String ram_used(String percent) {
    return '$percent% usado';
  }

  @override
  String get available_ram => 'RAM disponible';

  @override
  String get total_capacity => 'Capacidad total';

  @override
  String get loaded_status => 'Cargado';

  @override
  String get inference_backend => 'Motor de inferencia';

  @override
  String get backend_ios_notice =>
      'Solo el motor de CPU está disponible en iOS.';

  @override
  String get backend_cpu_desc =>
      'Funciona en todos los dispositivos. Más compatible.';

  @override
  String get backend_gpu_desc =>
      'Aceleración OpenCL. Más rápido en dispositivos compatibles.';

  @override
  String get backend_npu_desc =>
      'NPU del fabricante (Qualcomm/MediaTek). Inferencia más rápida.';

  @override
  String get select_model_title => 'Seleccionar modelo';

  @override
  String get refresh_models => 'Actualizar modelos';

  @override
  String get search_models_hint => 'Buscar modelos...';

  @override
  String get no_server_connected => 'Ningún servidor conectado';

  @override
  String get add_server_first =>
      'Añada un servidor primero para ver los modelos disponibles.';

  @override
  String get failed_load_models => 'No se pudieron cargar los modelos';

  @override
  String get no_models_available => 'No hay modelos disponibles';

  @override
  String no_models_match(String searchQuery) {
    return 'Ningún modelo coincide con \"$searchQuery\"';
  }

  @override
  String model_load_failed(String error) {
    return 'No se pudo cargar el modelo: $error';
  }

  @override
  String model_unloaded_ollama(String name) {
    return '$name se liberará de la memoria una vez que pase el tiempo de espera activo';
  }

  @override
  String model_unloaded_success(String name) {
    return '$name liberado de memoria correctamente';
  }

  @override
  String model_unload_failed(String error) {
    return 'No se pudo descargar el modelo de la memoria: $error';
  }

  @override
  String get unload_from_server => 'Liberar del servidor';

  @override
  String context_chip(String ctx) {
    return '$ctx ctx';
  }

  @override
  String download_notification_title(String modelName) {
    return 'Descargando $modelName...';
  }

  @override
  String get download_complete_notification => '¡Descarga completa!';

  @override
  String download_complete_body(String modelName) {
    return '$modelName se ha descargado correctamente.';
  }

  @override
  String download_failed_notification(String error) {
    return 'Descarga fallida: $error';
  }

  @override
  String download_failed_body(String modelName) {
    return 'No se pudo descargar $modelName.';
  }

  @override
  String get engine_name_system => 'TTS del sistema';

  @override
  String get engine_tagline_system => 'Motor integrado en el dispositivo';

  @override
  String get engine_name_kitten => 'Kitten TTS';

  @override
  String get engine_tagline_kitten => 'TTS neural de alta velocidad';

  @override
  String get engine_name_sherpa => 'Sherpa ONNX VITS';

  @override
  String get engine_tagline_sherpa => 'Voces Piper sin conexión';

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
      'Modelo de chat de propósito general más pequeño. Respuestas rápidas, bajo uso de memoria.';

  @override
  String get model_license_apache => 'Apache-2.0';

  @override
  String get model_qwen_25 => 'Qwen 2.5 1.5B Instruct';

  @override
  String get model_qwen_25_desc =>
      'Calidad y tamaño equilibrados. Bueno para conversación general.';

  @override
  String get model_deepseek => 'DeepSeek R1 Distill Qwen 1.5B';

  @override
  String get model_deepseek_desc =>
      'Modelo de razonamiento y cadena de pensamiento. El mejor para tareas lógicas.';

  @override
  String get model_license_mit => 'MIT';

  @override
  String get model_gemma => 'Gemma 4 E2B Instruct';

  @override
  String get model_gemma_desc =>
      'Modelo insignia de Google. Máxima calidad, requiere más RAM.';

  @override
  String export_header(String date) {
    return '*Exportado de LocalMind — $date*';
  }

  @override
  String get export_role_user => '## 👤 Usuario';

  @override
  String get export_role_assistant => '## 🤖 Asistente';

  @override
  String get export_role_system => '## ⚙️ Sistema';

  @override
  String get export_role_tool => '## 🔧 Herramienta';

  @override
  String get export_text_user => '[USUARIO]';

  @override
  String get export_text_assistant => '[ASISTENTE]';

  @override
  String get export_text_system => '[SISTEMA]';

  @override
  String get export_text_tool => '[HERRAMIENTA]';

  @override
  String get export_label_user => 'USUARIO';

  @override
  String get export_label_assistant => 'ASISTENTE';

  @override
  String get export_label_system => 'SISTEMA';

  @override
  String get export_label_tool => 'HERRAMIENTA';

  @override
  String get select_model_hint => 'Seleccione un modelo para empezar a chatear';

  @override
  String get test_notification_title => 'Notificación de prueba';

  @override
  String get test_notification_body =>
      'Esta es una notificación de prueba para el progreso de descarga de modelos.';

  @override
  String get tts_supports_background =>
      'Soporta reproducción en segundo plano como audio nativo';

  @override
  String get tts_other_services_background_note =>
      'Nota: Los otros servicios de TTS soportan reproducción en segundo plano como audio nativo.';
}
