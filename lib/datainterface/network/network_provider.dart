import 'dart:async';
import 'dart:convert';
import 'package:adhara/config.dart';
import 'package:socket_io/socket_io.dart';
import 'package:http/http.dart' as http;

abstract class NetworkProvider {
  Config config;
  SocketIO socket;
  NetworkProvider(this.config) {
    assert(this.baseURL.endsWith("/"));
  }

  String get baseURL => this.config.baseURL;

  load() async {
//    socket = await createSocket(config.webSocketURL);
//    await registerSocketEvents(socket);
  }

  dynamic formatResponse(Map data) {
    return data;
  }

  dynamic extractResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw response;
    }
    try {
      return formatResponse(json.decode(response.body));
    } catch (e) {
      return response.body;
    }
  }

  Map<String, String> get defaultHeaders {
    return {"Content-Type": "application/json"};
  }

  formatURL(String url) {
    assert(!url.startsWith("/"));
    return baseURL + url;
  }

  preFlightIntercept(String method, String url, dynamic data) {
    return;
  }

  _preFlightIntercept(String method, String url, dynamic data) {
    preFlightIntercept(method, url, data);
  }

  postResponseIntercept(
      String method, String url, dynamic data, http.Response response) async {
    return;
  }

  _postResponseIntercept(
      String method, String url, dynamic data, http.Response response) async {
    print(
        "http: $method $url with data: ${data ?? data.toString()} response: ${response.statusCode} \n ${response.body}");
    postResponseIntercept(method, url, data, response);
  }

  Future<dynamic> get(String url, {Map headers}) async {
    url = this.formatURL(url);
    _preFlightIntercept("GET", url, null);
    http.Response r =
        await http.get(url, headers: headers ?? this.defaultHeaders);
    await _postResponseIntercept("GET", url, null, r);
    return this.extractResponse(r);
  }

  Future<dynamic> post(String url, Map data, {Map headers}) async {
    url = this.formatURL(url);
    _preFlightIntercept("POST", url, data);
    http.Response r = await http.post(url,
        body: json.encode(data), headers: headers ?? this.defaultHeaders);
    await _postResponseIntercept("POST", url, data, r);
    return this.extractResponse(r);
  }

  Future<dynamic> put(String url, Map data, {Map headers}) async {
    url = this.formatURL(url);
    _preFlightIntercept("PUT", url, data);
    http.Response r = await http.put(url,
        body: json.encode(data), headers: headers ?? this.defaultHeaders);
    await _postResponseIntercept("PUT", url, data, r);
    return this.extractResponse(r);
  }

  Future<dynamic> delete(String url, {Map headers}) async {
    url = this.formatURL(url);
    _preFlightIntercept("DELETE", url, null);
    http.Response r =
        await http.delete(url, headers: headers ?? this.defaultHeaders);
    await _postResponseIntercept("DELETE", url, null, r);
    return this.extractResponse(r);
  }

  // WebSocket related handling...
  Future<SocketIO> createSocket([String uri]) async {
    final _socket = await SocketIO.createNewInstance(uri??config.webSocketURL);
    await _socket.on(SocketIOEvent.connecting, () async {
      print('Connecting...');
    });
    await _socket.on(SocketIOEvent.connect, () async {
      print('Connected.');
      final id = await _socket.id;
      print('Client SocketID: $id');
    });
    await _socket.on(SocketIOEvent.connectError, (error) {
      print('Error: $error');
    });
    await _socket.connect();
    return _socket;
  }

//  Future registerSocketEvents(SocketIO socket) async {}

}
