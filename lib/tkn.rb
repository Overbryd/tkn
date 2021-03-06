# coding: utf-8

require "rubygems"
require "io/console"
require "active_support/core_ext/string/strip"
require "pygments"
require "rainbow"

class String
  def rainbowify
    split("").map { |c| c.color(rand(25), rand(25), rand(25))}.join("")
  end
end

class Tkn

  attr_reader :n, :deck, :mtime, :slides

  def initialize
    @n      = 0
    @deck   = ARGV[0]
    @mtime  = nil
    @slides = []
    @default_slide_time = 0.5
    @default_format = :block
  end

  def run
    loop do
      print clear_screen

      current_mtime = File.mtime(deck)
      if mtime != current_mtime
        @slides = []
        instance_eval(File.read(deck))
        mtime = current_mtime
      end

      @n = [[0, n].max, @slides.length - 1].min
      render(@slides[n]) do |c|
        print c
      end

      user_input read_command
    end
  end

  #
  # --- DSL -------------------------------------------------------------
  #

  def slide(content, format=@default_format, speed=nil)
    @slides << [content.strip_heredoc, format, speed]
  end

  def section(content)
    @slides << [content, :section]
    yield
  end


  #
  # --- ANSI Escape Sequences -------------------------------------------
  #

  # Clears the screen and leaves the cursor at the top left corner.
  def clear_screen
    "\e[2J\e[H"
  end

  # Puts the cursor at (row, col), 1-based.
  #
  # Note that characters start to get printed where the cursor is. So, to leave
  # a left margin of 8 characters you want col to be 9.
  def cursor_at(row, col)
    "\e[#{row};#{col}H"
  end


  #
  # --- Utilities -------------------------------------------------------
  #

  # Returns the width of the content, defined as the maximum length of its lines
  # discarding trailing newlines if present.
  def width(content)
    content.each_line.map do |line|
      ansi_length(line.chomp)
    end.max
  end

  # Quick hack to compute the length of a string ignoring the characters that
  # represent ANSI escape sequences. This only supports a handful of them, the
  # ones that I want to use.
  def ansi_length(str)
    str.gsub(/\e\[(2J|\d*(;\d+)*(m|f|H))/, '').length
  end

  # Returns the number of rows and columns of the terminal as an array of two
  # integers [rows, cols].
  def winsize
    $stdout.winsize
  end


  #
  # --- Slide Rendering -------------------------------------------------
  #

  # Returns a string that the caller has to print as is to get the slide
  # properly rendered. The caller is responsible for clearing the screen.
  # Each char will be yielded after a configurable sleep time.
  def render(slide)
    result = render_out(slide)
    sleep_time = (slide[2] ? slide[2].to_f : @default_slide_time) / result.length
    result.each_char do |c|
      yield c
      sleep sleep_time
    end
  end

  def render_out(slide)
    send("render_#{slide[1]}", slide[0]) if slide[0] =~ /\S/
  end

  # Renders the content by centering each individual line.
  def render_center(content)
    nrows, ncols = winsize

    ''.tap do |str|
      nlines = content.count("\n")
      row = [1, 1 + (nrows - nlines)/2].max
      content.each_line.with_index do |line, i|
        col = [1, 1 + (ncols - ansi_length(line.chomp))/2].max
        str << cursor_at(row + i, col) + line
      end
    end
  end

  # Renders a section banner.
  def render_section(content)
    nrows, ncols = winsize
    width = width(content)

    rfil = [1, width - 5].max/2
    lfil = [1, width - 5 - rfil].max
    fleuron = '─' * lfil + ' ❧❦☙ ' + '─' * rfil

    render_center("#{fleuron}\n\n#{content}\n\n#{fleuron}\n")
  end

  # Renders Ruby source code.
  def render_code(code)
    render_block(Pygments.highlight(code, formatter: 'terminal256', lexer: 'ruby', options: {style: 'bw'}))
  end

  # Centers the whole content as a block. That is, the format within the content
  # is preserved, but the whole thing looks centered in the terminal. I think
  # this looks nicer than an ordinary flush against the left margin.
  def render_block(content)
    nrows, ncols = winsize

    nlines = content.count("\n")
    row = [1, 1 + (nrows - nlines)/2].max

    width = width(content)
    col = [1, 1 + (ncols - width)/2].max

    content.gsub(/^/) do
      cursor_at(row, col).tap { row += 1 }
    end
  end


  #
  # --- Main Loop -------------------------------------------------------
  #

  # Allows for reading multiple characters when combined with a loop
  # Returns true if a commmand could be read within the given wait_time.
  # Otherwise false and catches the Timeout::Error
  # Any results from read_command must be processed in a block.
  def try_read_command(wait_time = 0.3)
    timeout wait_time do
      yield read_command if block_given?
      true
    end
  rescue Timeout::Error
    false
  end

  # Reads either one single character or PageDown or PageUp. You need to
  # configure Terminal.app so that PageDown and PageUp get passed down the
  # script. Echoing is turned off while doing this.
  def read_command
    $stdin.noecho do |noecho|
      noecho.raw do |raw|
        raw.getc.tap do |command|
          # Consume PageUp or PageDown if present. No other ANSI escape sequence is
          # supported so a blind 3.times getc is enough.
          3.times { command << raw.getc } if command == "\e"
        end
      end
    end
  end

  def user_input cmd
    case cmd
    # next slide
    when ' ', 'n', 'l', 'k', "\e[5~"
      @n += 1
    # previous slide
    when 'b', 'p', 'h', 'j', "\e[6~"
      @n -= 1
    # jump to start
    when '^'
      @n = 0
    # jump to end
    when '$'
      @n = @slides.length - 1
    # quit
    when 'q'
      print clear_screen
      exit
    # jump to a slide by number
    # provides a small timeout to type a sequence of numbers
    when /^(\d+)$/
      @n = $1.to_i
      loop do
        break unless try_read_command do |cmd|
          @n = "#{n}#{$1}".to_i if cmd =~ /^(\d+)$/
        end
      end
    end
  end

end
