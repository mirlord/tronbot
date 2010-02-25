
require 'lib/utils'

class Map
    
    include TronUtils

protected

    attr_writer :my_point, :rival_point
    
public

    attr_reader :width, :height, :history, :my_point, :rival_point
	
	def initialize( history = [] )
	
        @history = history
        @width = -1
        @height = -1
        @walls = []
        @my_point = nil
        @rival_point = nil
        @points = nil
		
	end

    def initialize_copy( from_map )
        #@history = @history.clone # unnecessary, so skipped for performance
        @walls = @walls.clone
        @my_point = nil
        @rival_point = nil
        @points = Array.new( @width ) { Array.new( @height ) }
    end

    def set_wall_at( x, y )
        @walls[ y * @width + x ] = true
    end
    protected :set_wall_at

    def self.read_new( history = [] )
        m = Map.new( history )
        m.read_map
        return m
    end

    # @walls: [Array<Point>]
    # @my_coords [Array<Fixnum,Fixnum>] nil means unchanged
    # @rival_coords [Array<Fixnum,Fixnum>] nil means unchanged
    def imagine( iwalls = [], my_coords = nil, rival_coords = nil )

        mcopy = self.clone
        iwalls.each do |iwp|
            mcopy.set_wall_at( iwp.x, iwp.y )
        end

        my_coords = [self.my_point.x, self.my_point.y] if my_coords.nil?
        rival_coords = [self.rival_point.x, self.rival_point.y] if rival_coords.nil?
        
        x, y = my_coords
        mcopy.my_point = mcopy.p( x, y, true )
        mcopy.set_wall_at( x, y )
        x, y = rival_coords
        mcopy.rival_point = mcopy.p( x, y, true )
        mcopy.set_wall_at( x, y )

        return mcopy
    end

	def read_map
	
		begin
		
			#read the width and height from the first line
			firstline = $stdin.readline("\n")
			width, height = firstline.split(" ")
			@width = width.to_i
			@height = height.to_i

            @points = Array.new( @width ) { Array.new( @height ) }
			
			#check for properly formatted width, height
			if height == 0 or width == 0
				p "OOPS!: invalid map dimensions: " + firstline
				exit(1)
			end
			
			#read the representation of the board
			lines = []
			@height.times do
                l = $stdin.readline("\n").chomp
                # the following became unnecessary
                #l.gsub!( /^(\s*)(.*)(\s*)$/ ) { ('#' * $1.length) + $2 + ( '#' * $3.length ) }
				lines << l
                #think "Readline '#{lines.last}' (l=#{lines.last.length})"
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
			
			px = p1start % @width
			py = (p1start / @width)
			@my_point = p( px, py, true )
			
			px = p2start % @width
			py = (p2start / @width)
			@rival_point = p( px, py, true )
					
			
		rescue EOFError => e
			# Got EOF: tournament is finished.
			exit(0)
			
		rescue => e
			p  e
			exit(1)
		end
	
	end

	def each(&proc)
		
		(0..@height-1).each{|y|
			(0..@width-1).each{|x|
				proc[x, y, wall?(x, y)]
			}
		}
		
	end
	
	def wall? (x, y)
		return true if x < 0 or y < 0 or x >= @width or y >= @height
		return @walls[x+@width*y]
	end

    def p( x, y, withwalls = false )
        return nil if x.outside?( 0, @width-1 ) || y.outside?( 0, @height-1 )
        if ! wall?(x,y) || withwalls
            unless @points[x][y].nil?
                @points[x][y]
            else
                @points[x][y] = Point.new( self, x, y )
            end
        end
    end

	def to_string

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


