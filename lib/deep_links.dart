import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

// todo: replace with custom error class
class Failure {}

abstract class DeepLinkRoute {
  String route();
}

//! types

class PostRoute extends DeepLinkRoute {
  late String postId;

  PostRoute({required Uri uri}) {
    final Map<String, String> params = uri.queryParameters;
    params['id'] == null ? throw const FormatException() : postId = params['id']!;
  }

  @override
  String route() => "/home/detail";
}

//! logic

class DeepLinkService {
  static const uriPrefix = "https://matthewtrent.page.link";
  static const imageUri = "https://matthewtrent.me/assets/biz-low-res.png";
  static const linkDescription = "Check it out on Confesi";
  static const androidPackageName = "com.example.notification_test";
  static const iOSBundleId = "com.example.notification_test";
  static const iOSAppStoreId = "123456789";

  Future<Either<String, Failure>> buildLink(String linkData, String mediaPreviewTitle) async {
    try {
      ShortDynamicLink link = await FirebaseDynamicLinks.instance.buildShortLink(
        DynamicLinkParameters(
          uriPrefix: uriPrefix,
          link: Uri.parse('$uriPrefix$linkData'),
          socialMetaTagParameters: SocialMetaTagParameters(
            title: mediaPreviewTitle,
            imageUrl: Uri.parse(imageUri),
            description: linkDescription,
          ),
          androidParameters: const AndroidParameters(
            packageName: androidPackageName,
          ),
          iosParameters: const IOSParameters(
            bundleId: iOSBundleId,
            appStoreId: iOSAppStoreId,
          ),
        ),
      );
      return Left(link.shortUrl.toString());
    } catch (_) {
      return Right(Failure());
    }
  }
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

  Either<Failure, DeepLinkRoute> _parseRoute(Uri link) {
    final String path = link.path;
    if (path == "/post") {
      return Right(PostRoute(uri: link));
    } else {
      return Left(Failure());
    }
  }

  void _f(Uri link) {
    try {
      _controller.add(_parseRoute(link));
    } catch (_) {
      _controller.add(Left(Failure()));
    }
  }

  void initDeepLink() async {
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink != null) _f(initialLink.link);

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
      _f(dynamicLink.link);
    }, onError: (error) {
      _controller.addError(Left(Failure()));
    });
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
