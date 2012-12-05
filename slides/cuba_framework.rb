# encoding: utf-8

slide `jp2a --clear --width=35 --colors --term-fit --invert star.jpg`, :center

section "Cuba\n\nCe ci ne pas un framework" do
  slide "So what is it then?", :center
  slide <<-EOS, :center
    Cuba is

    a Rack based Microframework,

    that does route matching really well.
  EOS
  slide <<-EOS, :code
    # hello_world.rb
    require "cuba"

    Cuba.define do
      \e[1mon\e[0m "hello" do
        res.write "hello, world"
      end
    end
    run Cuba
  EOS
  slide "Small and light as a feather"
  slide "Cuba's core is 1 file at 174 loc"
  slide "Minimalistic but extensible"
  slide <<-EOS, :code
    # lib/cuba/content_for.rb

    module Cuba::ContentFor
      def yield_for(symbol)
        content_blocks[symbol].map(&:call)
      end

      def content_for(symbol, &block)
        content_blocks[symbol] << block
      end

      private

      def content_blocks
        @content_blocks ||= Hash.new { |h, k| h[k] = [] }
      end
    end

    # app.rb
    Cuba.plugin Cuba::ContentFor
  EOS
  slide <<-EOS, :code
    # app.rb
    Cuba.settings[:res] = Rack::Response
  EOS
  slide <<-EOS, :code
    # game_x.rb

    class GameX < Cuba
      def try
        super
      rescue ApplicationError => error
        res.status = 200
        render_json error
      end
    end
  EOS
  slide "Very much testable"
  slide <<-EOS, :code
    # hello_world_test.rb
    require "cuba/test"
    require_relative "./hello_world.rb"

    scope do
      test "Hello World" do
        get "/"
        assert_equal "hello, world", last_response.body
      end
    end
  EOS

  slide <<-EOS, :code
    # hello_world_capybara_test.rb
    require "cuba/capybara"
    require_relative "./hello_world.rb"

    scope do
      test "Homepage" do
        visit "/"

        assert has_content?("hello, world")
      end
    end
  EOS
end

section "Cuba in the wild" do
  slide `jp2a --clear --width=35 --colors --term-fit --invert wooga.jpg`
  slide <<-EOS
                 _._
            _.-``__ ''-._
       _.-``    `.  `_.  ''-._
   .-`` .-```.  ```\/    _.,_ ''-._
  (    '      ,       .-`  | `,    )
  |`-._`-...-` __...-.``-._|'` _.-'|
  |    `-._   `._    /     _.-'    |
   `-._    `-._  `-./  _.-'    _.-'
  |`-._`-._    `-.__.-'    _.-'_.-'|
  |    `-._`-._        _.-'_.-'    |
   `-._    `-._`-.__.-'_.-'    _.-'
  |`-._`-._    `-.__.-'    _.-'_.-'|
  |    `-._`-._        _.-'_.-'    |
   `-._    `-._`-.__.-'_.-'    _.-'
       `-._    `-.__.-'    _.-'
           `-._        _.-'
               `-.__.-'
  EOS
  slide <<-EOS
    http://educabilia.com/
  EOS
end

section "Beware of the Big But!" do
  slide "The Security Problem"
  slide "Cuba will do nothing for you by default."

  slide "The Encoding Problem"
  slide "Cuba will do nothing that ensures framework wide internal encoding"
  slide "Do not fall into the purists trap."

  slide "All this is good if you know what you are doing."
  slide "All this is good if you know what you are getting."
  slide "All this is really bad if you start writing 'the next big thing'"
  slide <<-EOS, :center
    'the next big thing' requires certain buzzwords
    
    "Time to Market" or "Revenue Stream"
  EOS
  slide <<-EOS, :center
    'the next big thing' does not require these buzzwords

    "CSRF", "XSS" or "SQL Injection"
  EOS
end

section "Visit Cuba!" do
  slide <<-EOS, :block
    Website:
      http://cuba.is

    App Template:
      https://github.com/soveran/app

    IRC:
      #cuba.rb on freenode.net

    Contributors:
      $ cd cuba/ && git shortlog -ns
      106  Michel Martens
       81  Cyril David
        3  Martin Kozák
        2  Konstantin Haase
        2  ichverstehe
        1  Nicolas Sanguinetti
        1  Samnang Chhun
        1  Leandro López (inkel)
        1  Brendon Murphy
        1  Florent Guilleux
        1  Kurtis Rainbolt-Greene
        1  Agis Anastasopoulos
  EOS
  slide "Hit me with your questions\n\n@Overbryd", :center
end
