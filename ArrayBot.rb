# MirlordBot
# Author: Vladimir Chizhov <master@mirlord.com>

def debug?
    ARGV.include?( '--debug' )
end

def think( *args )
    # do nothing in production
end

# redefine 'think' for debug mode
def think( *args )
    $stderr.puts "BT> #{args.join("\n -> ")}\n"
end if debug?

# for timing
def timed( msg, &block )
    from = Time.now
    yield
    to = Time.now
    $stderr.puts "> #{msg}: #{ (to - from) } sec"
end

##############################################################################
# Core

NORTH=1
EAST=2
SOUTH=3
WEST=4

class MovesHistory
    
    attr_reader :mhist

    def initialize
        @mhist = []
    end

    def remember( move )
        @mhist.insert( 0, move )
    end

    # last N moves
    def last( n = 1 )
        return nil if @mhist.empty?
        return @mhist[0] if n == 1
        @mhist[0,(n <= @mhist.length) ? n : @mhist.length]
    end

    def forget
        @mhist.clear
    end

end

class MirlordBot

	def makemove(map)
	
		x, y = map.my_position
		
		valid_moves = []
		valid_moves << NORTH if not map.wall?(x, y-1)
		valid_moves << SOUTH if not map.wall?(x, y+1)
		valid_moves << WEST  if not map.wall?(x-1, y)
		valid_moves << EAST  if not map.wall?(x+1, y)
        
        think "Possible valid moves: #{valid_moves}"
		
		if(valid_moves.size == 0)
			map.make_move( WEST ) # Self-murder, GO WEST :)
		else

            # advices - array of arrays, each of them consists of 2 elements: direction & weight (0-100)
            advices = collect_advices( map, valid_moves )

            m = choose( advices, valid_moves ) unless advices.empty?
            m = valid_moves[rand(valid_moves.size)] if m.nil? || m == 0
            # It's a protection from errors. Should be enabled only in production
            #m = valid_moves[rand(valid_moves.size)] unless valid_moves.include?( m ) && (! debug?)
            think "Going to make a move: #{m}"
			map.make_move( m )
		end
	
	end

    def collect_advices( map, valids )
        advices = Array.new

        advices.concat( try_to_keep_direction( map, valids ) )
        advices.concat( escape_from_rival( map, valids ) )
        # on 2 opposite directions
        if valids.size == 2
            advices.concat( dichotomy( map, valids ) )
        end

        return advices
    end

    def try_to_keep_direction( map, valids )
        moves = []
        previous = @history.last
        
        unless previous.nil?
            last = @history.last( 5 ).select { |e| valids.include? e }
            last.uniq!
            #think "Trying to keep last from: #{last}, while prev was: #{previous}"

            if last.length == 1 && last[0] == previous
                moves << [previous, 90]
            elsif last.length > 1 && last[0] == previous
                moves << [previous, 70]
            elsif last.include? previous
                moves << [previous, 50]
            elsif valids.include? previous
                moves << [previous, 20]
            end
        end

        think "Long direction advice is: #{moves}"
        return moves
    end

    def detect_threats( map, valids )
        #TODO: REFACTOR ALL THIS BULLSHIT BEFORE CONTINUE
        #detect_gates( map, valids )
    end

    def escape_from_rival( map, valids )
		x, y = map.my_position
		rx, ry = map.rival_position

        if ( (rx - x).abs + (ry - y).abs ) <= 5
            think "I'm not afraid of you, guy! :)".gsub( /(g).(y)/ ) { |s| $1 + "a" + $2 }
        end
        return []
    end

    def dichotomy( map, valids )
        if (valids[0] + valids[1]) == 4 
            dichotomyNS( map.space )
        elsif (valids[0] + valids[1]) == 6
            dichotomyWE( map.space )
        else
            []
        end
    end

    # North-South
    def dichotomyNS( tr )
        north_tr = tr[1] + tr[2] + tr[3]
        south_tr = tr[6] + tr[7] + tr[8]
        north_w = north_tr*100 / (north_tr + south_tr)

        moves = [ [NORTH, north_w], [SOUTH, 100 - north_w] ]
    end

    # West-East
    def dichotomyWE( tr )
        west_tr = tr[1] + tr[4] + tr[6]
        east_tr = tr[3] + tr[5] + tr[8]
        west_w = west_tr*100 / (west_tr + east_tr)

        moves = [ [WEST, west_w], [EAST, 100 - west_w] ]
    end

    def choose( moves, valids )
        #choose_top( moves )
        choose_optimal( moves )
    end

    def choose_top( moves )
        think "Choosing top from #{moves}"
        moves.sort! do |a, b|
            a[1] <=> b[1]
        end
        think "Top choice is: #{moves.last}"
        return moves.last[0]
    end

    def choose_optimal( moves )
        think "Choosing optimal from: #{moves}"

        choice = Array.new( 5 )
        moves.each do |m|
            i = m[0]
            choice[ i ] = 1.0 if choice[ i ].nil? # on first occurence - init with 1.0 weight
            choice[ i ] = choice[ i ] * ( m[1] / 100.0 )
        end

        think "Collected weights: #{choice}"

        imax = 0
        max = 0
        choice.each_index do |i|
            imax = (max < choice[i]) ? i : imax unless choice[i].nil?
        end
        think "Optimal choice is: #{imax}"
        return imax
    end

	def initialize

        @history = MovesHistory.new
	
		while(true)
		
            map = nil
            timed 'Map parsed in' do
                map = Map.new( @history )
            end
            timed 'Bot was thinking for' do
			    makemove(map)
		    end
		end
	
	end
	
end

##############################################################################
# utils

class Array

    # Returns the number of nil elements in self. May be zero.
    def nils_count
        self.select { |e| e.nil? }.size
    end

end

##############################################################################
# MAP

class Map

	attr_reader :width, :height, :my_position, :rival_position, :space
	
	def initialize( history )
	
        @history = history
		@width = -1
		@height = -1
		@walls = []
		@my_position = [-1,-1]
		@rival_position = [-1,-1]
        @space = []
		
		read_map
        calculate_space
		
	end	
	
	def read_map
	
		begin
		
			#read the width and height from the first line
			firstline = $stdin.readline("\n")
			width, height = firstline.split(" ")
			@width = width.to_i
			@height = height.to_i
			
			#check for properly formatted width, height
			if height == 0 or width == 0
				p "OOPS!: invalid map dimensions: " + firstline
				exit(1)
			end
			
			#read the representation of the board
			lines = []
			@height.times do
				lines += [$stdin.readline("\n").strip]
			end
			board = lines.join("")
			
			#get the wall data
            # using nil as 'false' for quick 'nils_count' weight counting
			@walls = board.split(//).map{|char| char == " " ? nil : true}
			
			#get player starting locations
			p1start = board.index("1").to_i
			p2start = board.index("2").to_i
			
			if board.split(//).select{|char| char == "1"}.size > 1
				p "OOPS!: found more than 1 location for player 1"
				exit(1)
			end
			
			if board.split(//).select{|char| char == "2"}.size > 1
				p "OOPS!: found more than 1 location for player 2"
				exit(1)
			end
			
			p "OOPS!: Cannot find locations." if p1start == nil or p2start == nil
			
			pstartx = p1start % @width
			pstarty = (p1start / @width)
			@my_position = [pstartx, pstarty]
			
			pstartx = p2start % @width
			pstarty = (p2start / @width)
			@rival_position = [pstartx, pstarty]
					
			
		rescue EOFError => e
			# Got EOF: tournament is finished.
			exit(0)
			
		rescue => e
			p  e
			exit(1)
		end
	
	end
	private :read_map
	
	def each(&proc)
		
		(0..@height-1).each{|y|
			(0..@width-1).each{|x|
				proc[x, y, wall?(x, y)]
			}
		}
		
	end
	
    # return [Array] 9 elements with zone weights
    # 123
    # 4-5
    # 678
    # 0 = full
    # large weight is bad!
    #
    # cost ~0.00023 sec
    def calculate_space
        ll = []
        cl = []
        rl = []
        x, y = @my_position

        (0..@height-1).each do |ln|
            start = ln * @width
            fl = @walls[start, @width] # full line
            ll.concat( fl[0, x] )
            cl.concat fl[x, 1]
            rl.concat fl[x+1, @width-x-1]
        end

        @space[1] = ll[0,x*y].nils_count
        @space[2] = cl[0,y].nils_count
        @space[3] = rl[0,y*(@width-x-1)].nils_count

        @space[4] = ll[x*y,x].nils_count
        @space[5] = rl[y*(@width-x-1),@width-x-1].nils_count

        @space[6] = ll[(x*y+x)..(ll.length-1)].nils_count
        @space[7] = cl[(y+1)..@height-1].nils_count
        @space[8] = rl[(@width-x-1)*(y+1)..(rl.length-1)].nils_count

        @space[0] = 0
        @space.each do |i|
            @space[0] = @space[0] + i
        end

        # debug assertions
        think "space: #{@space[1]} + #{@space[2]} + #{@space[3]} + #{@space[4]} + #{@space[5]} + #{@space[6]} + #{@space[7]} + #{@space[8]} = #{@space[0]}"
    end
	private :calculate_space

	def wall? (x, y)
		return true if x < 0 or y < 0 or x >= @width or y >= @height
		return @walls[x+@width*y]
	end
	
	def to_string()

		out = ""
		counter = 0
				
		@height.times do
			@width.times do
				out += @walls[counter] == true ? "#" : "-"
				counter+=1
			end
			out += "\n"
		end
		
		
		return out
		
	end



	def make_move(direction)

        @history.remember( direction )
	
		$stdout << direction
		$stdout << "\n"
		$stdout.flush
		
	end
	
end

MirlordBot.new()

