
require 'lib/utils'

class Map
    
    include TronUtils

	attr_reader :width, :height, :history
	
	def initialize( history )
	
        @history = history
		@width = -1
		@height = -1
		@walls = []
		@my_position = [-1,-1]
		@rival_position = [-1,-1]
        @points = nil
		
		read_map
		
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
        x, y = @my_position
        p( x, y, true )
    end
	
    def rival_point
        x, y = @rival_position
        p( x, y, true )
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
        if ! self.wall?(x,y) || withwalls
            unless @points[x][y].nil?
                @points[x][y]
            else
                @points[x][y] = Point.new( self, x, y )
            end
        end
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


