import 'package:campus_skillswap/features/posts/models/request_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestPostStatus', () {
    test('maps Firestore values to typed states', () {
      expect(
        RequestPostStatus.fromValue('in_progress'),
        RequestPostStatus.matched,
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

    test('normalizes the legacy in-progress state to matched', () {
      expect(RequestPostStatus.inProgress.firestoreValue, 'matched');
    });

    test('uses the three public status labels', () {
      expect(RequestPostStatus.open.label, 'Open');
      expect(RequestPostStatus.matched.label, 'Matched');
      expect(RequestPostStatus.completed.label, 'Done');
    });
  });
}
