##############################################################################
# Utils

def debug?
    ARGV.include?( '--debug' )
end

class Fixnum

    # @return [true] if inside range, inclusively
    def inside_i?( from, to )
        # <= & >= more optimal, but less beautiful :)
        inside_e?( from, to ) || self == from || self == to
    end

    # @return [true] if inside range, exclusively
    def inside_e?( from, to )
        self > from && self < to
    end

    def outside?( from, to )
        ! inside_i?( from, to )
    end

    def sign
        self <=> 0
    end

end

class Float

    def sign
        self <=> 0.0
    end

end

class Array

    # Returns the number of nil elements in self. May be zero.
    def nils_count
        self.select { |e| e.nil? }.size
    end

    def only
        raise "This array contains more than one element" if size > 1
        return first if ! empty? # So in case of empty aray result is 'nil'
    end

end

class NilClass
    include Comparable 

    def <=>( move )
        return 0 if move.nil?
        return -1
    end

end

module TronUtils

    def think( *args )
        # do nothing in production
    end

    # redefine 'think' for debug mode
    def think( *args )
        $stderr.puts "BT> #{args.join("\n -> ")}\n"
    end if debug?

    # for timing
    def timed( msg, &block )
        from = Time.now
        yield
        to = Time.now
        $stderr.puts "> #{msg}: #{ (to - from) } sec"
    end

end


