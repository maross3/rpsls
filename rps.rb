require 'yaml'
TEXT = YAML.load_file('text.yml')
MENU_STRINGS = YAML.load_file('menu_strings.yml')

class InputValidator
  def self.input(question, valid_choices)
    all_valid_choices = generate_possible_choices(valid_choices)

    loop do
      UserInterface.ask(question)
      input = gets.chomp.downcase

      no_space_input = input.gsub(/\s+/, "")
      name = input.capitalize.split(' ').join(' ')

      return choice(input, valid_choices) if all_valid_choices.include?(input)
      return name if valid_choices.empty? && !no_space_input.empty?
      puts "Invalid choide, please try again."
    end
  end

  def self.choice(input, valid_choices)
    valid_choices.select { |choice| choice.start_with?(input) }.join('')
  end

  def self.generate_abreviations(array)
    abreviation_hash = {}
    array.each do |selection|
      first_letter = selection[0].downcase
      if abreviation_hash[first_letter].nil?
        abreviation_hash[first_letter] = [selection]
      else
        abreviation_hash[first_letter] += [selection]
      end
    end
    abreviation_hash
  end

  def self.generate_possible_choices(array)
    abreviation_hash = generate_abreviations(array)
    repeats = abreviation_hash.select { |_, v| v.size > 1 }.values.flatten
    generate_selections(array, repeats)
  end

  def self.generate_selections(array, repeats)
    available_selections = []
    array.each do |element|
      option = element.downcase
      available_selections << option
      available_selections << option[0..1] if repeats.include?(option)
      available_selections << option[0] if !repeats.include?(option)
    end
    available_selections
  end
end

class Menu
  MENU_OPTIONS = ['1', '2', '3', '4', 'play', 'rules', 'help', 'exit']
  MENU_CHOICES = '1) Play 2) Rules 3) Help 4) Exit'
  attr_reader :choice

  def initialize
    UserInterface.generate('rock paper scissor')
    UserInterface.generate('lizard spock')
    @input = InputValidator.input(MENU_CHOICES, MENU_OPTIONS)
    @choice = menu_choice(@input)
  end

  private

  def menu_choice(str)
    case str
    when '1' then 'play'
    when '2' then 'rules'
    when '3' then 'help'
    when '4' then 'exit'
    else
      str
    end
  end
end

class UserInterface
  def self.ask(question)
    puts question
    print "> "
  end

  def self.battle_text(human, computer)
    system('clear')
    generate(human.to_s)
    sleep(0.5)
    generate('vs')
    sleep(0.5)
    generate(computer.to_s)
    wait(1)
  end

  def self.display_text(str)
    puts str
  end

  def self.enter_to_continue
    display_text("\n\nPress enter to continue...")
    gets.chomp
    wait(0.5)
  end

  def self.generate(str)
    str.gsub!(/2/, 'z')
    7.times do |line|
      str.length.times do |char|
        print TEXT[str[char].upcase][line] if str[char] != " "
        print TEXT['SPACE'][line] if str[char] == " "
      end
      print "\n"
    end
  end

  def self.help
    wait(0.5)
    generate('help')
    rule_line
    5.times { |line| puts MENU_STRINGS['HELP'][line] }
    enter_to_continue
    menu
  end

  def self.menu
    menu = Menu.new
    case menu.choice
    when 'play' then wait(0.5)
    when 'rules' then rules
    when 'help' then help
    when 'exit' then RPSGame.exit_game
    end
  end

  def self.rule_line
    display_text("==========================================")
  end

  def self.rules
    wait(0.5)
    generate('rules')
    rule_line
    4.times { |line| puts MENU_STRINGS['RULES'][line] }
    enter_to_continue
    menu
  end

  def self.wait(int)
    sleep(int)
    system('clear')
  end
end

class RPSGame
  attr_accessor :human, :computer, :playing

  @@playing = true
  def initialize
    @human = Human.new
    @computer = Computer.new
    @history = History.new(@human, @computer)
  end

  def self.exit_game
    @@playing = false
  end

  def play
    display_welcome_message
    game_loop
    display_goodbye_message
  end

  private

  def game_loop
    while @@playing
      display_scores
      human.choose
      @history.display if human.move == 'history'
      next if human.move == 'history'
      break if !@@playing
      computer.choose
      round_conclusion
    end
  end

  def determine_winner(human_mv, computer_mv)
    if human_mv.beats?(computer_mv)
      human
    elsif computer_mv.beats?(human_mv)
      computer
    else
      'tie'
    end
  end

  def display_goodbye_message
    puts "Thanks for playing my object oriented 'Rock, Paper, Scissors' game!"
  end

  def display_welcome_message
    UserInterface.wait(1)
    UserInterface.menu
  end

  def display_winner(winner)
    UserInterface.generate("#{winner.name} won") if winner != 'tie'
    UserInterface.generate("tie game") if winner == 'tie'
  end

  def display_scores
    puts "#{computer.name}: #{computer.score}"
    puts "#{human.name}: #{human.score}"
  end

  def match_conclusion(winner)
    UserInterface.wait(1)
    UserInterface.generate("#{winner.name} won the game")
    @@playing = false
    return unless play_again?
    @@playing = true
    initialize
  end

  def play_again?
    valid_rsp = ['yes', 'no', 'history']
    answer = ''
    loop do
      answer = InputValidator.input("Would you like to play again?", valid_rsp)
      @history.display if answer == 'history'
      break if answer == 'yes' || answer == 'no'
    end
    answer == 'yes'
  end

  def round_conclusion
    human_move = human.move
    computer_move = computer.move
    UserInterface.battle_text(human_move, computer_move)
    @history.update(human_move, computer_move)
    win_logic(human_move, computer_move)
    UserInterface.wait(1)
  end

  def tally_score(plyr)
    plyr.score += 1
  end

  def win_logic(human_mv, computer_mv)
    winner = determine_winner(human_mv, computer_mv)
    display_winner(winner)
    return if winner == 'tie'
    tally_score(winner)
    match_conclusion(winner) if winner.win_game?
  end
end

class Player
  WIN_SCORE = 3

  attr_accessor :move, :score, :name

  def initialize(player_type = :human)
    @player_type = player_type
    @move = nil
    @score = 0
    set_name
  end

  def win_game?
    @score == WIN_SCORE
  end

  protected

  attr_accessor :player_type
end

class Human < Player
  EXTRA_INPUT_CHOICES = ['history', 'exit']
  QUESTION = "Choose rock, paper, scissors, lizard, or spock (history/exit):"

  def choose
    self.move = nil
    possible_choices = Move::VALUES + EXTRA_INPUT_CHOICES
    choice = InputValidator.input(QUESTION, possible_choices)
    return self.move = Move.new(choice).value if Move::VALUES.include?(choice)
    return self.move = choice if choice == 'history'
    RPSGame.exit_game
  end

  def set_name
    self.name = InputValidator.input("What's your name?", [])
  end
end

class Computer < Player
  @@human_last_move = nil

  def choose
    self.move = player_type.choose
  end

  def self.human_last_move=(last)
    @@human_last_move = last
  end

  def set_bot_type
    [R2d2.new, Hal.new, Chappie.new, Robocop.new, Megatron.new].sample
  end

  def set_name
    self.player_type = set_bot_type
    self.name = player_type.class.to_s
  end
end

class R2d2 < Computer
  def initialize; end

  def choose
    Move.new('scissors').value
  end
end

class Hal < Computer
  def initialize; end

  def choose
    Move.new(Move::VALUES.sample).value
  end
end

class Megatron < Computer
  def initialize; end

  def choose
    generate_move
  end

  private

  def generate_move
    if !@@human_last_move.nil?
      p new_moves = Move::VALUES - @@human_last_move.beats
      return Move.new(new_moves.sample).value
    end
    Move.new(Move::VALUES.sample).value
  end
end

class Chappie < Computer
  def initialize; end

  def choose
    return @@human_last_move if !@@human_last_move.nil?
    Move.new('rock').value
  end
end

class Robocop < Computer
  WEIGHTS = [3, 1, 1, 2, 1]
  def initialize; end

  def choose
    generate_move
  end

  private

  def generate_move
    result = []
    Move::VALUES.each_with_index { |ltr, i| WEIGHTS[i].times { result << ltr } }
    Move.new(result.sample).value
  end
end

class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']

  attr_reader :value

  def initialize(value)
    @value = string_to_class(value)
  end

  def beats?(move)
    @beats.include?(move.to_s)
  end

  def to_s
    self.class.to_s.downcase
  end

  private

  def string_to_class(str)
    Object.const_get(str.capitalize).new
  end
end

class Lizard < Move
  BEATS = ['paper', 'spock']
  attr_reader :beats

  def initialize
    @beats = BEATS
  end
end

class Spock < Move
  BEATS = ['scissors', 'rock']
  attr_reader :beats

  def initialize
    @beats = BEATS
  end
end

class Scissors < Move
  BEATS = ['paper', 'lizard']
  attr_reader :beats

  def initialize
    @beats = BEATS
  end
end

class Rock < Move
  BEATS = ['scissors', 'lizard']
  attr_reader :beats

  def initialize
    @beats = BEATS
  end
end

class Paper < Move
  BEATS = ['rock', 'spock']
  attr_reader :beats

  def initialize
    @beats = BEATS
  end
end

class History
  def initialize(human, computer)
    @human = human
    @computer = computer
    @game_number = 0
    @record = {}
  end

  def display
    UserInterface.wait(0.1)
    UserInterface.generate("history")
    puts "=========================================="
    puts "Nothing to show..." if @record.empty?
    @record.each { |k, v| puts "Game number #{k}: #{format_moves(v)}" }
    UserInterface.enter_to_continue
  end

  def update(human, computer)
    store_result(human, computer)
    Computer.human_last_move = find_last_human_move
  end

  private

  def find_last_human_move
    Object.const_get(@record[@game_number][@human.name]).new
  end

  def format_moves(value)
    move_array = value.to_a
    move_array.map! { |element| element[0] + "'s move: " + element[1] }
    move_array.join(' || ')
  end

  def store_result(human_choice, computer_choice)
    @record[@game_number += 1] = { @computer.name => computer_choice.class.to_s,
                                   @human.name => human_choice.class.to_s }
  end
end

RPSGame.new.play
