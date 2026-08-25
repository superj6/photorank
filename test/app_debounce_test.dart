import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/app/providers.dart';

void main() {
  test('debounce emits first immediately, then the latest after the window', () {
    fakeAsync((async) {
      final src = StreamController<int>();
      final got = <int>[];
      debounce(src.stream, const Duration(milliseconds: 100)).listen(got.add);
      src.add(1);
      async.flushMicrotasks();
      expect(got, [1]);
      src.add(2);
      src.add(3);
      async.elapse(const Duration(milliseconds: 50));
      src.add(4);
      async.elapse(const Duration(milliseconds: 99));
      expect(got, [1]);
      async.elapse(const Duration(milliseconds: 2));
      expect(got, [1, 4]);
      src.close();
      async.flushMicrotasks();
    });
  });
}
