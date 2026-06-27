import 'package:campus_skillswap/features/posts/models/request_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestPostStatus', () {
    test('maps Firestore values to typed states', () {
      expect(
        RequestPostStatus.fromValue('in_progress'),
        RequestPostStatus.inProgress,
      );
      expect(
        RequestPostStatus.fromValue('completed'),
        RequestPostStatus.completed,
      );
    });

    test('uses open as a safe fallback', () {
      expect(RequestPostStatus.fromValue(null), RequestPostStatus.open);
      expect(RequestPostStatus.fromValue('unexpected'), RequestPostStatus.open);
    });

    test('serializes the in-progress state for Firestore', () {
      expect(RequestPostStatus.inProgress.firestoreValue, 'in_progress');
    });
  });
}
