part of bridge.http;

UrlGenerator _urlGenerator;

class HttpServiceProvider extends ServiceProvider {
  Server server;
  Router router;
  Program program;

  setUp(Application app,
        Server server,
        Router router,
        _ResponseMapper responseMapper,
        SessionManager manager,
        HttpConfig config) {
    this.server = server;
    this.router = router;

    _helperConfig = config;

    server.attachRouter(router);

    app.singleton(responseMapper);
    app.singleton(server, as: Server);
    app.singleton(router, as: Router);
    app.singleton(manager);
  }

  load(Program program,
       SessionsMiddleware sessionsMiddleware,
       CsrfMiddleware csrfMiddleware,
       StaticFilesMiddleware staticFilesMiddleware,
       InputMiddleware inputMiddleware,
       FormMethodMiddleware formMethodMiddleware,
       UrlGenerator urlGenerator) {
    _urlGenerator = urlGenerator;

    server.addMiddleware(sessionsMiddleware, highPriority: true);
    server.addMiddleware(staticFilesMiddleware);
    server.addMiddleware(inputMiddleware);
    server.addMiddleware(formMethodMiddleware);
    server.addMiddleware(csrfMiddleware);
    server.onError = (e, s) {
      print('');
      program.printDanger(new trace.Chain.forTrace(s).terse
      .toString().split('\n').toList().reversed.join('\n'));
      print('');
      program.printWarning('<underline>Uncaught HTTP exception</underline>');
      program.printDanger(e);
      print('');
    };

    this.program = program;
    program.addCommand(start);
    program.addCommand(stop);
    program.addCommand(routes);
  }

  tearDown() async {
    await stop();
  }

  @Command('Start the server')
  start() async {
    await server.start();
    program.printInfo('Server started on http://${server.hostname}:${server.port}');
  }

  @Command('Stop the server')
  stop() async {
    try {
      await server.stop();
      program.printInfo('Server stopped');
    } catch (e) {
    }
  }

  @Command('List all the end-points defined in the router')
  routes() async {
    var table = new dlog.Table(3);

    table.columns.addAll([
      'Method',
      'End-point',
      'Name',
    ]);

    for (var row in router._routes) {
      table.data.addAll([
        row.method,
        row.route,
        row.name == null ? '' : row.name,
      ]);
    }

    print(table);
  }
}
