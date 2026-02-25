import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) async {
    final uri = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: path,
    );
    return _FakeHttpClientRequest(uri);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _FakeHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(url);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.url);

  @override
  final Uri url;

  final _headers = _FakeHttpHeaders();

  @override
  Encoding encoding = utf8;

  @override
  bool bufferOutput = false;

  @override
  int contentLength = 0;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(_buildResponseBody(url));
  }

  String _buildResponseBody(Uri uri) {
    final path = uri.path;
    if (path.contains('/movies/now-showing')) {
      return jsonEncode({
        'data': [
          {
            '_id': 'm1',
            'title': 'Avatar 3',
            'genre': 'Sci-Fi',
            'rating': 'PG-13',
            'img': '',
            'year': 2026,
            'score': 8.3,
            'duration': '2h 45m',
            'synopsis': 'A sci-fi adventure.',
            'language': 'English',
            'status': 'now_showing',
          }
        ]
      });
    }

    if (path.contains('/movies/coming-soon')) {
      return jsonEncode({
        'data': [
          {
            '_id': 'm2',
            'title': 'Avengers Reborn',
            'genre': 'Action',
            'rating': 'PG-13',
            'img': '',
            'year': 2026,
            'score': 8.1,
            'duration': '2h 30m',
            'synopsis': 'A superhero action epic.',
            'language': 'English',
            'status': 'coming_soon',
          }
        ]
      });
    }

    if (path.contains('/showtimes/movie/')) {
      return jsonEncode({'data': []});
    }

    return jsonEncode({'data': []});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(String body)
      : _bytes = utf8.encode(body),
        _stream = Stream<List<int>>.value(utf8.encode(body));

  final List<int> _bytes;
  final Stream<List<int>> _stream;

  final _headers = _FakeHttpHeaders(contentType: ContentType.json);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  HttpHeaders get headers => _headers;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  Future<Socket> detachSocket() {
    throw UnsupportedError('detachSocket is not supported in tests');
  }

  @override
  int get hashCode => _bytes.hashCode;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  Future<bool> get isEmpty => _stream.isEmpty;

  @override
  Future<bool> any(bool Function(List<int> element) test) => _stream.any(test);

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) {
    return _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Future<E> drain<E>([E? futureValue]) => _stream.drain(futureValue);

  @override
  Future<List<int>> get first => _stream.first;

  @override
  Future<List<int>> get last => _stream.last;

  @override
  Future<int> get length => _stream.length;

  @override
  Future<List<int>> get single => _stream.single;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  _FakeHttpHeaders({ContentType? contentType}) : _contentType = contentType;

  final Map<String, List<String>> _values = {};
  ContentType? _contentType;

  @override
  ContentType? get contentType => _contentType;

  @override
  set contentType(ContentType? value) {
    _contentType = value;
    if (value != null) {
      set(HttpHeaders.contentTypeHeader, value.toString());
    }
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _values.putIfAbsent(key, () => <String>[]).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>[value.toString()];
  }

  @override
  void remove(String name, Object value) {
    final key = name.toLowerCase();
    _values[key]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _values.remove(name.toLowerCase());
  }

  @override
  String? value(String name) {
    final values = _values[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
