module Ruby2600
  class TIA
    attr_accessor :cpu, :riot

    include Constants

    # A scanline "lasts" 228 "color clocks" (CLKs), of which 68
    # are the initial blank period, and each of the remai

    HORIZONTAL_BLANK_CLK_COUNT = 68
    TOTAL_SCANLINE_CLK_COUNT = 228

    # Maps which register/bit should be set for each playfield pixel

    PLAYFIELD_ORDER = [[PF0, 4], [PF0, 5], [PF0, 6], [PF0, 7],
                       [PF1, 7], [PF1, 6], [PF1, 5], [PF1, 4], [PF1, 3], [PF1, 2], [PF1, 1], [PF1, 0],
                       [PF2, 0], [PF2, 1], [PF2, 2], [PF2, 3], [PF2, 4], [PF2, 5], [PF2, 6], [PF2, 7]]

    def initialize
      @reg = Array.new(32) { rand(256) }
      @cpu_credits = 0
      @bl_counter = TIACounter.new
      @bl_counter.on_change { |value| bl_counter_increased(value) }
      @bl_pixels_to_draw = 0
      @p0 = TIAPlayer.new(@reg, 0)
      @p1 = TIAPlayer.new(@reg, 1)
    end

    def [](position)

    end

    def []=(position, value)
      case position
      when RESBL
        @bl_counter.reset
      when RESP0
        @p0.strobe
      when RESP1
        @p1.strobe
      when HMOVE
        @bl_counter.move @reg[HMBL]
      else
        @reg[position] = value
      end
    end

    def scanline
      intialize_scanline
      wait_horizontal_blank
      draw_scanline
    end

    def frame
      buffer = []
      scanline while vertical_sync?
      buffer << scanline until vertical_sync?
      buffer
    end

    private

    def intialize_scanline
      reset_cpu_sync
      @scanline = Array.new(160, 0)
      @pixel = 0
    end

    def wait_horizontal_blank
      HORIZONTAL_BLANK_CLK_COUNT.times { |color_clock| sync_cpu_with color_clock }
    end

    def draw_scanline
      HORIZONTAL_BLANK_CLK_COUNT.upto TOTAL_SCANLINE_CLK_COUNT - 1 do |color_clock|
        sync_cpu_with color_clock
        unless vertical_blank?
          @scanline[@pixel] = player_pixel || bl_pixel || pf_pixel || bg_pixel
        end
        @pixel += 1
        @bl_counter.tick
      end
      @scanline
    end

    # The 2600 hardware wiring ensures that we have three color clocks
    # for each CPU clock, but "freezes" the CPU if WSYNC is set on TIA.
    #
    # To keep them in sync, we'll compute a "credit" for each color
    # clock, and "use" this credit when we have any of it

    def sync_cpu_with(color_clock)
      riot.pulse if color_clock % 3 == 0
      return if @reg[WSYNC]
      @cpu_credits += 1 if color_clock % 3 == 0
      @cpu_credits -= @cpu.step while @cpu_credits > 0
    end

    def reset_cpu_sync
      @cpu_credits = 0 if @reg[WSYNC]
      @reg[WSYNC] = nil
    end

    def vertical_blank?
      @reg[VBLANK] & 0b00000010 != 0
    end

    def vertical_sync?
      @reg[VSYNC] & 0b00000010 != 0
    end

    # Background

    def bg_pixel
      @reg[COLUBK]
    end

    # Playfield

    def pf_pixel
      pf_color if pf_bit_set?
    end

    def pf_color
      @reg[score_mode? ? COLUP0 + @pixel / 80 : COLUPF]
    end

    def pf_bit_set?
      pf_pixel = (@pixel / 4) % 20
      pf_pixel = 19 - pf_pixel if reflect_current_side?
      register, bit = PLAYFIELD_ORDER[pf_pixel]
      @reg[register][bit] == 1
    end

    def reflect_current_side?
      @reg[CTRLPF][0] == 1 && @pixel > 79
    end

    def score_mode?
      @reg[CTRLPF][1] == 1
    end

    # Ball

    def bl_pixel
      return nil unless @reg[ENABL][1]==1 && @bl_pixels_to_draw > 0
      @bl_pixels_to_draw -= 1
      @reg[COLUPF]
    end

    def bl_size
      2 ** (2 * @reg[CTRLPF][5] + @reg[CTRLPF][4])
    end

    def bl_counter_increased(value)
      if value == 0
        @bl_pixels_to_draw = [bl_size, 4].min
      elsif value == 1 && bl_size == 8
        @bl_pixels_to_draw = 4
      else
        @bl_pixels_to_draw = 0
      end
    end

    # Players
    # (need to request both pixels to keep counters in sync,
    #  even if one overrides the other)

    def player_pixel
      p0_pixel = @p0.pixel
      p1_pixel = @p1.pixel
      p0_pixel || p1_pixel
    end
  end
end


