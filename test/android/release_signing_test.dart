import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release signing fails closed and never selects debug signing', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('releaseSigningError'));
    expect(gradle, contains('throw GradleException'));
    expect(
      gradle,
      contains('Release signing never falls back to the debug key'),
    );

    final releaseBlock = gradle.substring(gradle.indexOf('release {'));
    expect(releaseBlock, isNot(contains('signingConfigs.getByName("debug")')));
    expect(releaseBlock, contains('signingConfigs.getByName("release")'));
  });

  test('device integration can use a package isolated from release', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final runner = File('tool/run_android_integration.sh').readAsStringSync();

    expect(gradle, contains('create("production")'));
    expect(gradle, contains('create("integration")'));
    expect(gradle, contains('applicationIdSuffix = ".integration"'));
    expect(gradle, contains('processIntegrationDebugGoogleServices'));
    expect(gradle, contains('enabled = false'));
    expect(pubspec, contains('default-flavor: production'));
    expect(runner, contains('--flavor integration'));
    expect(runner, contains('--no-uninstall'));
    expect(runner, contains(r'uninstall "$integration_package"'));
  });
}
