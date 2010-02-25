
require 'lib/utils'
require 'lib/space'

class MirlordBot

    include TronUtils

	def makemove
	    
        @valids = my_valid_moves( @map )
        think "Possible valid moves: #{@valids}"

		if @valids.size == 0
			@map.make_move( 0 )
		else
            collect_weights unless @valids.size < 2

            m = @valids.choose
            m = @valids[ rand(@valids.size) ] if m.nil? # sometimes we can't choose any move

            think "Going to make a move: #{m}"
			m.make
		end
	
	end

    def rival_valids
		rvalids = ValidMovesArray.new( North.new( @map ), East.new( @map ), South.new( @map ), West.new( @map ) )
    end

    def collect_weights

        spaces, total_size = analyze_limited_space( @map, @valids )
        if spaces.size == 1 && @rival_presence
            check_rival_presence( @map, spaces.first )
        end

        if spaces.size > 1
            s_max = spaces.sort.last
            s_max.starting_moves.each do |m|
                @valids[ m.index ].add_weight( 2.0 )
            end
        end
        
        if @rival_presence

            me = @map.my_point
            rival = @map.rival_point
            xd = me.x - rival.x
            yd = me.y - rival.y
            xyd = ( xd.abs - yd.abs ).abs

            if ( xd.abs + yd.abs ) > 2
                if xyd == 0
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
                    follow_longest_delta( xd, yd, 1.1, 0.3 )

                elsif xyd > 1
                    follow_longest_delta( xd, yd, 1.0, 0.4, 0.2 )

                elsif xyd == 1
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
                    ispaces, _ = analyze_limited_space( imap, my_valid_moves( imap ) )
                    rival_ispaces, _ = analyze_limited_space( imap, rival_valid_moves( imap ) )
                    ispaces.sort!
                    rival_ispaces.sort!
                    if ispaces.last.size > rival_ispaces.last.size
                        # cut it!
                        @valids[ cutting_move_index ].add_weight( 1.9 )
                    end
                    follow_longest_delta( xd, yd, 1.0, 0.2, 0.1 )
                end
            elsif ( xd.abs + yd.abs ) == 1
                rvalids = rival_valid_moves( @map )
                if rvalids.size == 1
                    rvalids.each do |rm| # will be executed only once, but for only proper rival valid move
                        imap = @map.imagine( [], nil, [ rm.dst.x, rm.dst.y ] )
                        irvalids = rival_valid_moves( imap ) # rival imagined valid moves
                        blocking_move = @valids.intersects?( irvalids )
                        @valids[ blocking_move.index ].add_weight( 1.8 )
                    end
                end
            end

        else
            try_to_keep_hugging

            try_not_to_split
        end

        try_to_keep_direction

    end

    def try_not_to_split
        @valids.each do |m|
            spaces, total_size = analyze_limited_space( @map, @valids )
            imap = @map.imagine( [], [m.dst.x, m.dst.y] )
            ispaces, total = analyze_limited_space( imap, my_valid_moves( imap ) )
            if ispaces.size > spaces.size
                ispaces.sort!
                # weight MUST be less than 0.8 (so I subtract 0.2),
                # but more than zero (so .abs needed)
                @valids[ m.index ].add_weight( ( ispaces.last.size.to_f / total.to_f - 0.2 ).abs  )
            end
        end
    end

    def follow_longest_delta( xd, yd, base_value = 1.0, base_factor = 0.4, diff_factor = 0 )
        # *wf => x|y weight factor
        xwf = ( base_factor + diff_factor * (xd.abs - yd.abs).sign ) * xd.sign
        ywf = ( base_factor - diff_factor * (xd.abs - yd.abs).sign ) * yd.sign

        #TODO: create a stub object, which silently takes & forgets the weight
        #      to avoid so much 'unless'-es
        @valids[ West.index ].add_weight( base_value + xwf ) unless @valids[ West.index ].nil?
        @valids[ East.index ].add_weight( base_value - xwf ) unless @valids[ East.index ].nil?
        @valids[ North.index ].add_weight( base_value + ywf ) unless @valids[ North.index ].nil?
        @valids[ South.index ].add_weight( base_value - ywf ) unless @valids[ South.index ].nil?
    end

    def try_to_keep_hugging
        @valids.each do |m|
            if m.along_wall?
                @valids[ m.index ].add_weight( 1.2 )
            end
        end
    end

    def analyze_limited_space( map, valids )
        sws = SpaceWidthSearch.new( map )
        valids.each do |m|
            sws.add_starting_move( m )
        end
        spaces = sws.execute
        think "Spaces available:\n    #{spaces.join("\n    ")}"
        return spaces, sws.total_size
    end

    def my_valid_moves( map )
		return ValidMovesArray.new( North.new( map ), East.new( map ), South.new( map ), West.new( map ) )
    end

    def rival_valid_moves( map )
        rp = map.rival_point
		return ValidMovesArray.new( North.new( map, rp ), East.new( map, rp ), South.new( map, rp ), West.new( map, rp ) )
    end

    def check_rival_presence( map, space_info )
        rvalids = rival_valid_moves( map )
        @rival_presence = ! ((rvalids.map { |rm| rm.dst }) & space_info.contents).empty?
    end

    def try_to_keep_direction

        previous = @history.last
        unless previous.nil? || ! @valids.include_index?( previous )
            last_and_valid = @history.last( 5 ).select { |mi| @valids.include_index? mi }
            #think "Trying to keep last from: #{last_and_valid}, while prev was: #{previous}"
            last_and_valid.uniq!

            if last_and_valid.size == 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight 1.1
            elsif last_and_valid.size > 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight 1.05
            elsif last_and_valid.include? previous
                @valids[ previous ].add_weight 1.01
            end
        end

        think "Long direction advice is: #{@valids}"
    end

	def initialize

        @history = Array.new
        @rival_presence = true
        @map = nil
        @valids = nil
	
		while(true)
		
            timed 'Map parsed in' do
                @map = TronMap.read_new( @history )
            end
            timed 'Bot was thinking for' do
			    makemove
		    end

            # a small portion of paranoia :D
            @map = nil
            @valids = nil
		end
	
	end
	
end

