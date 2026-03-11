import 'package:flutter_test/flutter_test.dart';
import 'package:winp_flux_assessment/services/html_content_service.dart';

void main() {
  late HtmlContentService htmlService;

  setUp(() {
    htmlService = HtmlContentService();
  });

  group('stripTags', () {
    test('removes all HTML tags from string', () {
      expect(htmlService.stripTags('<p>Hello</p>'), 'Hello');
    });

    test('returns original string if no tags present', () {
      expect(htmlService.stripTags('No tags here'), 'No tags here');
    });

    test('trims whitespace from result', () {
      expect(htmlService.stripTags('  <p>Test</p>  '), 'Test');
    });

    test('removes nested tags', () {
      expect(
        htmlService.stripTags('<div><p>Nested</p></div>'),
        'Nested',
      );
    });
  });

  group('hasBlockContent', () {
    test('returns true for paragraph and div tags', () {
      expect(htmlService.hasBlockContent('<p>Text</p>'), isTrue);
      expect(htmlService.hasBlockContent('<div>Content</div>'), isTrue);
    });

    test('returns true for unordered and ordered lists', () {
      expect(htmlService.hasBlockContent('<ul><li>Item</li></ul>'), isTrue);
      expect(htmlService.hasBlockContent('<ol><li>Item</li></ol>'), isTrue);
    });

    test('returns true for heading tags', () {
      expect(htmlService.hasBlockContent('<h1>Title</h1>'), isTrue);
      expect(htmlService.hasBlockContent('<h6>Title</h6>'), isTrue);
    });

    test('returns false for non-block content', () {
      expect(htmlService.hasBlockContent('<span>Text</span>'), isFalse);
      expect(htmlService.hasBlockContent('<b>Bold</b>'), isFalse);
    });
  });
}
