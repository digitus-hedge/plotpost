import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotpost/widgets/property_image.dart';

void main() {
  testWidgets('loads backend data images from memory', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PropertyImage(
          path:
              'data:image/png;base64,'
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6ioAAAAASUVORK5CYII=',
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('loads backend image URLs over the network', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PropertyImage(
          path: 'http://192.168.1.25:5000/photo.jpg',
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
  });

  testWidgets('loads local image paths from disk', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PropertyImage(path: 'listing.jpg'),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<FileImage>());
  });
}
