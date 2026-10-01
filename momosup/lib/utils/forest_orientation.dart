import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ForestOrientation { portrait, landscape }

/// Only page navigation changes the policy. Dialogs and sheets keep the current
/// direction; returning from a preview restores the underlying page's policy.
final forestOrientationObserver = RouteObserver<PageRoute<dynamic>>();

class _OrientationRequests with WidgetsBindingObserver {
  _OrientationRequests() {
    WidgetsBinding.instance.addObserver(this);
  }
  final requests = <Object, ({ForestOrientation mode, bool active})>{};
  ForestOrientation? applied;
  bool queued = false;
  void update(Object key, ForestOrientation mode, bool active) {
    requests[key] = (mode: mode, active: active);
    sync();
  }

  void remove(Object key) {
    requests.remove(key);
    sync();
  }

  void sync() {
    if (queued) return;
    queued = true;
    scheduleMicrotask(() {
      queued = false;
      final active = requests.values.where((r) => r.active);
      final mode = active.lastOrNull?.mode ?? ForestOrientation.portrait;
      if (applied == mode) return;
      applied = mode;
      unawaited(
        SystemChrome.setPreferredOrientations(
          mode == ForestOrientation.landscape
              ? [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]
              : [DeviceOrientation.portraitUp],
        ).catchError((Object error) {
          applied = null;
          debugPrint('Screen orientation request failed: $error');
        }),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      applied = null;
      sync();
    }
  }
}

class ForestOrientationScope extends StatefulWidget {
  const ForestOrientationScope({
    required this.child,
    this.mode = ForestOrientation.landscape,
    super.key,
  });
  final Widget child;
  final ForestOrientation mode;
  @override
  State<ForestOrientationScope> createState() => _ForestOrientationScopeState();
}

class _ForestOrientationScopeState extends State<ForestOrientationScope>
    with RouteAware {
  static final policy = _OrientationRequests();
  PageRoute<dynamic>? route;
  bool active = true;
  void update() => policy.update(this, widget.mode, active);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context);
    if (next is PageRoute && next != route) {
      forestOrientationObserver.unsubscribe(this);
      route = next;
      forestOrientationObserver.subscribe(this, next);
    }
    update();
  }

  @override
  void didUpdateWidget(ForestOrientationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    update();
  }

  @override
  void didPush() {
    active = true;
    update();
  }

  @override
  void didPopNext() {
    active = true;
    update();
  }

  @override
  void didPushNext() {
    active = false;
    update();
  }

  @override
  void didPop() {
    active = false;
    update();
  }

  @override
  void dispose() {
    forestOrientationObserver.unsubscribe(this);
    policy.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Modern tablet windows can ignore native orientation locks. A wide play
      // window keeps real-sized controls and preserves game state on resizing.
      final letterbox =
          widget.mode == ForestOrientation.landscape &&
          box.hasBoundedHeight &&
          box.maxWidth >= 600 &&
          box.maxHeight > box.maxWidth;
      final media = MediaQuery.of(context);
      final size = letterbox
          ? Size(box.maxWidth, box.maxWidth * 9 / 16)
          : media.size;
      return ColoredBox(
        color: letterbox ? const Color(0xFF102B28) : Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: box.hasBoundedWidth ? box.maxWidth : null,
              height: letterbox
                  ? size.height
                  : box.hasBoundedHeight
                  ? box.maxHeight
                  : null,
            ),
            child: MediaQuery(
              data: letterbox
                  ? media.copyWith(
                      size: size,
                      padding: EdgeInsets.only(
                        left: media.padding.left,
                        right: media.padding.right,
                      ),
                      viewPadding: EdgeInsets.only(
                        left: media.viewPadding.left,
                        right: media.viewPadding.right,
                      ),
                    )
                  : media,
              child: widget.child,
            ),
          ),
        ),
      );
    },
  );
}
