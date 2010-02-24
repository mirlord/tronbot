
require 'lib/utils'
require 'lib/space'

class MirlordBot

    include TronUtils

	def makemove
	    
        @valids = my_valid_moves( @map )
        think "Possible valid moves: #{@valids}"

		if @valids.nsize == 0
			@map.make_move( 0 )
		else
            collect_weights unless @valids.nsize < 2

            m = @valids.choose
            m = @valids[ rand(@valids.size) ] if m.nil? # sometimes we can't choose any move

            # It's a protection from errors. Should be enabled only in production
            #m = @valids[rand(@valids.size)] unless @valids.include?( m ) && (! debug?)

            think "Going to make a move: #{m}"
			m.make
		end
	
	end

    def rival_valids
		rvalids = ValidMovesArray.new( North.new( @map ), East.new( @map ), South.new( @map ), West.new( @map ) )
    end

    def collect_weights

        spaces = analyze_limited_space( @map, @valids )
        if spaces.size == 1 && @rival_presence
            check_rival_presence( spaces.first )
        end

        if spaces.size > 1
            s_max = spaces.sort.last
            s_max.starting_moves.each do |m|
                @valids[ m.index ].add_weight( 2.0 )
            end
        end
        
        if @rival_presence

            @primary_strategy = :headon

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
                    ispaces = analyze_limited_space( imap, my_valid_moves( imap ) )
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

                    # *wf => x|y weight factor
                    xwf = 0.3 * xd.sign
                    ywf = 0.3 * yd.sign

                    #TODO: create a stub object, which silently takes & forgets the weight
                    #      to avoid so much 'unless'-es
                    @valids[ West.index ].add_weight( 1.1 + xwf ) unless @valids[ West.index ].nil?
                    @valids[ East.index ].add_weight( 1.1 - xwf ) unless @valids[ East.index ].nil?
                    @valids[ North.index ].add_weight( 1.1 + ywf ) unless @valids[ North.index ].nil?
                    @valids[ South.index ].add_weight( 1.1 - ywf ) unless @valids[ South.index ].nil?

                elsif xyd > 1
                    follow_longest_delta( xd, yd )
                elsif xyd == 1
                    iwalls = [] # imagined walls
                    if xd.abs < yd.abs
                        (1..(xd.abs)).each do |i|
                            iwalls << @map.p( me.x - i * xd.sign, me.y, true  )
                        end
                        (1..(yd.abs)).each do |i|
                            iwalls << @map.p( rival.x, rival.y + i * yd.sign, true  )
                        end
                    else
                        (1..(yd.abs)).each do |i|
                            iwalls << @map.p( me.x, me.y - i * yd.sign, true  )
                        end
                        (1..(xd.abs)).each do |i|
                            iwalls << @map.p( rival.x + i * xd.sign, rival.y, true  )
                        end
                    end
                    imap = @map.imagine( iwalls ) # imagined map
                    ispaces = analyze_limited_space( imap, my_valid_moves( imap ) )
                    follow_longest_delta( xd, yd, 0.5 )
                end
            end

        else
            # TODO: hugging
            @primary_strategy = :hugger # yeah, it will be overwritten each time, I don't care
            try_to_keep_hugging
        end

        try_to_keep_direction

    end

    def follow_longest_delta( xd, yd, reduce_factor = 1.0 )
        # *wf => x|y weight factor
        xwf = ( 0.4 + 0.2 * (xd.abs - yd.abs).sign ) * xd.sign * reduce_factor
        ywf = ( 0.4 - 0.2 * (xd.abs - yd.abs).sign ) * yd.sign * reduce_factor

        #TODO: create a stub object, which silently takes & forgets the weight
        #      to avoid so much 'unless'-es
        @valids[ West.index ].add_weight( 1.0 + xwf ) unless @valids[ West.index ].nil?
        @valids[ East.index ].add_weight( 1.0 - xwf ) unless @valids[ East.index ].nil?
        @valids[ North.index ].add_weight( 1.0 + ywf ) unless @valids[ North.index ].nil?
        @valids[ South.index ].add_weight( 1.0 - ywf ) unless @valids[ South.index ].nil?
    end

    def try_to_keep_hugging
        
    end

    def analyze_limited_space( map, valids )
        sws = SpaceWidthSearch.new( map )
        valids.each do |m|
            sws.add_starting_move( m )
        end
        spaces = sws.execute
        think "Spaces available:\n    #{spaces.join("\n    ")}"
        return spaces
    end

    def my_valid_moves( map )
		return ValidMovesArray.new( North.new( map ), East.new( map ), South.new( map ), West.new( map ) )
    end

    def rival_valid_moves
        rp = @map.rival_point
		return ValidMovesArray.new( North.new( @map, rp ), East.new( @map, rp ), South.new( @map, rp ), West.new( @map, rp ) )
    end

    def check_rival_presence( space_info )
        rvalids = rival_valid_moves
        @rival_presence = ! ((rvalids.map { |rm| rm.dst }) & space_info.contents).empty?
    end

    def try_to_keep_direction

        previous = @history.last
        unless previous.nil? || ! @valids.include?( previous )
            last_and_valid = @history.last( 5 ).select { |m| @valids.include? m }
            #think "Trying to keep last from: #{last_and_valid}, while prev was: #{previous}"
            last_and_valid.uniq!

            if last_and_valid.size == 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight 1.2
            elsif last_and_valid.size > 1 && last_and_valid[0] == previous
                @valids[ previous ].add_weight 1.15
            elsif last_and_valid.include? previous
                @valids[ previous ].add_weight 1.1
            end
        end

        think "Long direction advice is: #{@valids}"
    end

	def initialize

        @history = Array.new
        @rival_presence = true
        @map = nil
        @valids = nil
        @primary_strategy = nil
	
		while(true)
		
            timed 'Map parsed in' do
                @map = Map.read_new( @history )
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

