require 'open-uri'

CSA_USI_MAP = {
  '0' => '*',
  '1' => 'a',
  '2' => 'b',
  '3' => 'c',
  '4' => 'd',
  '5' => 'e',
  '6' => 'f',
  '7' => 'g',
  '8' => 'h',
  '9' => 'i',
}

CSA_USI_PIECE_MAP = {
  'FU' => 'P',
  'KY' => 'L',
  'KE' => 'N',
  'GI' => 'S',
  'KI' => 'G',
  'KA' => 'B',
  'HI' => 'R',
  'OU' => 'K',
}

def csa2usi(move)
  if move[1] == '0' &&move[2] == '0'
    m = CSA_USI_PIECE_MAP[move[5..6]]
  else
    m = move[1]
  end
  m + CSA_USI_MAP[move[2]] + move[3] + CSA_USI_MAP[move[4]]
end

def analyze(moves)
  Dir.chdir('./engine')
  line = nil
  candidates = []
  IO.popen('./release', 'r+') do |io|
    io.puts 'usi'
    io.puts 'isready'
    io.puts 'setoption name MultiPV value 1'
    io.puts 'usinewgame'
    while !line&.start_with?('readyok')
      line = io.readline
    end
    position = 'position startpos moves'
    before_score = 0
    moves.each_with_index do |move, turn|
      line = nil
      position = position + ' ' + move
      io.puts position
      io.puts 'go btime 0 wtime 0 byoyomi 1000'
      scores = []
      while !line&.start_with?('best')
        line = io.readline
        line.scan(/score cp (.*?) multipv/).each do |s|
          scores << s[0].to_i
        end
      end
      score = turn%2 == 0 ? scores.max : scores.min
      if (score - before_score).abs > 500
        candidates << turn
      end
      before_score = score
    end
  end
  candidates
end

moves = []
open("https://shogidb2.com/games/4e8a983d9d440b158a6060a968ff70840fb557a1") do |file|
  s = file.read
  s.scan(/\"csa\":\"(.*?)\"/).each do |move|
    move = move[0]
    break if move.include?("TORYO")
    moves << { csa: csa2usi(move) }
  end
  s.scan(/\{"sfen\":\"(.*?)\"/).each_with_index do |sfen, i|
    moves[i][:sfen] = sfen
  end
end
p moves
candidates = analyze(moves.map{|m| m[:csa] })
