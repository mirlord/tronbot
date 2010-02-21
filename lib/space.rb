
class SpaceWidthSearch

    DEPTH_LIMIT_DEFAULT=10

    def initialize( map )
        @spaces = []
        @done = []
        @map = map
        @depth = DEPTH_LIMIT_DEFAULT
    end

    def add_starting_point( p )
        @spaces << SpaceInfo.new( p )
    end

    def execute
        @depth.times do
            merge_intersections
            return if @spaces.size < 2

            @spaces.reject! do |si|
                @done << si if si.closed?
            end

            @spaces.each do |si|
                si.pop_each do |p|
                    si.push( p.siblings( false ) )
                end
            end
        end
        @done += @spaces
        # unnecessary, so skipping for performance
        #@spaces.clear
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

    attr_reader :starting_points, :boundaries, :contents

    # @p [Point]
    def initialize( p )
        @starting_points = [ p ]
        @boundaries = [ p ]
        @contents = [ p ] # contents always include boundaries
    end

    def push( *points )
        # each point should be checked, so forced to use iterator
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
        return nil unless self.intersects_with?( si )

        @starting_points += si.starting_points
        @contents += si.contents
        @boundaries += si.boundaries
        @contents.uniq!
        @boundaries.uniq!
        return self
    end

    def intersects_with?( si )
        ! (boundaries & si.boundaries).empty? unless si.nil?
    end
    private :intersects_with?

    def pop_each
        @boundaries.each do |p|
            yield( p )
        end
        @boundaries.clear
    end

end

