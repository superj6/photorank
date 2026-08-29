import 'dart:math';

/// A recovery phrase is the only way back into an account: five words from
/// a 240-word list (~40 bits). Sign-in attempts are rate-limited server-side,
/// so this is plenty against guessing, while staying easy to write down.
class RecoveryPhrase {
  RecoveryPhrase._();

  static const wordCount = 5;

  static String generate({Random? rng}) {
    final r = rng ?? Random.secure();
    return List.generate(wordCount, (_) => words[r.nextInt(words.length)]).join('-');
  }

  /// Lower-cases and normalises separators so "Apple Bee-cat" == "apple-bee-cat".
  static String normalize(String raw) => raw.trim().toLowerCase().split(RegExp(r'[\s\-_,.]+')).where((w) => w.isNotEmpty).join('-');

  static bool looksValid(String raw) => normalize(raw).split('-').length >= wordCount;

  static const words = [
    'acorn', 'amber', 'anchor', 'apple', 'arrow', 'aspen', 'atlas', 'autumn', 'badge', 'bamboo', 'banjo', 'basil', 'beach', 'berry', 'birch', 'blossom',
    'bonfire', 'breeze', 'bridge', 'bright', 'bronze', 'brook', 'bubble', 'butter', 'cabin', 'cactus', 'camera', 'candle', 'canoe', 'canyon', 'carrot', 'castle',
    'cedar', 'cello', 'cherry', 'cider', 'cinema', 'circle', 'citrus', 'cloud', 'clover', 'cobalt', 'cocoa', 'comet', 'copper', 'coral', 'cotton', 'crayon',
    'cricket', 'crystal', 'daisy', 'dawn', 'delta', 'desert', 'dolphin', 'domino', 'dragon', 'drift', 'eagle', 'ember', 'engine', 'falcon', 'feather', 'fern',
    'fiddle', 'field', 'flame', 'flute', 'forest', 'fossil', 'fresco', 'frost', 'galaxy', 'garden', 'garlic', 'ginger', 'glacier', 'globe', 'goose', 'granite',
    'grape', 'gravel', 'guitar', 'hammer', 'harbor', 'harvest', 'hazel', 'helmet', 'heron', 'hickory', 'honey', 'horizon', 'igloo', 'indigo', 'island', 'ivory',
    'jacket', 'jaguar', 'jasmine', 'jelly', 'jungle', 'juniper', 'kayak', 'kettle', 'kiwi', 'koala', 'lagoon', 'lantern', 'lava', 'lemon', 'lilac', 'linen',
    'lobster', 'locket', 'lotus', 'lunar', 'magnet', 'mango', 'maple', 'marble', 'meadow', 'melon', 'meteor', 'mint', 'mirror', 'mocha', 'monsoon', 'mosaic',
    'muffin', 'mustard', 'nectar', 'noodle', 'north', 'nutmeg', 'oasis', 'ocean', 'olive', 'onyx', 'orbit', 'orchid', 'otter', 'oyster', 'paddle', 'panda',
    'paper', 'parrot', 'pastel', 'peach', 'pebble', 'pelican', 'pepper', 'piano', 'pillow', 'pine', 'pixel', 'planet', 'plum', 'pocket', 'poppy', 'prism',
    'pumpkin', 'puzzle', 'quartz', 'quill', 'rabbit', 'radio', 'rain', 'raven', 'ribbon', 'river', 'robin', 'rocket', 'rose', 'ruby', 'saddle', 'saffron',
    'salmon', 'sand', 'sapphire', 'scarf', 'shadow', 'shell', 'silk', 'silver', 'sketch', 'sleigh', 'snow', 'sonnet', 'sparrow', 'spice', 'spruce', 'stone',
    'storm', 'summer', 'sunset', 'swan', 'tango', 'teapot', 'thistle', 'thunder', 'tiger', 'timber', 'toffee', 'tomato', 'topaz', 'torch', 'tulip', 'tundra',
    'turtle', 'umbrella', 'valley', 'velvet', 'violet', 'violin', 'wagon', 'walnut', 'walrus', 'water', 'whale', 'willow', 'window', 'winter', 'wonder', 'yarn',
    'yellow', 'yogurt', 'zebra', 'zephyr', 'zinc', 'zipper', 'anvil', 'beacon', 'bison', 'boulder', 'cabbage', 'compass', 'dune', 'echo', 'fjord', 'harp',
  ];
}
