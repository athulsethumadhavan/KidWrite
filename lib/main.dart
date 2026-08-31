import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kid_write/Core/router/app_router.dart';
import 'package:kid_write/Core/services/deep_link_handler.dart';
import 'package:kid_write/Core/theme/app_theme.dart';

import 'Presentation/blocs/Music/music_bloc.dart';import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait on phones, any orientation on tablets (iPad apps are often
  // held in landscape, and the tracing canvas benefits from the width).
  final shortestSide =
      WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .physicalSize
          .shortestSide /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(
    shortestSide >= 600
        ? DeviceOrientation.values
        : [DeviceOrientation.portraitUp],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initDependencies();

  unawaited(DeepLinkHandler.init(appRouter));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MusicBloc>(
      create: (_) => sl<MusicBloc>(),
      child: MaterialApp.router(
        title: 'KidWrite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
