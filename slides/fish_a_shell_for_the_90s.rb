section "The Problem" do
  slide "/bin/bash"
  slide "slow..........", :center, 10
  slide "hacky"
  slide "dated"
end

# Enough bash bashing
section "Fish\n\nThe friendly interactive shell" do
  slide "$ell it to me!"
  slide "It is incredibly fast", :center, 0
  slide "it uses \e[1mthreads\e[0m", :center, 0
  slide "Fast on \e[1mHDDs\e[0m", :center, 0
  slide "think \e[1mSSDs\e[0m...", :center, 0
  # It already knows what you want to type

  slide "Modern!", :center, 0
  # I would say, its shell for the 90s
  slide "REAL VGA colors! Native support for term256".rainbowify, :center, 0
  slide "Web configurable", :center, 0

  slide "Unobtrusive", :center, 0
  slide "Autosuggestions based on your history", :center, 0
  slide "Autocompletions are built from your man pages", :center, 0
  slide "Help is always at your fingertips!", :center, 0
end

section "Show it!" do
  slide `jp2a --clear --width=175 --colors --term-fit thescream.jpg`, :center, 0
  slide <<-EOS, :code, 0
    # MacOSX installation instructions
    $ brew install fishfish
    $ echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
    $ chsh -s fish
  EOS
  slide "Read about fish: http://ridiculousfish.com/shell/", :center, 0
  slide "Modernize your tools!", :center, 0
end

section "
Have a good time!

thanks,
Lukas 'Overbryd' Rieder
" do

end