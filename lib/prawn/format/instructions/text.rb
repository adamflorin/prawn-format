# encoding: utf-8

require 'prawn/format/instructions/base'

module Prawn
  module Format
    module Instructions

      class Text < Base
        attr_reader :text

        def initialize(state, text, options={})
          super(state)
          @text = text
          @break = options.key?(:break) ? options[:break] : text.index(/[-\xE2\x80\x94\s]/)
          @discardable = options.key?(:discardable) ? options[:discardable] : text.index(/\s/)
          @text = state.font.normalize_encoding(@text) if options.fetch(:normalize, true)
        end

        def dup
          self.class.new(state, @text.dup, :normalize => false,
            :break => @break, :discardable => @discardable)
        end

        def accumulate(list)
          if list.last.is_a?(Text) && list.last.state == state
            list.last.text << @text
          else
            list.push(dup)
          end

          return list
        end

        def spaces
          @spaces ||= @text.scan(/ /).length
        end

        def height(ignore_discardable=false)
          if ignore_discardable && discardable?
            0
          else
            @height
          end
        end

        def break?
          @break
        end

        def discardable?
          @discardable
        end

        def compatible?(with)
          with.is_a?(self.class) && with.state == state
        end
        
        # Since we now draw text character-by-charater, we must recalc @width
        # (thereby affecting draw_state[:dx]) after EACH call to draw--not just if it's nil.
        # Underlines are egregiously off if we don't explicitly reset @width on each call.
        # 
        def width(type=:all)
          @width = @state.font.compute_width_of(@text, :size => @state.font_size, :kerning => @state.kerning?)

          case type
          when :discardable then discardable? ? @width : 0
          when :nondiscardable then discardable? ? 0 : @width
          else @width
          end
        end

        def to_s
          @text
        end
        
        # Sift through strings character-by-character.
        # If font doesn't have glyph, then fall back to Arial.
        # If Arial doesn't have glyph, log warning.
        # 
        # TODO: make fallback font configurable; don't rely on Arial!
        #
        def draw(document, draw_state, options={})
          full_text = @text
          full_text.each_char do |c|
            @text = c
            if has_glyph(@state.font, c)
              draw_without_glyph_fix(document, draw_state, options)
            else # desired font doesn't have glyph--try Arial
              @state = @state.with_style(:font_family => "Arial")
              draw_without_glyph_fix(document, draw_state, options)
              puts "WARNING: no font has glyph for '#{c}'" unless has_glyph(@state.font, c)
            end
          end
        end
        
        # (orig. draw)
        # 
        def draw_without_glyph_fix(document, draw_state, options={})
          @state.apply!(draw_state[:text], draw_state[:cookies])

          encoded_text = @state.font.encode_text(@text, :kerning => @state.kerning?)
          encoded_text.each do |subset, chunk|
            @state.apply_font!(draw_state[:text], draw_state[:cookies], subset)
            draw_state[:text].show(chunk)
          end
          draw_state[:dx] += width

          draw_state[:dx] += draw_state[:padding] * spaces if draw_state[:padding]
        end
        
        
        private
          
          # utility to check if char is in font
          #
          # From http://thomas.noto.de/prawn/main.rb
          # See also http://groups.google.com/group/prawn-ruby/browse_thread/thread/a6f70bdaa6777ba/613717b4e34dfbd4?lnk=gst&q=character#613717b4e34dfbd4
          #
          def has_glyph(font,char)
            unicode = char.unpack("U")[0]
            font.ttf.cmap.tables.each do |tab|
              return true if tab.unicode? && tab[unicode] != 0
            end
            return false
          end
          
      end

    end
  end
end
