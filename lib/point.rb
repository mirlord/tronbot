
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
        @space = nil
    end

    def sibling( direction, withwalls = true )
        self.method( direction ).call( withwalls )
    end

    def siblings( withwalls = true )
        [ self.north( withwalls ), self.east( withwalls ), self.south( withwalls ), self.west( withwalls ) ]
    end

    def north( withwalls = true )
        think "Somebody wants go NORTH from #{self}"
        n = @map.p( @x, @y - 1, withwalls )
        think "He goes #{n}"
        return n
    end

    def south( withwalls = true )
        @map.p( @x, @y + 1, withwalls )
    end

    def west( withwalls = true )
        think "Somebody wants go WEST from #{self}"
        n = @map.p( @x - 1, @y, withwalls )
        think "He goes #{n}"
        return n
    end

    def east( withwalls = true )
        @map.p( @x + 1, @y, withwalls )
    end

    def space( direction_name )
        @space = @map.calculate_space( self ) if @space.nil?

        case direction_name
            when :north
                @space[1] + @space[2] + @space[3]
            when :east
                @space[3] + @space[5] + @space[8]
            when :south
                @space[6] + @space[7] + @space[8]
            when :west
                @space[1] + @space[4] + @space[6]
            else
                0
        end
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

    def ==( comp )
        self.eql?( comp )
    end

end


