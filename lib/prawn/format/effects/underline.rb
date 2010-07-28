# encoding: utf-8

module Prawn
  module Format
    module Effects

      class Underline
        def initialize(from, state, options)
          @from = from
          @state = state
          @options = options
        end

        def finish(document, draw_state)
          # TODO: make stroke width customizable
          document.line_width = 0.5
          
          document.stroke_color(@state.color)
          
          # TODO: orient underline correctly for all rotation values (via trig).
          # For now, just support the 90-deg rotation we need with some pretty funky axis-bending.
          unless @options[:rotate] == 90
            x1 = draw_state[:x] + @from
            x2 = draw_state[:x] + draw_state[:dx]
            y  = draw_state[:y] + draw_state[:dy] - 2.5 # larger-than-default offset
            document.move_to(x1, y)
            document.line_to(x2, y)
          else
            y1 = draw_state[:y] + @from
            y2 = draw_state[:y] + draw_state[:dx]
            x = 7 # FIXME: get actual font size!
            document.move_to(x, y1)
            document.line_to(x, y2)
          end
          
          document.stroke
        end

        def wrap(document, draw_state)
          finish(document, draw_state)
          @from = 0
        end
      end

    end
  end
end
