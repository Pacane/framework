part of bridge.tether.shared;

/// Represents a message being send from one [Tether] to another.
/// This is identified by the combination of its token and its key.
/// The token points to a specific session, and the key specifies
/// what handler should be responsible for responding to the
/// message.
class Message {
  final String key;
  final String token;
  int exception = -1;
  final dynamic data;
  String _returnToken;

  Message(String this.key, String this.token, this.data, [String this._returnToken]);

  factory Message.deserialize(String json) {
    return new Message._fromMap(JSON.decode(json));
  }

  factory Message._fromMap(Map data) {
    return new Message(data['key'], data['token'], data['data'], data['returnToken'])
      ..exception = data['exception'];
  }

  String get serialized => JSON.encode(
      {'key': key, 'token': token, 'data': data, 'returnToken': returnToken, 'exception': exception},
      toEncodable: (o) {
        try {
          try {
            return JSON.encode(o.serialize());
          } on NoSuchMethodError {
            if (o is Serializable)
              (() async => throw new TetherException('$o failed serialization!'))();
            return JSON.encode(o.toJson());
          }
        } on NoSuchMethodError {
          return JSON.encode(o.toString());
        }
      });

  String get returnToken {
    if (_returnToken != null) return _returnToken;
    _returnToken = generateToken();
    return _returnToken;
  }

  static String generateToken() {
    var o = '',
    rand = new Random(),
    chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (o.length < 50) o += chars[rand.nextInt(chars.length - 1)];
    return o;
  }
}
