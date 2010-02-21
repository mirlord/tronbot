
require 'lib/utils'

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


