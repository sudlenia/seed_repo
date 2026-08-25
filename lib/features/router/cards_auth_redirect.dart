String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  final path = uri.path;

  if (!isAuthed) {
    if (path == '/onboarding') {
      return null;
    }

    if (path.startsWith('/cards')) {
      final fullLocation = uri.toString();
      final encodedNext = Uri.encodeComponent(fullLocation);
      return '/onboarding?next=$encodedNext';
    }

    return null;
  }

  if (isAuthed && path == '/onboarding') {
    final next = uri.queryParameters['next'];
    
    if (next != null && next.isNotEmpty) {
      final decodedNext = Uri.decodeComponent(next);
      
      if (decodedNext.startsWith('/cards')) {
        try {
          final nextUri = Uri.parse(decodedNext);
          if (nextUri.scheme.isEmpty || nextUri.scheme == 'http' || nextUri.scheme == 'https') {
            if (decodedNext.startsWith('/')) {
              return decodedNext;
            }
          }
        } catch (_) {
        }
      }
    }
    
    return '/cards';
  }

  return null;
}