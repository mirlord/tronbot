# MirlordBot
# Author: Vladimir Chizhov <master@mirlord.com>


##############################################################################
# Utils

def debug?
    ARGV.include?( '--debug' )
end

class Array

    # Returns the number of nil elements in self. May be zero.
    def nils_count
        self.select { |e| e.nil? }.size
    end

end

class NilClass
    include Comparable 

    def <=>( move )
        return 0 if move.nil?
        return -1
    end

end

module TronUtils

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

end

##############################################################################
# Core

NORTH=1
EAST=2
SOUTH=3
WEST=4

class Point

    attr_reader :x, :y

    def initialize( map, x, y )
        @map = map
        @x = x
        @y = y
        @space = nil
    end

    def north
        Point.new( @map, @x, @y - 1 ) unless @y == 0
    end

    def south
        Point.new( @map, @x, @y + 1 ) unless @y == @map.height
    end

    def west
        Point.new( @map, @x - 1, @y ) unless @x == 0
    end

    def east
        Point.new( @map, @x + 1, @y ) unless @y == @map.width
    end

    def space( direction_name )
        @space = @map.calculate_space( self ) if @space.nil?

        case direction_name
            when :north
                @space[1] + @space[2] + @space[3]
            when :east
                @space[3] + @space[5] + @space[8]
            when :south
                @space[6] + @space[7] + @space[8]
            when :west
                @space[1] + @space[4] + @space[6]
            else
                0
        end
    end

    def inspect
        to_s
    end

    def to_s
        "<x=#{@x}; y=#{@y}>"
    end

end

class ValidMovesArray

    include TronUtils

    def initialize( *moves )
        @moves = moves
        @moves.collect! do |m|
            m if m.possible?
        end
    end

    def each( &block )
        @moves.each do |e|
            yield( e ) unless e.nil?
        end
    end

    def opposite?
        ( nsize == 2) && ( ( @moves[0].nil? && @moves[2].nil? ) || ( @moves[1].nil? && @moves[3].nil? )  )
    end
    
    def nsize
        @moves.size - @moves.nils_count
        #self.compact.size
    end

    def include?( mindex )
        ! @moves[ mindex ].nil?
    end

    def inspect
        to_s
    end

    def to_s
        "\n    " + @moves.join( "\n    " )
    end

    def choose
        #choose_top
        choose_optimal
    end

    def choose_optimal
        think "Choosing optimal from: #{@moves}"

        sorted = @moves.sort

        think "Collected weights: #{sorted}"
        sorted.last
    end

    def []( index )
        @moves[ index ]
    end

end

class Move
    
    include TronUtils
    include Comparable

    attr_reader :src, :dst, :cvalue, :weights, :index

    # Parameters:
    # @map [Map]
    # @source [Point]
    # @destination [Point]
    def initialize( map, source, cvalue, destination_method_name = nil, index = nil )
        @map = map
        @src = ( source.nil? ) ? map.my_point : source
        dst_method = ( destination_method_name.nil? ) ? @src.method( self.name ) : @src.method( destination_method_name )
        @dst = dst_method.call
        @cvalue = cvalue
        @index = ( index.nil? ) ? cvalue - 1 : index # but I recommend not to specify index manually
        @weights = Array.new
    end

    def possible?
        ! @map.wall?( @dst.x, @dst.y )
    end

    def make
        @map.history << @index
        @map.make_move( @cvalue )
    end
    
    def add_weight( w )
        @weights << w unless w.nil?
    end

    def weight
        # hmm... I'm not sure, that a default weight should be 0 or 0.01 or ...
        return 0.01 if @weights.empty?
        res = 1.0
        @weights.each do |w|
            res = res * w
        end
        return res
    end

    def space
        @src.space( self.name )
    end

    def respace
        @src.space( self.opposite_name )
    end

    def name
        :unknown
    end

    def <=>( comp )
        return 1 if comp.nil?
        self.weight <=> comp.weight
    end

    def inspect
        to_s
    end

    def to_s
        "#{self.name}: from #{@src}, to #{@dst} | w: [#{@weights.join(' * ')}] = #{self.weight}"
    end

end

class North < Move

    def initialize( map, source = nil )
        super( map, source, 1 )
    end

    def name
        :north
    end

    def opposite_name
        :south
    end

end

class East < Move

    def initialize( map, source = nil )
        super( map, source, 2 )
    end

    def name
        :east
    end

    def opposite_name
        :west
    end

end

class South < Move

    def initialize( map, source = nil )
        super( map, source, 3 )
    end

    def name
        :south
    end

    def opposite_name
        :north
    end

end

class West < Move

    def initialize( map, source = nil )
        super( map, source, 4 )
    end

    def name
        :west
    end

    def opposite_name
        :east
    end

end

class MirlordBot

    include TronUtils

    # @map [Map]
	def makemove( map )
	    
		valids = ValidMovesArray.new( North.new( map ), East.new( map ), South.new( map ), West.new( map ) )
        think "Possible valid moves: #{valids}"
		
		if valids.nsize == 0
			map.make_move( 0 )
		else
            collect_weights( map, valids )

            m = valids.choose
            m = valids[ rand(valids.size) ] if m.nil? # sometimes we can't choose any move

            # It's a protection from errors. Should be enabled only in production
            #m = valid_moves[rand(valid_moves.size)] unless valid_moves.include?( m ) && (! debug?)

            think "Going to make a move: #{m}"
			m.make
		end
	
	end

    def collect_weights( map, valids )

        try_to_keep_direction( map, valids )
        
        escape_from_rival( map, valids )

        # on 2 opposite directions
        if valids.opposite?
            dichotomy( map, valids )
        end
    end

    def try_to_keep_direction( map, valids )

        previous = @history.last
        unless previous.nil? || ! valids.include?( previous )
            last = @history.last( 5 ).select { |m| valids.include? m }
            #think "Trying to keep last from: #{last}, while prev was: #{previous}"
            last.uniq!

            if last.length == 1 && last[0] == previous
                valids[ previous ].add_weight 0.8
            elsif last.length > 1 && last[0] == previous
                valids[ previous ].add_weight 0.7
            elsif last.include? previous
                valids[ previous ].add_weight 0.5
            else
                valids[ previous ].add_weight 0.2
            end
        end

        think "Long direction advice is: #{valids}"
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
    end

    def dichotomy( map, valids )
        # it *could* be done quicker, but not significantly, I guess
        valids.each do |m|
            s = m.space
            w = s * 100 / (s + m.respace)
        end
    end

	def initialize

        @history = Array.new
	
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
# MAP

class Map

	attr_reader :width, :height, :my_position, :rival_position, :history
	
	def initialize( history )
	
        @history = history
		@width = -1
		@height = -1
		@walls = []
		@my_position = [-1,-1]
		@rival_position = [-1,-1]
		
		read_map
		
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

    def my_point
        x, y = my_position
        Point.new( self, x, y )
    end
	
	def each(&proc)
		
		(0..@height-1).each{|y|
			(0..@width-1).each{|x|
				proc[x, y, wall?(x, y)]
			}
		}
		
	end
	
    # @p [Point]
    # return [Array] 9 elements with zone weights
    # 123
    # 4-5
    # 678
    # 0 = full
    # large weight is bad!
    #
    # cost ~0.00023 sec
    def calculate_space( p )
        ll = []
        cl = []
        rl = []

        x = p.x # very beatiful
        y = p.y # and useful :)

        (0..@height-1).each do |ln|
            start = ln * @width
            fl = @walls[start, @width] # full line
            ll.concat( fl[0, x] )
            cl.concat fl[x, 1]
            rl.concat fl[x+1, @width-x-1]
        end

        s[1] = ll[0,x*y].nils_count
        s[2] = cl[0,y].nils_count
        s[3] = rl[0,y*(@width-x-1)].nils_count

        s[4] = ll[x*y,x].nils_count
        s[5] = rl[y*(@width-x-1),@width-x-1].nils_count

        s[6] = ll[(x*y+x)..(ll.length-1)].nils_count
        s[7] = cl[(y+1)..@height-1].nils_count
        s[8] = rl[(@width-x-1)*(y+1)..(rl.length-1)].nils_count

        s[0] = 0
        s.each do |i|
            s[0] = s[0] + i
        end

        # debug assertions
        think "space: #{s[1]} + #{s[2]} + #{s[3]} + #{s[4]} + #{s[5]} + #{s[6]} + #{s[7]} + #{s[8]} = #{s[0]}"
        return s
    end

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

		$stdout << direction
		$stdout << "\n"
		$stdout.flush
		
	end
	
end

MirlordBot.new()

