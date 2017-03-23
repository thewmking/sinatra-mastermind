require 'sinatra'
require 'sinatra/reloader' if development?

enable :sessions

def guess_check(guess, code)
  @@temp = code.dup
  @@correct = 0
  @@position = 0
  for i in (0..3)
    if (guess[i] == @@temp[i])
      @@correct += 1
      @@temp[i] = "x"
    end
  end

  for j in (0..3)
    if guess.include?(@@temp[j])
      @@position += 1
    end
  end
  @current_count = [@@correct, @@position]
  return @current_count
end

get '/' do
  erb :index
end

post '/maker' do
  erb :maker
end

get '/breaker' do
  @@player_name = "player"
  @@game = Mastermind.new
  @@guesses_remaining = 12
  @@guesses = []
  @@master_code = []
  @@prev_count = []
  @@counts = []
  4.times do
    @@master_code << rand(1..6).to_s
  end
  erb :breaker
end

get '/break_game' do
  @message = " "
  if @@prev_count[0] == 4
    @message = "You are the MASTERMIND!"
  end
  if @@guesses_remaining < 1
    @message = "The secret code was #{@@master_code}"
    #redirect to '/breaker'
  end
  #@@guess = params['code']

  erb :break_game, :locals => {
    :guess => @@guess,
    :guesses_remaining => @@guesses_remaining,
    :guesses => @@guesses,
    :master_code => @@master_code,
    :prev_count => @@prev_count,
    :message => @message,
    :counts => @@counts
  }
end

get '/guess' do

  @@guess = params['code']
  @@guesses << @@guess

  @@game.turn
  Game.check(@@guess, @@master_code)


  erb :break_game, :locals => {
    :guess => @@guess,
    :guesses => @@guesses
  }
  redirect to ('/break_game')
end

get '/comp_guess' do
  Mastermind.new
  @@temp = []
  @numbers = ["1", "2", "3", "4", "5", "6"]
  @possible_guesses = @numbers.repeated_permutation(4).to_a
  @@computer_guesses = []
  @@player_code = params['code']
  @@player_code = @@player_code.split("")
  @current_count = []
  @@prev_count = []
  @@counts = []
  @@player_name = "computer"
  @@guess = ["1", "1", "2", "2"]


  until @@guess == @@player_code

      Game.check(@@guess, @@player_code)
      @possible_guesses.reject! do |code|
        guess_check(@@guess, code)
        @current_count != @@prev_count
      end
      @@guess = @possible_guesses.sample
      @@computer_guesses << @@guess
      Game.check(@@guess, @@player_code)
      @@game.turn

  end
  redirect to ('/make_game')
end


get '/make_game' do
  @@computer_guesses
  message = "The computer guessed #{@@computer_guesses}"
  erb :make_game, :locals => {
    :player_code => @@player_code,
    :guesses_remaining => @@guesses_remaining,
    :guess => @guess, :temp => @@temp,
    :computer_guesses => @@computer_guesses,
    :message => message
    }
end



helpers do
  class Mastermind
    attr_accessor :correct, :position, :guesses_remaining, :guesses
    def initialize
      #system ('clear')
      @@guesses_remaining = 12
      @@guesses = []
      @numbers = ["1", "2", "3", "4", "5", "6"]
      @possible_guesses = @numbers.repeated_permutation(4).to_a
      @guess = []
      @@correct = 0
      @@position = 0
      @@master_code = []
      @@computer_guesses = []
      4.times do
        @@master_code << rand(1..6).to_s
      end
      @current_count = []
      @@prev_count = []
      @game = Game.new
    end


    def turn
      @@guesses_remaining -= 1
    end

    def play_breaker
      @@player_name = "player"
      puts "Enter your guess. Choose 4 digits from 1 to 6."
      @guess = gets.chomp
      while (@guess.length != 4) || !(@guess =~ /[1-6]{4}/)
        puts "Guess must be 4 digits from 1-6"
        @guess = gets.chomp
      end
      @guess = @guess.split("")
      code = []
      if Game.check(@guess, code)
        play_breaker
      end
    end

    def play_maker
      @@player_name = "computer"
      if @@guesses_remaining == 12
        puts "Enter your secret code. Choose 4 digits from 1 to 6."
        @@player_code = gets.chomp
        while (@@player_code.length != 4) || !(@@player_code =~ /[1-6]{4}/)
          puts "Code must be 4 digits from 1-6"
          @@player_code = gets.chomp
        end
        @@player_code = @@player_code.split("")
        computer_guess_two
      else
        computer_guess_two
      end
      if Game.check(@guess, @@player_code)
        play_maker
      end
    end

    def computer_guess
      if @@guesses_remaining == 12
        @guess = first_guess
      else
        @guess = @numbers.sample(4)
      end
    end

    def computer_guess_two
      if @@guesses_remaining == 12
        @guess = first_guess
      else
        filter_guesses
        @guess = @possible_guesses.sample
      end
      return @guess
    end

    def first_guess
      @guess = ["1", "1", "2", "2"]
    end

    def filter_guesses
      @possible_guesses.reject! do |code|
        guess_check(@guess, code)
        @current_count != @@prev_count
      end
    end

    def guess_check(guess, code)
      @@temp = code.dup
      @@correct = 0
      @@position = 0
      for i in (0..3)
        if (guess[i] == @@temp[i])
          @@correct += 1
          @@temp[i] = "x"
        end
      end

      for j in (0..3)
        if guess.include?(@@temp[j])
          @@position += 1
        end
      end
      @current_count = [@@correct, @@position]
      return @current_count
    end

  end

  class Game < Mastermind
    attr_accessor :correct, :position, :guesses_remaining, :prev_count, :possible_guesses, :counts, :computer_guesses
    def initialize
    end

    def self.check(guess, code)
      if @@player_name != "player"
        code = @@player_code
      end

      if @@player_name == "player"
        code = @@master_code
      end

      if @@guesses_remaining > 1
        @@temp = code.dup
        @@correct = 0
        @@position = 0
        for i in (0..3)
          if (guess[i] == @@temp[i])
            @@correct += 1
            @@temp[i] = "x"
          end
        end

        for j in (0..3)
          if guess.include?(@@temp[j])
            @@position += 1
            @@temp[j] = "y"
          end
        end

        @@prev_count = [@@correct, @@position]
        @@counts << @@prev_count
        if @@correct == 4
          winner
        else
          #@@guesses_remaining -= 1

          return @@prev_count
          return true
        end
      else
        if @@player_name == "player"
          puts "Oh no! You're out of guesses!"
        else
          puts "The computer failed to guess your code!"
        end
        puts "The secret code was #{code}"
      end
    end

    def guess_check(guess, code)
      @@temp = code.dup
      @@correct = 0
      @@position = 0
      for i in (0..3)
        if (guess[i] == @@temp[i])
          @@correct += 1
          @@temp[i] = "x"
          #guess[i] = "y"
        end
      end

      for j in (0..3)
        if guess.include?(@@temp[j])
          @@position += 1
        end
      end
      @current_count = [@@correct, @@position]
      return @current_count
    end



    def self.winner
      if @@player_name == "player"
        return "You are the MASTERMIND"
      else
        puts "The computer guessed your secret code with only #{13-@@guesses_remaining} guesses!"
      end
    end


  end
end
