
require 'lib/utils'

class ValidMovesArray

    include TronUtils

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

    def intersects?( valids )
        each do |m|
            return m if valids.include?( m )
        end
        return false
    end

    #def opposite?
        #( size == 2) && ( ( @moves[0].nil? && @moves[2].nil? ) || ( @moves[1].nil? && @moves[3].nil? )  )
    #end
    
    def size
        @moves.size - @moves.nils_count
        #self.compact.size
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

    def choose
        #choose_top
        choose_optimal
    end

    def choose_optimal
        think "Choosing optimal from: #{self}"

        sorted = @moves.sort

        think "Collected weights: #{pretty_print_a( sorted )}"
        sorted.last
    end

    def []( index )
        #TODO: stub for nils
        @moves[ index ]
    end

end

class Move
    
    include TronUtils
    include Comparable

    BASE_WEIGHT = 1.0

    attr_reader :src, :dst, :weights

    # Parameters:
    # @map [Map]
    # @source [Point]
    # @destination [Point]
    def initialize( map, source, destination_method_name = nil )
        @map = map
        @src = ( source.nil? ) ? map.my_point : source
        dst_method = ( destination_method_name.nil? ) ? @src.method( dname ) : @src.method( destination_method_name )
        @dst = dst_method.call
        @weights = Array.new
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
    end

    def weight
        res = BASE_WEIGHT
        @weights.each do |w|
            res = res * w
        end
        return res
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


