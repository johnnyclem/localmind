enum BootstrapStage {
  initializing,
  preparingApp,
  initializingServices,
  configuringServer,
  done,
  error,
}

class BootstrapState {
  final BootstrapStage stage;
  final String statusMessage;
  final Object? error;
  final double progress;

  const BootstrapState({
    this.stage = BootstrapStage.initializing,
    this.statusMessage = 'Initializing...',
    this.error,
    this.progress = 0.0,
  });
}
