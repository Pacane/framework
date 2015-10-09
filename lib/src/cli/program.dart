part of bridge.cli;

class BridgeCli extends Program {
  final Application app = new Application();
  final String _configPath;

  BridgeCli(String this._configPath, Shell shell) : super(shell) {
    app..singleton(this)..singleton(this, as: Program);
  }

  setUp() async {
    await app.setUp(_configPath);
    InputDevice.prompt = new Output('<cyan>=</cyan> ');
  }

  tearDown() async {
    await unwatch();
    await app.tearDown();
  }

  @override
  Future run({String bootArguments: '', stdinBroadcast, reloadPort}) {
    return super.run(
        bootArguments: bootArguments.replaceAll('--production', ''),
        stdinBroadcast: stdinBroadcast,
        reloadPort: reloadPort);
  }

  bool _watching = false;
  bool _reloading = false;
  StreamSubscription _watchSubscription;

  @Command('Watch your project files for changes')
  watch() async {
    if (_watching) {
      printWarning('Already watching!');
      return;
    }
    _watching = true;
    _watchSubscription =
        Directory.current.watch(recursive: true).listen((event) async {
          if (path.split(event.path).any((s) => s.startsWith('.'))) return;
          if (_reloading || path.basename(event.path).startsWith('.')) return;
          printAccomplishment('Reloading...');
          _reloading = true;
          await reload(['watch']);
        });
    printInfo('Watching files...');
  }

  @Command('Stop watching your project files for changes')
  unwatch() async {
    if (!_watching) return;
    await _watchSubscription.cancel();
    if (!_reloading)
      printInfo('Stopped watching files');
    _watching = false;
  }

  @Command('Build the projects client side assets using [pub build]')
  build() async {
    final commands = [];
    final public = new Directory(app.config('http.server.public_root', 'web'));
    final build = new Directory(app.config('http.server.build_root', 'build'));
    commands.add(_run('pub', ['build', '-o', build.path]));
    final List<File> files = await public
        .list(recursive: false)
        .where((e) => e.path.endsWith('.dart')).toList();
    for (final file in files)
      commands.add(
          _run('dart2js', [
            '-m',
            '-o',
            path.join(build.path, '${file.path}.js'),
            file.path,
          ]));
    await Future.wait(commands);
  }

  Future _run(String executable, List<String> arguments) async {
    printWarning('Executing: $executable ${arguments.join(' ')}');

    final process = await Process.start(executable, arguments);
    process.stdout.map(UTF8.decode)
        .map((s) => _colorizeOutput(executable, s)).listen(this.print);
    process.stderr.map(UTF8.decode)
        .map((s) => _colorizeOutput(executable, s)).listen(this.print);
    final exitCode = await process.exitCode;

    if (exitCode != 0)
      printDanger('Exited with exit code $exitCode');
    else
      printAccomplishment('Finished: $executable ${arguments.join(' ')}');
  }

  String _colorizeOutput(String executable, String line) {
    return '<gray>[<gray><cyan>$executable</cyan><gray>] ${line.trim()}</gray>';
  }
}
