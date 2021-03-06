
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


class Fixnum

    def inside_i?( from, to )
        inside_e?( from, to ) || self == from || self == to
    end

    def inside_e?( from, to )
        self > from && self < to
    end

    def outside?( from, to )
        ! inside_i?( from, to )
    end

    def sign
        self <=> 0
    end

end

class Float

    def sign
        self <=> 0.0
    end

end

class Array

    def nils_count
        nindexes.size
    end

    def nindexes
        r = []
        self.each_index do |i|
            r << i if self[i].nil?
        end
        return r
    end

    def only
        raise "This array contains more than one element" if size > 1
        return first if ! empty? # So in case of empty aray result is 'nil'
    end

    def nsize
        compact.size
    end

    def nlast
        self.reverse_each do |e|
            return e if ! e.nil?
        end
    end

    def nfirst
        self.each do |e|
            return e if ! e.nil?
        end
    end

end

class NilClass
    include Comparable 

    def <=>( move )
        return 0 if move.nil?
        return -1
    end

end

class TronMap

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
        m = TronMap.new( history )
        m.read_map
        return m
    end

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

			firstline = $stdin.readline("\n")
			width, height = firstline.split(" ")
			@width = width.to_i
			@height = height.to_i

            @points = Array.new( @width ) { Array.new( @height ) }

			if height == 0 or width == 0
				p "OOPS!: invalid map dimensions: " + firstline
				exit(1)
			end

			lines = []
			@height.times do
                l = $stdin.readline("\n").chomp
				lines << l
			end
			board = lines.join("")

			@walls = board.split(//).map{|char| char == " " ? nil : true}

			p1start = board.index("1").to_i
			p2start = board.index("2").to_i

			if board.split(//).select{|char| char == "1"}.size > 1
				$stderr.puts "OOPS!: found more than 1 location for player 1"
				exit(1)
			end

			if board.split(//).select{|char| char == "2"}.size > 1
				$stderr.puts "OOPS!: found more than 1 location for player 2"
				exit(1)
			end

			$stderr.puts "OOPS!: Cannot find locations." if p1start == nil or p2start == nil

			px = p1start % @width
			py = (p1start / @width)
			@my_point = p( px, py, true )

			px = p2start % @width
			py = (p2start / @width)
			@rival_point = p( px, py, true )


		rescue EOFError => e
			exit(0)

		rescue => e
			$stderr.puts  e
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

class Point

    attr_reader :x, :y

    def initialize( map, x, y )
        @map = map
        @x = x
        @y = y
    end

    def sibling( direction, withwalls = true )
        self.method( direction ).call( withwalls )
    end

    def siblings( withwalls = true )
        [ self.north( withwalls ), self.east( withwalls ), self.south( withwalls ), self.west( withwalls ) ]
    end

    def north( withwalls = true )
        @map.p( @x, @y - 1, withwalls )
    end

    def south( withwalls = true )
        @map.p( @x, @y + 1, withwalls )
    end

    def west( withwalls = true )
        @map.p( @x - 1, @y, withwalls )
    end

    def east( withwalls = true )
        @map.p( @x + 1, @y, withwalls )
    end

    def wall?
        @map.wall?( @x, @y )
    end

    def inspect
        to_s
    end

    def to_s
        "<x=#{@x}; y=#{@y}>"
    end

    def eql?( comp )
        self.x == comp.x && self.y == comp.y
    end

    def <=>( comp )
        return 0 if self == comp
    end

    def equal?
        self.eql?( comp )
    end

    def ==( comp )
        self.eql?( comp )
    end

end

class SpaceWidthSearch

    DEPTH_LIMIT_DEFAULT=225

    attr_reader :total_size

    def initialize( map, reduce_deep_factor )
        @spaces = []
        @done = []
        @map = map
        @deep = DEPTH_LIMIT_DEFAULT / reduce_deep_factor
        @total_size = 0
    end

    def add_starting_move( m )
        @spaces << SpaceInfo.new( m )
    end

    def execute
        while @total_size < DEPTH_LIMIT_DEFAULT
            merge_intersections
            @spaces.reject! do |si|
                if si.closed?
                    @done << si
                end
            end

            break if @spaces.empty?

            @spaces.each do |si|
                si.pop_each do |p|
                    @total_size += 1
                    si.push( p.siblings( false ) )
                end
            end
        end
        @done += @spaces
        @spaces.each do |si|
            @total_size += si.boundaries.size
        end
        return @done
    end

    def merge_intersections
        @spaces.each_index do |si_i|
            (0..(si_i - 1)).each do |ci|
                @spaces[ci] = nil if @spaces[si_i].merge!( @spaces[ci] )
            end
        end
        @spaces.compact!
    end
    private :merge_intersections

end

class SpaceInfo

    attr_reader :starting_moves, :boundaries, :contents

    def initialize( m )
        p = m.dst
        @starting_moves = [ m ]
        @boundaries = [ p ]
        @contents = [ p ] # contents always include boundaries
    end

    def push( points )
        points.each do |p|
            unless p.nil? || @contents.include?( p )
                @contents << p
                @boundaries << p
            end
        end
    end

    def closed?
        @boundaries.empty?
    end

    def size
        @contents.size
    end

    def merge!( si )
        return nil unless intersects_with?( si )

        @starting_moves += si.starting_moves
        @contents += si.contents
        @boundaries += si.boundaries
        @contents.uniq!
        @boundaries.uniq!
        return self
    end

    def intersects_with?( si )
        ! (contents & si.contents).empty? unless si.nil?
    end

    def pop_each
        # without temporary array, pop & push falls into a kind of conflict
        tmp = @boundaries.clone
        @boundaries.clear
        tmp.each do |p|
            yield( p )
        end
    end

    def inspect
        to_s
    end

    def to_s
        "Space area ( size=#{self.size} ):: #{@starting_moves}"
    end

    def <=>( comp )
        size <=> comp.size
    end

end

class ValidMovesArray

    def initialize( *moves )
        @moves = Array.new( moves.size, nil )
        moves.each do |m|
            @moves[ m.index ] = m if m.possible?
        end
    end

    def each( &block )
        @moves.each do |e|
            yield( e ) unless e.nil?
        end
    end

    def map( &block )
        r = Array.new
        @moves.each do |e|
            r << yield( e ) unless e.nil?
        end
        return r
    end

    def include?( move )
        @moves.include?( move )
    end

    def intersection( moves )
        dsts = moves.map { |m| m.dst }
        r = []
        each do |m|
            r << m if dsts.include?( m.dst )
        end
        return r
    end

    def size
        @moves.nsize
    end

    def empty?
        size == 0
    end

    def include_index?( mindex )
        ! @moves[ mindex ].nil?
    end

    def inspect
        to_s
    end

    def to_s
        pretty_print_a( @moves )
    end

    def pretty_print_a( a )
        "\n  > " + a.reject { |m| m.nil? }.join( "\n  > " )
    end

    def choose_anyway
        return @moves.nfirst if size == 1
        m = choose_optimal
        if m.nil?
            m = choose_random
        end
        #think "Anyway choice is #{m}"
        return m
    end

    def choose_random
        return @moves.compact[ rand( size ) ]
    end

    def choose_optimal

        sorted = @moves.sort.compact
        #think "Choosing from: #{@moves}"

        return nil if sorted.empty? || ( sorted.last.weight == sorted.first.weight )
        return sorted.last
    end

    def []( index )
        @moves[ index ]
    end

end

class Move

    include Comparable

    BASE_WEIGHT = 1.0

    attr_reader :src, :dst

    def initialize( map, source, destination_method_name = nil )
        @map = map
        @src = ( source.nil? ) ? map.my_point : source
        dst_method = ( destination_method_name.nil? ) ? @src.method( dname ) : @src.method( destination_method_name )
        @dst = dst_method.call
        @weights = Array.new
        @weight = nil

        @dst_walls = (@src.x == @dst.x) ? [ @dst.west, @dst.east ] : [ @dst.north, @dst.south ]
    end

    def self.cvalue
        raise "Not overriden (but MUST) in #{self.class.name}"
    end

    def self.index
        self.cvalue - 1
    end

    def cvalue
        self.class.cvalue
    end

    def index
        self.class.index
    end

    def possible?
        ! @map.wall?( @dst.x, @dst.y )
    end

    def make
        @map.history << index
        @map.make_move( cvalue )
    end

    def add_weight( w )
        @weights << w unless w.nil?
        @weight = nil
    end

    def weight
        if @weight.nil?
            @weight = BASE_WEIGHT
            @weights.each do |w|
                @weight = @weight * w
            end
        end
        return @weight
    end

    def <=>( comp )
        return 1 if comp.nil?
        self.weight <=> comp.weight
    end

    def inspect
        to_s
    end

    def to_s
        "#{dname} | from #{@src}, to #{@dst} | w: [#{@weights.join(' * ')}] = #{self.weight}"
    end

    def dname
        :"#{self.class.name.downcase}"
    end

    def walls_count
        n = 0
        @dst_walls.each do |p|
            n += 1 if p.wall?
        end
        return n
    end
    private :walls_count

    def wall_type
        return :corner if walls_count == 1 && ! front_move.possible?
        return :gate if walls_count == 2
        return :single if walls_count == 1
        return nil # otherwise
    end

    def along_wall?
        return true if walls_count > 0
    end

    def front_move
        @front_move = self.class.new( @map, @dst ) if @front_move.nil?
        return @front_move
    end

    def has_front_points?
        return ( ! front_move.possible? || front_move.along_wall? ) ? true : false
    end

end

class North < Move

    def initialize( map, source = nil )
        super( map, source )
    end

    def self.cvalue
        return 1
    end

end

class East < Move

    def initialize( map, source = nil )
        super( map, source )
    end

    def self.cvalue
        return 2
    end

end

class South < Move

    def initialize( map, source = nil )
        super( map, source )
    end

    def self.cvalue
        return 3
    end

end

class West < Move

    def initialize( map, source = nil )
        super( map, source )
    end

    def self.cvalue
        return 4
    end

end

class MirlordBot

	def makemove

        @valids = my_valid_moves( @map )
        @rival_valids = rival_valid_moves( @map )

		if @valids.size == 0
			@map.make_move( West.cvalue )
        elsif @valids.size == 1
            @valids.choose_anyway.make
		else # @valids.size > 1
            @spaces_base, @spaces_total = analyze_limited_space( @map, @valids )
            collect_weights
            m = @valids.choose_optimal

            if m.nil?
                try_to_keep_direction
                m = @valids.choose_anyway
            end

			m.make
		end

	end

    def collect_weights

        spaces = @spaces_base
        if spaces.size == 1 && @rival_presence
            check_rival_presence( spaces.first )
        end

        if spaces.size > 1
            s_max = spaces.sort.last
            s_max.starting_moves.each do |m|
                @valids[ m.index ].add_weight( 2.0 )
            end
            try_not_to_split( s_max.starting_moves )
        else
            if @rival_presence

                me = @map.my_point
                rival = @map.rival_point
                xd = me.x - rival.x
                yd = me.y - rival.y
                xyd = ( xd.abs - yd.abs ).abs

                if ( xd.abs + yd.abs ) == 1
                    try_to_block

                elsif ( xd.abs + yd.abs ) == 3 && xyd == 1
                    try_not_to_be_cutoff

                elsif ( xd.abs + yd.abs ) == 2
                    check_draw_profit

                else
                    case xyd
                    when 0
                        try_to_headon_diag
                        follow_delta( :long, xd, yd, 1.1, 0.3 )

                    when 1
                        #try_to_cut( me, rival ) #it's a bullshit!
                        follow_delta( :long, xd, yd, 1.0, 0.4, 0.2 )

                    else
                        follow_delta( :long, xd, yd, 1.0, 0.4, 0.2 )

                    end
                end

                if ! @rival_presence_confirmed
                    #think "Unconfirmed, so trying not to split"
                    try_not_to_split( @valids )
                end

                # TODO: need optimization
                #try_to_predict_splits

            else
                try_to_keep_hugging

                try_not_to_split( @valids )
            end
        end

    end

    def try_not_to_be_cutoff
        me = @map.my_point
        rival = @map.rival_point
        xd = me.x - rival.x
        yd = me.y - rival.y

        cutoff_moves = []
        @rival_valids.each do |rm|
            cutoff_moves << rm if (me.x - rm.dst.x).abs + (me.y - rm.dst.y).abs == 2
        end
        #think "Cutoffs: #{cutoff_moves}"
        return follow_delta( :short, xd, yd, 1.0, 0.4, 0.2 ) if cutoff_moves.empty?

        my_moves = []
        @valids.each do |m|
            my_moves << m if (m.dst.x - rival.x).abs + (m.dst.y - rival.y).abs == 2
        end
        return follow_delta( :long, xd, yd, 1.0, 0.4, 0.2 ) if my_moves.empty?
        
        cutoff_moves.each do |m|
            imap = @map.imagine( [], nil, [ m.dst.x, m.dst.y ] )
            ispaces, _ = analyze_limited_space( imap, my_valid_moves( imap ), 2 )
            if ispaces.size > 1
                ispaces.sort!
                ispaces.last.starting_moves.each do |m|
                    @valids[ m.index ].add_weight( 1.9 ) unless @valids[ m.index ].nil?
                end
            else
                return follow_delta( :long, xd, yd, 1.0, 0.4, 0.2 ) if my_moves.empty?
            end
        end
        
    end

    def check_draw_profit
        draw_moves = @valids.intersection( @rival_valids )
        return if draw_moves.empty?

        me = @map.my_point
        rival = @map.rival_point
        xd = me.x - rival.x
        yd = me.y - rival.y

        if (xd.abs - yd.abs) == 2 # unless (xd.abs - yd.abs).abs == 0
            #think "Checking draw profit for straight head-on"
            rival_icoords = [ me.x - xd.sign, me.y - yd.sign ]
            imap = @map.imagine( [], nil, rival_icoords )
            my_ispaces, _ = analyze_limited_space( imap, my_valid_moves( imap ) )
            #think "Spaces: #{my_ispaces}"
            if my_ispaces.size == 1
                draw_moves.each do |dm|
                    @valids[ dm.index ].add_weight( 0.85 ) unless @valids[ dm.index ].nil?
                end
            else # my_ispaces.size == 2 # more is impossible
                my_ispaces.sort!
                if (my_ispaces.last.size - my_ispaces.first.size) == 0
                    draw_moves.each do |dm|
                        @valids[ dm.index ].add_weight( 2.0 ) unless @valids[ dm.index ].nil?
                    end
                else
                    s_max = my_ispaces.last
                    s_max.starting_moves.each do |m|
                        @valids[ m.index ].add_weight( 2.0 )
                    end
                end
            end
        end
    end

    def try_to_cut
        me = @map.my_point
        rival = @map.rival_point
        xd = me.x - rival.x
        yd = me.y - rival.y
        xyd = ( xd.abs - yd.abs ).abs

        iwalls = [] # imagined walls
        my_icoords = []
        rival_icoords = []
        cutting_move_index = 0
        if xd.abs < yd.abs
            (1..(xd.abs)).each do |i|
                iwalls << @map.p( me.x - i * xd.sign, me.y, true  )
            end
            (1..(yd.abs - 1)).each do |i|
                iwalls << @map.p( rival.x, rival.y + i * yd.sign, true  )
            end
            my_icoords = [ me.x - xd, me.y ]
            rival_icoords = [ rival.x, rival.y + (yd.abs-1)*yd.sign ]
            cutting_move_index = xd < 0 ? East.index : West.index
        else
            (1..(yd.abs)).each do |i|
                iwalls << @map.p( me.x, me.y - i * yd.sign, true  )
            end
            (1..(xd.abs)).each do |i|
                iwalls << @map.p( rival.x + i * xd.sign, rival.y, true  )
            end
            my_icoords = [ me.x, me.y - yd ]
            rival_icoords = [ rival.x + (xd.abs-1)*xd.sign, rival.y ]
            cutting_move_index = yd < 0 ? South.index : North.index
        end
        imap = @map.imagine( iwalls, my_icoords, rival_icoords ) # imagined map
        ivalids = my_valid_moves( imap )
        irvalids = rival_valid_moves( imap )
        if ivalids.size > 0 && irvalids.size > 0
            ispaces, _ = analyze_limited_space( imap, ivalids )
            rival_ispaces, _ = analyze_limited_space( imap, irvalids )
            ispaces.sort! if ispaces.size > 1
            rival_ispaces.sort! if rival_ispaces.size > 1
            if ispaces.last.size > rival_ispaces.last.size
                # cut it!
                @valids[ cutting_move_index ].add_weight( 1.9 ) unless @valids[ cutting_move_index ].nil?
            end
            follow_delta( :long, xd, yd, 1.0, 0.2, 0.1 )
        end
    end

    def try_to_headon_diag
        me = @map.my_point
        rival = @map.rival_point
        xd = me.x - rival.x
        yd = me.y - rival.y
        xyd = ( xd.abs - yd.abs ).abs

        iwalls = [] # imagined walls
        (1..(xd.abs-1)).each do |i|
            iwalls << @map.p( me.x - i * xd.sign, me.y - i * yd.sign , true  )
        end
        imap = @map.imagine( iwalls )
        ispaces, total_size = analyze_limited_space( imap, my_valid_moves( imap ) )
        if ispaces.size > 1
            ispaces.sort!
            is_max = ispaces.last
            is_max.starting_moves.each do |m|
                @valids[ m.index ].add_weight( 1.2 )
            end

            is_min = ispaces.first
            is_min.starting_moves.each do |m|
                @valids[ m.index ].add_weight( 0.8 )
            end
        end
    end

    def try_to_block
        me = @map.my_point
        rival = @map.rival_point
        xd = me.x - rival.x
        yd = me.y - rival.y
        xyd = ( xd.abs - yd.abs ).abs

        #think "Blocking?"
        rvalids = @rival_valids
        if rvalids.size == 1
            #think "He has no chances!"
            rvalids.each do |rm| # will be executed only once, but for only proper rival valid move
                imap = @map.imagine( [], nil, [ rm.dst.x, rm.dst.y ] )
                #think "He will go to #{rm.dst}"
                irvalids = rival_valid_moves( imap ) # rival imagined valid moves
                #think "And then to #{irvalids}"
                blocking_move = @valids.intersection( irvalids ).first
                #think "I can block it by going to: #{blocking_move}"
                @valids[ blocking_move.index ].add_weight( 1.8 ) unless blocking_move.nil? || @valids[ blocking_move.index ]
            end
        end
    end

    def try_to_predict_splits
        rvalids = @rival_valids
        @valids.each do |my_move|
            rvalids.each do |r_move|
                imap = @map.imagine( [], [my_move.dst.x, my_move.dst.y], [r_move.dst.x, r_move.dst.y] )
                ivalids = my_valid_moves( imap )
                if ivalids.empty?
                    @valids[ my_move.index ].add_weight( 0.2 )
                    next
                end
                ispaces, _ = analyze_limited_space( imap, ivalids )
                rivalids = rival_valid_moves( imap )
                if rivalids.empty?
                    # it's a small chance to cut
                    @valids[ my_move.index ].add_weight( 1.05 )
                    next
                end
                irspaces, _ = analyze_limited_space( imap, rivalids )
                ispaces.sort!
                irspaces.sort!
                if ispaces.last.size < irspaces.last.size
                    @valids[ my_move.index ].add_weight( 0.4 )
                end
            end
        end
    end

    def try_not_to_split( moves )
        spaces = @spaces_base
        moves.each do |m|
            if m.has_front_points?
                #think "Trying not to split for: #{m}"
                imap = @map.imagine( [], [m.dst.x, m.dst.y] )
                ispaces, total = analyze_limited_space( imap, my_valid_moves( imap ) )
                #think "isp=#{ispaces.last.size.to_f}; total=#{total.to_f}; s=#{ispaces.size}"
                if ispaces.size > 1
                    ispaces.sort!
                    @valids[ m.index ].add_weight( ( ispaces.last.size.to_f / total.to_f ) * 0.7 )
                end
            end
        end
    end

    def follow_delta( direction, xd, yd, base_value = 1.0, base_factor = 0.4, diff_factor = 0 )
        direction_factor = (direction == :long) ? 1 : -1 # else :short
        xwf = ( base_factor + diff_factor * (xd.abs - yd.abs).sign * direction_factor ) * xd.sign
        ywf = ( base_factor - diff_factor * (xd.abs - yd.abs).sign * direction_factor ) * yd.sign

        @valids[ West.index ].add_weight( base_value + xwf ) unless @valids[ West.index ].nil?
        @valids[ East.index ].add_weight( base_value - xwf ) unless @valids[ East.index ].nil?
        @valids[ North.index ].add_weight( base_value + ywf ) unless @valids[ North.index ].nil?
        @valids[ South.index ].add_weight( base_value - ywf ) unless @valids[ South.index ].nil?
    end

    def try_to_keep_hugging
        walls_found = false # flag
        @valids.each do |m|
            wt = m.wall_type
            if ! wt.nil?
                walls_found = true
                @valids[ m.index ].add_weight( @wall_weights[ wt ] )
            end
        end
        if !walls_found
            try_to_rotate
        end
    end

    def try_to_rotate
        previous = @history.last
        unless previous.nil?
            @valids[ previous ].add_weight( 0.85 ) unless @valids[ previous ].nil?
        end
    end

    def analyze_limited_space( map, valids, reduce_deep_factor = 1 )
        sws = SpaceWidthSearch.new( map, reduce_deep_factor )
        valids.each do |m|
            sws.add_starting_move( m )
        end
        spaces = sws.execute
        return spaces, sws.total_size
    end

    def my_valid_moves( map )
		return ValidMovesArray.new( North.new( map ), East.new( map ), South.new( map ), West.new( map ) )
    end

    def rival_valid_moves( map )
        rp = map.rival_point
		return ValidMovesArray.new( North.new( map, rp ), East.new( map, rp ), South.new( map, rp ), West.new( map, rp ) )
    end

    def check_rival_presence( space_info )
        rvalids = @rival_valids
        presence = ! ((rvalids.map { |rm| rm.dst }) & space_info.contents).empty?
        if presence # 100% confirmed
            #think "100% presence confirmed"
            @rival_presence = true
            @rival_presence_confirmed = true
        elsif space_info.closed? # 100% absence confirmed
            #think "100% absence confirmed"
            @rival_presence = false
            @rival_presence_confirmed = true
        end
    end

    def try_to_keep_direction

        previous = @history.last
        unless previous.nil? || ! @valids.include_index?( previous )
            last_and_valid = @history.last( 5 ).select { |mi| @valids.include_index? mi }
            last_and_valid.uniq!

            if last_and_valid.size == 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight( 1.1 ) unless @valids[ previous ].nil?
            elsif last_and_valid.size > 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight( 1.05 ) unless @valids[ previous ].nil?
            elsif last_and_valid.include? previous
                @valids[ previous ].add_weight( 1.01 ) unless @valids[ previous ].nil?
            end
        end

    end

	def initialize

        @history = Array.new
        @rival_presence = true
        @rival_presence_confirmed = false
        @map = nil
        @valids = nil
        @spaces_base = nil
        @spaces_total = nil
        @wall_weights = { :single => 1.2, :gate => 1.3, :corner => 1.4 }

		while(true)

            @map = TronMap.read_new( @history )
            makemove

            @map = nil
            @valids = nil
            @spaces_base = nil
            @spaces_total = nil
		end

	end

end

MirlordBot.new()

