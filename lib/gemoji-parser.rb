require 'gemoji-parser/version'
require 'gemoji'

module EmojiParser
  extend self

  # Emoticons
  # ---------
  # The base emoticons set (below) is generated with "noseless" variants, ie:  :-) and :)
  # The generated `EmojiParser.emoticons` hash is formatted as:
  # ---
  # > {
  # >   ":-)" => :blush,
  # >   ":)" => :blush,
  # >   ":-D" => :smile,
  # >   ":D" => :smile,
  # > }
  #
  # This base set is selected for commonality and high degrees of author intention.
  # If you want more/different emoticons:
  # - Please DO customize the `EmojiParser.emoticons` hash in your app runtime.
  # - Please DO NOT customize this source code and issue a pull request.
  #
  # To add an emoticon:
  # ---
  # > EmojiParser.emoticons[':-$'] = :grimacing
  # > EmojiParser.rehash!
  #
  # To remove an emoticon:
  # ---
  # > EmojiParser.emoticons.delete(':-$')
  # > EmojiParser.rehash!
  #
  # NOTE: call `rehash!` after making changes to Emoji/emoticon sets.
  # Rehashing updates the parser's regex cache with the latest icons.
  #
  def emoticons
    return @emoticons if defined? @emoticons
    @emoticons = {}
    emoticons = {
      angry: ">:-(",
      blush: ":-)",
      cry: ":'(",
      confused: [":-\\", ":-/"],
      disappointed: ":-(",
      kiss: ":-*",
      neutral_face: ":-|",
      monkey_face: ":o)",
      open_mouth: ":-o",
      smiley: "=-)",
      smile: ":-D",
      stuck_out_tongue: [":-p", ":-P", ":-b"],
      stuck_out_tongue_winking_eye: [";-p", ";-P", ";-b"],
      wink: ";-)"
    }

    # Parse all named patterns into a flat hash table,
    # where pattern is the key and its token is the value.
    # all patterns are duplicated with the "noseless" variants, ie:  :-) and :)
    emoticons.each_pair do |name, patterns|
      patterns = [patterns] unless patterns.is_a?(Array)
      patterns.each do |pattern|
        @emoticons[pattern] = name
        @emoticons[pattern.sub(/(?<=:|;|=)-/, '')] = name
      end
    end

    @emoticons
  end

  attr_writer :emoticons

  def new_emoji_set
    new_emoji_set = [
      ["\u{1F171}", ":b:", "b"],
      ["\u{1F170}", ":black-a:", "black-a"],
      ["\u{1F17F}", ":black-p:", "black-p"],
      ["\u{1F17E}", ":black-o:", "black-o"],
      ["\u{1F1E6}", ":alphabet-a:", "alphabet-a"],
      ["\u{1F1E7}", ":alphabet-b:", "alphabet-b"],
      ["\u{1F1E8}", ":alphabet-c:", "alphabet-c"],
      ["\u{1F1E9}", ":alphabet-d:", "alphabet-d"],
      ["\u{1F1EA}", ":alphabet-e:", "alphabet-e"],
      ["\u{1F1EB}", ":alphabet-f:", "alphabet-f"],
      ["\u{1F1EC}", ":alphabet-g:", "alphabet-g"],
      ["\u{1F1ED}", ":alphabet-h:", "alphabet-h"],
      ["\u{1F1EE}", ":alphabet-i:", "alphabet-i"],
      ["\u{1F1EF}", ":alphabet-j:", "alphabet-j"],
      ["\u{1F1F0}", ":alphabet-k:", "alphabet-k"],
      ["\u{1F1F1}", ":alphabet-l:", "alphabet-l"],
      ["\u{1F1F2}", ":alphabet-m:", "alphabet-m"],
      ["\u{1F1F3}", ":alphabet-n:", "alphabet-n"],
      ["\u{1F1F4}", ":alphabet-o:", "alphabet-o"],
      ["\u{1F1F5}", ":alphabet-p:", "alphabet-p"],
      ["\u{1F1F6}", ":alphabet-q:", "alphabet-q"],
      ["\u{1F1F7}", ":alphabet-r:", "alphabet-r"],
      ["\u{1F1F8}", ":alphabet-s:", "alphabet-s"],
      ["\u{1F1F9}", ":alphabet-t:", "alphabet-t"],
      ["\u{1F1FA}", ":alphabet-u:", "alphabet-u"],
      ["\u{1F1FB}", ":alphabet-v:", "alphabet-v"],
      ["\u{1F1FC}", ":alphabet-w:", "alphabet-w"],
      ["\u{1F1FE}", ":alphabet-y:", "alphabet-y"],
      ["\u{1F1FD}", ":alphabet-x:", "alphabet-x"],
      ["\u{1F1FF}", ":alphabet-z:", "alphabet-z"],
      ["\u{270C}", ":v:", "victory"],
      ["\u{1F3CC}", ":golfer:", "golfer"],
      ["\u{1F575}", ":sleuth_or_spy:", "spy"],
      ["\u{1F3CB}", ":weight_lifter:", "weight_lifter"],
      ["\u{1F3F3}", ":waving_white_flag:", "white flag"],
      ["\u{1F5E8}", ":left_speech_bubble:", "bubble speech"],
      ["\u{1F3FB}", ":skin-tone-2:", "skin-tone-2"],
      ["\u{1F3FC}", ":skin-tone-3:", "skin-tone-3"],
      ["\u{1F3FD}", ":skin-tone-4:", "skin-tone-4"],
      ["\u{1F3FE}", ":skin-tone-5:", "skin-tone-5"],
      ["\u{1F3FF}", ":skin-tone-6:", "skin-tone-6"],
      ["\u{1F3FB}\u{FE0F}", ":skin-tone-2-undefined", "skin-tone-2-undefined"],
      ["\u{1F3FC}\u{FE0F}", ":skin-tone-3-undefined:", "skin-tone-3-undefined"],
      ["\u{1F3FD}\u{FE0F}", ":skin-tone-4-undefined:", "skin-tone-4-undefined"],
      ["\u{1F3FE}\u{FE0F}", ":skin-tone-5-undefined:", "skin-tone-5-undefined"],
      ["\u{1F3FF}\u{FE0F}", ":skin-tone-6-undefined:", "skin-tone-6-undefined"]
    ]

    new_emoji_set.each do |set|
      Emoji.create(set[2]) do |char|
        char.add_alias set[1]
        char.add_unicode_alias set[0]
      end
    end
  end

  # Rehashes all cached regular expressions.
  # IMPORTANT: call this once after changing emoji characters or emoticon patterns.
  def rehash!
    unicode_regex(rehash: true)
    token_regex(rehash: true)
    emoticon_regex(rehash: true)
  end

  U_FE0F = '\\u{fe0f}'

  # Creates an optimized regular expression for matching unicode symbols.
  # - Options: rehash:boolean
  def unicode_regex(opts={})
    return @unicode_regex if defined?(@unicode_regex) && !opts[:rehash]

    scores_file = File.expand_path('../../db/scores.json', __FILE__)
    scores = File.open(scores_file, 'r:UTF-8') { |data| JSON.parse(data.read) }
    @_new_emoji_set ||= new_emoji_set
    pattern = []

    Emoji.all.each do |emoji|
      score_id = nil
      u = emoji.unicode_aliases.map do |char|
        score_id = char if scores[char]
        char.codepoints.map { |c| '\u{%s}' % c.to_s(16).rjust(4, '0') }.join('')
      end

      if u.any?
        pattern << {
          :pattern => unicode_matcher(u),
          :score => score_id ? scores[score_id].to_i : 0
        }
      end
    end

    pattern.sort! { |a, b| b[:score] - a[:score] }
    pattern.map! { |p| p[:pattern] }

    @unicode_pattern = "(?:#{ pattern.join('|') })#{ U_FE0F }?"
    @unicode_regex = Regexp.new("(#{@unicode_pattern})")
  end

  # Creates a regular expression for matching token symbols.
  # - Options: rehash:boolean (currently unused)
  def token_regex(opts={})
    return @token_regex if defined?(@token_regex)
    @token_pattern = ':([\w+-]+):'
    @token_regex = Regexp.new(@token_pattern)
  end

  # Defines lookaround patterns for matching before and after emoticons.
  def emoticon_lookaround(opts={})
    return @emoticon_lookaround if defined?(@emoticon_lookaround) && !opts[:reset]
    @emoticon_lookaround = {
      behind: '^|\\s',
      ahead: '$|\\s'
    }
  end

  attr_writer :emoticon_lookaround

  # Creates an optimized regular expression for matching emoticon symbols.
  # - Options: rehash:boolean
  def emoticon_regex(opts={})
    return @emoticon_regex if defined?(@emoticon_regex) && !opts[:rehash]
    pattern = {}

    emoticons.keys.each do |icon|
      compact_icon = icon.gsub('-', '')

      # Check to see if this icon has a compact version, ex:  :-)  versus  :)
      # One expression will match as many nose/noseless variants as possible.
      if compact_icon != icon && emoticons[compact_icon]
        compact_regex = Regexp.escape(icon).gsub('-', '-?')

        # Keep this expression if it hasn't been defined yet,
        # or if it's longer than a previously defined pattern.
        if !pattern[compact_icon] || pattern[compact_icon].length < compact_regex.length
          pattern[compact_icon] = compact_regex
        end
      elsif !pattern[icon]
        pattern[icon] = Regexp.escape(icon)
      end
    end

    lookaround = emoticon_lookaround
    @emoticon_pattern = "(?<=#{ lookaround[:behind] })(?:#{ pattern.values.join('|') })(?=#{ lookaround[:ahead] })"
    @emoticon_regex = Regexp.new("(#{@emoticon_pattern})")
  end

  # Generates a macro regex for matching one or more symbol sets.
  # Regex uses various formats, based on symbol sets. Yields match as $1 OR $2
  # T/EU:        (token-$1)|(emoticon-unicode-$2)
  # T/E or T/U:  (token-$1)|(emoticon/unicode-$2)
  # EU:          (emoticon/unicode-$1)
  # - Options: unicode:boolean, tokens:boolean, emoticons:boolean
  def macro_regex(opts={})
    opts = { unicode: true, tokens: true, emoticons: true }.merge(opts)
    unicode_regex if opts[:unicode]
    token_regex if opts[:tokens]
    emoticon_regex if opts[:emoticons]
    pattern = []

    if opts[:emoticons] && opts[:unicode]
      pattern << "(?:#{ @emoticon_pattern })"
      pattern << @unicode_pattern
    else
      pattern << @emoticon_pattern if opts[:emoticons]
      pattern << @unicode_pattern if opts[:unicode]
    end

    pattern = pattern.any? ? "(#{ pattern.join('|') })" : ""

    if opts[:tokens]
      if pattern.empty?
        pattern = @token_pattern
      else
        pattern = "(?:#{ @token_pattern })|#{ pattern }"
      end
    end

    Regexp.new(pattern)
  end

  # Parses all unicode symbols within a string.
  # - Block: performs all symbol transformations.
  def parse_unicode(text)
    text.gsub(unicode_regex) do |match|
      emoji = Emoji.find_by_unicode($1)
      block_given? && emoji ? yield(emoji) : match
    end
  end

  # Parses all token symbols within a string.
  # - Block: performs all symbol transformations.
  def parse_tokens(text)
    text.gsub(token_regex) do |match|
      emoji = Emoji.find_by_alias($1)
      block_given? && emoji ? yield(emoji) : match
    end
  end

  # Parses all emoticon symbols within a string.
  # - Block: performs all symbol transformations.
  def parse_emoticons(text)
    text.gsub(emoticon_regex) do |match|
      if emoticons.has_key?($1)
        emoji = Emoji.find_by_alias(emoticons[$1].to_s)
        block_given? && emoji ? yield(emoji) : match
      else
        match
      end
    end
  end

  # Parses all emoji unicode, tokens, and emoticons within a string.
  # - Block: performs all symbol transformations.
  # - Options: unicode:boolean, tokens:boolean, emoticons:boolean
  def parse(text, opts={})
    opts = { unicode: true, tokens: true, emoticons: true }.merge(opts)
    if opts.one?
      return parse_unicode(text)   { |e| yield e } if opts[:unicode]
      return parse_tokens(text)    { |e| yield e } if opts[:tokens]
      return parse_emoticons(text) { |e| yield e } if opts[:emoticons]
    end
    text.gsub(macro_regex(opts)) do |match|
      a = defined?($1) ? $1 : nil
      b = defined?($2) ? $2 : nil
      emoji = find(a || b)
      block_given? && emoji ? yield(emoji) : match
    end
  end

  # Transforms all unicode emoji into token strings.
  def tokenize(text)
    parse_unicode(text) { |emoji| ":#{emoji.name}:" }
  end

  # Transforms all token strings into unicode emoji.
  def detokenize(text)
    parse_tokens(text) { |emoji| emoji.raw }
  end

  # Finds an Emoji::Character instance for an unknown symbol type.
  # - symbol: an <Emoji::Character>, or a unicode/token/emoticon string.
  def find(symbol)
    return symbol if (symbol.is_a?(Emoji::Character))
    symbol = emoticons[symbol].to_s if emoticons.has_key?(symbol)
    Emoji.find_by_alias(symbol) || Emoji.find_by_unicode(symbol) || nil
  end

  # Gets the image file reference for a symbol; optionally with a custom path.
  # - symbol: an <Emoji::Character>, or a unicode/token/emoticon string.
  # - path: a file path to sub into symbol's filename.
  def image_path(symbol, path=nil)
    emoji = find(symbol)
    return nil unless emoji
    return emoji.image_filename unless path
    "#{ path.sub(/\/$/, '') }/#{ emoji.image_filename.split('/').pop }"
  end

  private

  U_FE0F_SUFFIX = Regexp.new(Regexp.escape(U_FE0F)+'$')

  # Compiles an optimized unicode pattern for fast matching.
  def unicode_matcher(patterns)
    # Strip off all trailing U_FE0F characters:
    patterns.map! { |p| p.gsub(U_FE0F_SUFFIX, '') }.uniq!

    # Return a single pattern directly:
    return patterns.first if patterns.length == 1

    # Sort patterns, longest to shortest:
    patterns.sort! { |a, b| b.length - a.length }

    # Use the longest pattern with U_FE0F optionalized, if possible:
    if patterns.all? { |p| p.gsub(U_FE0F, '') == patterns.last }
      patterns.first.gsub(U_FE0F, U_FE0F+'?')
    else
      patterns.join('|')
    end
  end
end
