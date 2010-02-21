class Point

    attr_reader :x, :y

    def initialize( map, x, y )
        @map = map
        @x = x
        @y = y
        @space = nil
    end

    def north
        Point.new( @map, @x, @y - 1 ) unless @y == 0
    end

    def south
        Point.new( @map, @x, @y + 1 ) unless @y == @map.height
    end

    def west
        Point.new( @map, @x - 1, @y ) unless @x == 0
    end

    def east
        Point.new( @map, @x + 1, @y ) unless @y == @map.width
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

    def inspect
        to_s
    end

    def to_s
        "<x=#{@x}; y=#{@y}>"
    end

end


