##############################################################################
# Utils

def debug?
    ARGV.include?( '--debug' )
end

class Array

    # Returns the number of nil elements in self. May be zero.
    def nils_count
        self.select { |e| e.nil? }.size
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


