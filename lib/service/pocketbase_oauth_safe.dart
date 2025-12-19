import 'dart:async';

import 'package:pocketbase/pocketbase.dart';

/// Safe wrapper for PocketBase OAuth to avoid "Future already completed" crashes
/// when providers emit multiple realtime events.
extension SafeOAuthRecordService on RecordService {
  Future<RecordAuth> authWithOAuth2Safe(
    String providerName,
    OAuth2URLCallbackFunc urlCallback, {
    List<String> scopes = const [],
    Map<String, dynamic> createData = const {},
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    String? expand,
    String? fields,
  }) async {
    final authMethods = await listAuthMethods();

    final AuthMethodProvider provider;
    try {
      provider = authMethods.oauth2.providers
          .firstWhere((p) => p.name == providerName);
    } catch (_) {
      throw ClientException(
        originalError: Exception("missing provider $providerName"),
      );
    }

    final redirectURL = client.buildURL("/api/oauth2-redirect");
    final completer = Completer<RecordAuth>();
    Future<void> Function()? unsubscribeFunc;
    String? initialState;

    void completeSafe(FutureOr<RecordAuth> value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    void completeErrorSafe(Object err) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }

    try {
      unsubscribeFunc = await client.realtime.subscribe("@oauth2", (e) async {
        try {
          final eventData = e.jsonData();
          final code = eventData["code"] as String? ?? "";
          final state = eventData["state"] as String? ?? "";
          final error = eventData["error"] as String? ?? "";

          final expectedState = initialState ?? client.realtime.clientId;

          if (state.isEmpty || state != expectedState) {
            throw StateError("State parameters don't match.");
          }

          if (error.isNotEmpty || code.isEmpty) {
            throw StateError("OAuth2 redirect error or missing code.");
          }

          final auth = await authWithOAuth2Code(
            provider.name,
            code,
            provider.codeVerifier,
            redirectURL.toString(),
            createData: createData,
            body: body,
            query: query,
            headers: headers,
            expand: expand,
            fields: fields,
          );

          completeSafe(auth);

          if (unsubscribeFunc != null) {
            unawaited(unsubscribeFunc());
          }
        } catch (err) {
          final wrappedErr =
              err is ClientException ? err : ClientException(originalError: err);
          completeErrorSafe(wrappedErr);
        }
      });

      // capture the state after SSE connection is fully established
      initialState = client.realtime.clientId;
      if (initialState == null || initialState.isEmpty) {
        throw StateError("Missing realtime client id for OAuth2 flow.");
      }

      final authURL = Uri.parse(provider.authURL + redirectURL.toString());
      final queryParameters = Map<String, String>.of(authURL.queryParameters);
      queryParameters["state"] = initialState ?? "";

      if (scopes.isNotEmpty) {
        queryParameters["scope"] = scopes.join(" ");
      }

      urlCallback(authURL.replace(queryParameters: queryParameters));
    } catch (err) {
      final wrappedErr =
          err is ClientException ? err : ClientException(originalError: err);
      completeErrorSafe(wrappedErr);
    }

    return completer.future;
  }
}
