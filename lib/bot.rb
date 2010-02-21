
require 'lib/utils'
require 'lib/space'

class MirlordBot

    include TronUtils

    # @map [Map]
	def makemove( map )
	    
		valids = ValidMovesArray.new( North.new( map ), East.new( map ), South.new( map ), West.new( map ) )
        think "Possible valid moves: #{valids}"
		
		if valids.nsize == 0
			map.make_move( 0 )
		else
            collect_weights( map, valids ) unless valids.nsize < 2

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

    def analyze_limited_space( map, valids )
        sws = SpaceWidthSearch.new
        valids.each do |m|
            sws.add_starting_point( m.dst )
        end
        spaces = sws.execute
        think "Spaces merged into one" if spaces.size == 1
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
            w = s / (s + m.respace)
            valids[ m.index ].add_weight( w )
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

