
require 'lib/utils'

class SpaceWidthSearch

    include TronUtils

    DEPTH_LIMIT_DEFAULT=100

    attr_reader :total_size

    def initialize( map )
        @spaces = []
        @done = []
        @map = map
        @depth = DEPTH_LIMIT_DEFAULT
        @total_size = 0
    end

    # @m [Move]
    def add_starting_move( m )
        @spaces << SpaceInfo.new( m )
    end

    def execute
        @depth.times do
            merge_intersections
            #think "Searching..."
            @spaces.reject! do |si|
                #think "Closed space found" if si.closed?
                # it's more optimcal to calculate total size here
                # to avoid +1 array bypass
                if si.closed?
                    @total_size += si.size
                    @done << si
                end
            end

            break if @spaces.size < 2

            @spaces.each do |si|
                si.pop_each do |p|
                    si.push( p.siblings( false ) )
                end
            end
        end
        @done += @spaces
        # unnecessary, so skipping for performance
        #@spaces.clear
        return @done
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

    include TronUtils

    attr_reader :starting_moves, :boundaries, :contents

    # @m [Move]
    def initialize( m )
        p = m.dst
        @starting_moves = [ m ]
        @boundaries = [ p ]
        @contents = [ p ] # contents always include boundaries
    end

    def push( points )
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
        return nil unless intersects_with?( si )

        @starting_moves += si.starting_moves
        @contents += si.contents
        @boundaries += si.boundaries
        @contents.uniq!
        @boundaries.uniq!
        return self
    end

    def intersects_with?( si )
        ! (contents & si.contents).empty? unless si.nil?
    end

    def pop_each
        @boundaries.each do |p|
            yield( p )
        end
        @boundaries.clear
    end
    
    def inspect
        to_s
    end

    def to_s
        "Space area ( size=#{self.size} ):: #{@starting_moves}"
    end

    def <=>( comp )
        size <=> comp.size
    end

end

