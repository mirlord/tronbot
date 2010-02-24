
require 'lib/utils'
require 'lib/space'

class MirlordBot

    include TronUtils

	def makemove
	    
        @valids = my_valid_moves
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

        analyze_limited_space
        
        if @rival_presence

            @primary_strategy = :headon

            me = @map.my_point
            rival = @map.rival_point
            xd = me.x - rival.x
            yd = me.y - rival.y
            xyd = ( xd.abs - yd.abs ).abs

            if xyd == 0
                #TODO: check if I have _2_ possible moves (not only one or even less)
                #TODO: imagine diagonal, calculate areas' space, choose direction
            elsif xyd > 1
                # *wf => x|y weight factor
                xwf = 0.4 + 0.2 * (xd.abs - yd.abs).sign
                ywf = 0.4 - 0.2 * (xd.abs - yd.abs).sign
                #TODO: create a stub object, which silently takes & forgets the weight
                #      to avoid so much 'unless'-es
                @valids[ West.index ].add_weight( 1.0 + xwf * xd.sign ) unless @valids[ West.index ].nil?
                @valids[ East.index ].add_weight( 1.0 - xwf * xd.sign ) unless @valids[ East.index ].nil?
                @valids[ North.index ].add_weight( 1.0 + ywf * yd.sign ) unless @valids[ North.index ].nil?
                @valids[ South.index ].add_weight( 1.0 - ywf * yd.sign ) unless @valids[ South.index ].nil?
            elsif xyd == 1
                #TODO: try to cut by the shortest coord, check spaces, make a decision if it's reasonable
            end

            #try_to_keep_direction
        else
            # TODO: hugging
            @primary_strategy = :hugger # yeah, it will be overwritten each time, I don't care
            try_to_keep_hugging
        end

    end

    def try_to_keep_hugging
        
    end

    def analyze_limited_space
        sws = SpaceWidthSearch.new( @map )
        @valids.each do |m|
            sws.add_starting_move( m )
        end
        spaces = sws.execute
        think "Spaces available:\n    #{spaces.join("\n    ")}"
        if spaces.size == 1 && @rival_presence
            check_rival_presence( spaces.first )
        end

        return if spaces.size == 1

        s_max = spaces.sort.last
        s_max.starting_moves.each do |m|
            @valids[ m.index ].add_weight( 2.0 )
        end
    end

    def my_valid_moves
		return ValidMovesArray.new( North.new( @map ), East.new( @map ), South.new( @map ), West.new( @map ) )
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
            last = @history.last( 5 ).select { |m| @valids.include? m }
            #think "Trying to keep last from: #{last}, while prev was: #{previous}"
            last.uniq!

            if last.length == 1 && last[0] == previous
                @valids[ previous ].add_weight 1.2
            elsif last.length > 1 && last[0] == previous
                @valids[ previous ].add_weight 1.15
            elsif last.include? previous
                @valids[ previous ].add_weight 1.1
            else
                @valids[ previous ].add_weight 1.05
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
                @map = Map.new( @history )
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

