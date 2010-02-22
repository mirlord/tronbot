
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
                l.gsub!( /^(\s*)(.*)(\s*)$/ ) { ('#' * $1.length) + $2 + ( '#' * $3.length ) }
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
        
        s = Array.new
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
        #think "Space: #{s[1]} + #{s[2]} + #{s[3]} + #{s[4]} + #{s[5]} + #{s[6]} + #{s[7]} + #{s[8]} = #{s[0]}"
        return s
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


