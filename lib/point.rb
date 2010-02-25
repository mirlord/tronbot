
require 'lib/utils'

class Point

    include TronUtils

    attr_reader :x, :y

    # Don't use it directly!!!
    # Use Map::p( x, y ) or Point::sibling( direction ) or Point::(north|east|west|south)
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
        #return true if super( comp )
        self.x == comp.x && self.y == comp.y
    end

    def <=>( comp )
        return 0 if self == comp
    end

    def equal?
        self.eql?( comp )
    end

    def ==( comp )
        #return true if super( comp )
        self.eql?( comp )
    end

end


