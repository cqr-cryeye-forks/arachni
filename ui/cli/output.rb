=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module UI

# CLI Output module.
#
# Provides a command line output interface to the framework.
# All UIs should provide an `Arachni::UI::Output` module with these methods.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Output

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def personalize_output
            @personalize_output = true
        end

        def personalize_output?
            @personalize_output
        end
    end

    def self.reset_output_options
        @@debug   = 0
        @@verbose = false
        @@mute    = false

        @@only_positives  = false
        @@reroute_to_file = false

        @@opened = false

        @@error_logfile = 'error.log'
    end

    reset_output_options

    # @param    [String]    logfile
    #   Location of the error log file.
    def set_error_logfile( logfile )
        @@error_logfile = logfile
    end

    # @return  [String]
    #   Location of the error log file.
    def error_logfile
        @@error_logfile
    end

    # Prints and logs an error message.
    #
    # @param    [String]    str
    def print_error( str = '' )
        print_color( '[-]', 31, str, $stderr )
        log_error( str )
    end

    # Prints the backtrace of an exception as error messages.
    #
    # @param    [Exception] e
    def print_error_backtrace( e )
        e.backtrace.each { |line| print_error( line ) }
    end

    def print_exception( e )
        print_error "[#{e.class}] #{e}"
        print_error_backtrace( e )
    end

    # Logs an error message to the error log file.
    #
    # @param    [String]    str
    def log_error( str = '' )
        File.open( @@error_logfile, 'a' ) do |f|
            if !@@opened
                f.puts
                f.puts "#{Time.now} " + ( "-" * 80 )

                begin
                    h = {}
                    ENV.each { |k, v| h[k] = v }
                    f.puts 'ENV:'
                    f.puts h.to_yaml

                    f.puts "-" * 80

                    f.puts 'OPTIONS:'
                    f.puts Arachni::Options.instance.to_yaml
                rescue
                end

                f.puts "-" * 80
            end
            print_color( "[#{Time.now}]", 31, str, f, true )
        end

        @@opened = true
    end

    # Used to draw attention to a bad situation which isn't an error.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute
    def print_bad( str = '', unmute = false )
        return if muted? && !unmute
        print_color( '[-]', 31, str, $stdout, unmute )
    end

    # Prints a status message.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    def print_status( str = '', unmute = false )
        return if only_positives?
        print_color( '[*]', 34, str, $stdout, unmute )
    end

    # Prints an info message.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute
    def print_info( str = '', unmute = false )
        return if only_positives?
        print_color( '[~]', 30, str, $stdout, unmute )
    end

    # Prints a good message, something that went very very right, like the
    # discovery of an issue.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute
    def print_ok( str = '', unmute = false )
        print_color( '[+]', 32, str, $stdout, unmute )
    end

    # Prints a debugging message.
    #
    # @param    [String]    str
    #
    # @see #debug?
    def print_debug( str = '', level = 1 )
        return if !debug?( level )
        print_color( '[!]', 36, str, $stderr )
    end

    def print_debug_level_1( str = '' )
        print_debug( str, 1 )
    end

    def print_debug_level_2( str = '' )
        print_debug( str, 2 )
    end

    def print_debug_level_3( str = '' )
        print_debug( str, 3 )
    end

    # Prints the backtrace of an exception as debugging messages.
    #
    # @param    [Exception] e
    #
    # @see #debug?
    # @see #debug
    def print_debug_backtrace( e )
        return if !debug?
        e.backtrace.each{ |line| print_debug( line ) }
    end

    # Prints a verbose message.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute
    #
    # @see #verbose?
    # @see #verbose!
    def print_verbose( str = '', unmute = false )
        return if !verbose?
        print_color( '[v]', 37, str, $stdout, unmute )
    end

    # Prints an unclassified message.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute
    def print_line( str = '', unmute = false )
        return if only_positives?
        return if muted? && !unmute

        # We may get IO errors...freaky stuff...
        begin
            puts str
        rescue
        end
    end

    # Enables {#print_verbose} messages.
    #
    # @see #verbose?
    def verbose_on
        @@verbose = true
    end
    alias :verbose :verbose_on

    # Disables {#print_verbose} messages.
    #
    # @see #verbose?
    def verbose_off
        @@verbose = false
    end

    # @return    [Bool]
    def verbose?
        @@verbose
    end

    # Enables {#print_debug} messages.
    #
    # @param    [Integer]   level
    #   Sets the debugging level.
    #
    # @see #debug?
    def debug_on( level = 1 )
        @@debug = level
    end
    alias :debug :debug_on

    # Disables {#print_debug} messages.
    #
    # @see #debug?
    def debug_off
        @@debug = 0
    end

    # @return   [Integer]
    #   Debugging level.
    def debug_level
        @@debug
    end

    # @param    [Integer]   level
    #   Checks against this level.
    #
    # @return   [Bool]
    #
    # @see #debug
    def debug?( level = 1 )
        @@debug >= level
    end

    def debug_level_1?
        debug? 1
    end
    def debug_level_2?
        debug? 2
    end
    def debug_level_3?
        debug? 3
    end

    # Mutes everything but {#print_ok} messages.
    def only_positives
        @@only_positives = true
    end

    # Undoes {#only_positives}.
    def disable_only_positives
        @@only_positives = false
    end

    # @return    [Bool]
    def only_positives?
        @@only_positives
    end

    # Mutes all output messages, unless they explicitly override the mute status.
    def mute
        @@mute = true
    end

    # Unmutes output messages.
    def unmute
        @@mute = false
    end

    # @return   [Bool]
    def muted?
        @@mute
    end

    private

    def intercept_print_message( message )
        return message if !self.class.respond_to?( :personalize_output? )

        self.class.personalize_output? ?
            "#{self.class.name.split('::').last}: #{message}" : message
    end

    # Prints a message prefixed with a colored sign.
    #
    # @param    [String]    sign
    # @param    [Integer]   color     shell color number
    # @param    [String]    string    the string to output
    # @param    [IO]        out        output stream
    # @param    [Bool]      unmute    override mute
    def print_color( sign, color, string, out = $stdout, unmute = false )
        return if muted? && !unmute

        str = intercept_print_message( string )
        str = add_resource_usage_statistics( str ) if Arachni.profile?

        # We may get IO errors...freaky stuff...
        begin
            if out.tty?
                out.print "\033[1;#{color.to_s}m #{sign}\033[1;00m #{str}\n"
            else
                out.print "#{sign} #{str}\n"
            end
        rescue
        end
    end

    def print_with_statistics( message = nil )
        print_info add_resource_usage_statistics( message )
    end

    def add_resource_usage_statistics( message )
        require 'sys/proctable'

        procinfo = ::Sys::ProcTable.ps( Process.pid )
        pctcpu   = procinfo[:pctcpu]
        pctmem   = procinfo[:pctmem]
        rss      = procinfo[:rss]
        @rss   ||= rss

        # Change in RAM consumption in MB | Total RAM consumption in MB (RAM %) |
        # CPU usage % | Amount of Typhoeus::Request - Typhoeus::Response objects in RAM |
        # Proc objects in RAM
        sprintf( '%7.4f | %8.4f (%5.1f%%) | %5.1f%% | %3i - %3i | %3i - %3i | %5i | ',
                rss_to_mb(rss - @rss), rss_to_mb(rss), pctmem, pctcpu,
                ::ObjectSpace.each_object( Arachni::HTTP::Request ){},
                ::ObjectSpace.each_object( Arachni::HTTP::Response ){},
                ::ObjectSpace.each_object( ::Typhoeus::Request ){},
                ::ObjectSpace.each_object( ::Typhoeus::Response ){},
                ::ObjectSpace.each_object( ::Proc ){}) + message.to_s
    ensure
        @rss = rss
    end

    def rss_to_mb( rss )
        rss * 4096.0 / 1024.0 / 1024.0
    end

    extend self

end

end
end
