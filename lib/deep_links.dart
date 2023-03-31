import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class Failure {}

abstract class DeepLinkRoute {
  String route();
}

class PostRoute extends DeepLinkRoute {
  late String postId;

  PostRoute({required Uri uri}) {
    final Map<String, String> params = uri.queryParameters;
    params['id'] == null ? throw const FormatException() : postId = params['id']!;
  }

  @override
  String route() => "/home/detail";
}

class DeepLinkStream {
  final StreamController<Either<Failure, DeepLinkRoute>> _controller =
      StreamController<Either<Failure, DeepLinkRoute>>();
  late StreamSubscription<Either<Failure, DeepLinkRoute>> _subscription;

  DeepLinkStream() {
    initDeepLink();
  }

  StreamSubscription<Either<Failure, DeepLinkRoute>> listen(void Function(Either<Failure, DeepLinkRoute> link)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _subscription = _controller.stream.listen(onData);
    return _subscription;
  }

  void f(Uri link) {
    try {
      _controller.add(Right(PostRoute(uri: link)));
    } catch (_) {
      _controller.add(Left(Failure()));
    }
  }

  void initDeepLink() async {
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink != null) f(initialLink.link);

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
      f(dynamicLink.link);
    }, onError: (error) {
      _controller.addError(Left(Failure()));
    });
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
