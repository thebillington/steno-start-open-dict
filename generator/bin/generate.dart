import 'dart:io';

import 'package:steno_start_generator/steno_start_generator.dart';

Future<void> main(List<String> arguments) async {
  final Directory cwd = Directory.current;
  // The documented build command runs with -w /workspace/generator.
  final Directory root = cwd.path.endsWith('${Platform.pathSeparator}generator')
      ? cwd.parent
      : cwd;

  if (arguments.contains('--check')) {
    final BuildResult result = Generator(root: root).build(write: false);
    stdout.writeln(result.summary);
    return;
  }

  final BuildResult result = Generator(root: root).build();
  stdout.writeln(result.summary);
}
