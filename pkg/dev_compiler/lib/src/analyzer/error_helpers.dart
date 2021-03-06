// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart' show ErrorProcessor;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:path/path.dart' as path;

/// Sorts and formats errors, returning the error messages.
List<String> formatErrors(AnalysisContext context, List<AnalysisError> errors) {
  sortErrors(context, errors);
  var result = <String>[];
  for (var e in errors) {
    var m = formatError(context, e);
    if (m != null) result.add(m);
  }
  return result;
}

// TODO(jmesserly): this code was taken from analyzer_cli.
// It really should be in some common place so we can share it.
// TODO(jmesserly): this shouldn't depend on `context` but we need it to compute
// `errorSeverity` due to some APIs that need fixing.
void sortErrors(AnalysisContext context, List<AnalysisError> errors) {
  errors.sort((AnalysisError error1, AnalysisError error2) {
    // severity
    var severity1 = errorSeverity(context, error1);
    var severity2 = errorSeverity(context, error2);
    int compare = severity2.compareTo(severity1);
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(error1.source.fullName.toLowerCase(),
        error2.source.fullName.toLowerCase());
    if (compare != 0) return compare;

    // offset
    compare = error1.offset - error2.offset;
    if (compare != 0) return compare;

    // compare message, in worst case.
    return error1.message.compareTo(error2.message);
  });
}

// TODO(jmesserly): this was from analyzer_cli, we should factor it differently.
String formatError(AnalysisContext context, AnalysisError error) {
  var severity = errorSeverity(context, error);
  // Skip hints, some like TODOs are not useful.
  if (severity.ordinal <= ErrorSeverity.INFO.ordinal) return null;

  var lineInfo = context.computeLineInfo(error.source);
  var location = lineInfo.getLocation(error.offset);

  // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
  return (StringBuffer()
        ..write('[${severity.displayName}] ')
        ..write(error.message)
        ..write(' (${path.prettyUri(error.source.uri)}')
        ..write(', line ${location.lineNumber}, col ${location.columnNumber})'))
      .toString();
}

ErrorSeverity errorSeverity(AnalysisContext context, AnalysisError error) {
  var errorCode = error.errorCode;
  if (errorCode == StrongModeCode.TOP_LEVEL_FUNCTION_LITERAL_BLOCK ||
      errorCode == StrongModeCode.TOP_LEVEL_INSTANCE_GETTER ||
      errorCode == StrongModeCode.TOP_LEVEL_INSTANCE_METHOD) {
    // These are normally hints, but they should be errors when running DDC, so
    // that users won't be surprised by behavioral differences between DDC and
    // dart2js.
    return ErrorSeverity.ERROR;
  }

  // TODO(jmesserly): this Analyzer API totally bonkers, but it's what
  // analyzer_cli and server use.
  //
  // Among the issues with ErrorProcessor.getProcessor:
  // * it needs to be called per-error, so it's a performance trap.
  // * it can return null
  // * using AnalysisError directly is now suspect, it's a correctness trap
  // * it requires an AnalysisContext
  return ErrorProcessor.getProcessor(context.analysisOptions, error)
          ?.severity ??
      errorCode.errorSeverity;
}

bool isFatalError(AnalysisContext context, AnalysisError e, bool replCompile) {
  if (errorSeverity(context, e) != ErrorSeverity.ERROR) return false;

  // These errors are not fatal in the REPL compile mode as we
  // allow access to private members across library boundaries
  // and those accesses will show up as undefined members unless
  // additional analyzer changes are made to support them.
  // TODO(jacobr): consider checking that the identifier name
  // referenced by the error is private.
  return !replCompile ||
      (e.errorCode != StaticTypeWarningCode.UNDEFINED_GETTER &&
          e.errorCode != StaticTypeWarningCode.UNDEFINED_SETTER &&
          e.errorCode != StaticTypeWarningCode.UNDEFINED_METHOD);
}

const invalidImportDartMirrors = StrongModeCode(
    ErrorType.COMPILE_TIME_ERROR,
    'IMPORT_DART_MIRRORS',
    'Cannot import "dart:mirrors" in web applications (https://goo.gl/R1anEs).');

const invalidJSInteger = StrongModeCode(
    ErrorType.COMPILE_TIME_ERROR,
    'INVALID_JS_INTEGER',
    "The integer literal '{0}' can't be represented exactly in JavaScript. "
    "The nearest value that can be represented exactly is '{1}'.");
