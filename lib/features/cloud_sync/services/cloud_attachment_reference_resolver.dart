import 'dart:convert';

import 'package:path/path.dart' as p;

class CloudAttachmentReferenceResolver {
  const CloudAttachmentReferenceResolver();

  String? findPreviousReference({
    required List<String> previousReferences,
    required String localPath,
    required int index,
  }) {
    final localName = p.basename(localPath);
    for (final candidate in previousReferences) {
      try {
        final encodedName = Uri.parse(candidate).pathSegments.last;
        final padded = encodedName.padRight(
          encodedName.length + ((4 - encodedName.length % 4) % 4),
          '=',
        );
        if (utf8.decode(base64Url.decode(padded)) == localName) {
          return candidate;
        }
      } catch (_) {}
    }
    return index < previousReferences.length ? previousReferences[index] : null;
  }
}
