require "open3"
require "thread"

module SheepWall
  class Capture
    DEFAULT_DUMP  = "/usr/bin/dumpcap"
    DEFAULT_SHARK = "/usr/bin/tshark"
    COMMON_FIELDS = %w{ tcp.stream ip.src_host ip.dst_host tcp.dstport }

    attr_accessor :interface, :capture_filter, :display_filter, :options, :input
    attr_reader :parsers, :fields, :queue, :display

    def initialize interface = "lo", capture_filter = "tcp"
      @interface = interface
      @capture_filter = capture_filter
      @display_filter = []
      @options = []
      @parsers = []
      @fields = []
      @input = input
      @queue = Queue.new
    end

    def add_parser parser
      parser = parser.new @queue
      @parsers << parser
      parser.fields.each do |f|
        @fields<< [ f, parser]
      end
      @options += parser.options
      @display_filter << parser.filter if parser.filter
      parser
    end

    def add_display disp
      @display = disp.new
    end

    def quit?
      @quit
    end

    def start
      Thread.new do
        loop { @display.show @queue.pop }
      end
      Open3.pipeline_r(*build_command) do |out, _|
        loop do
          begin
            flds = out.readline.chomp.split("\t")
            common = COMMON_FIELDS.zip flds.shift(COMMON_FIELDS.size)

            # FIXME: flds length may sometimes mismatch with fields, need further inspectation
            grp = flds.zip(fields).reject { |pair| pair.first.nil? or pair.first.empty? }.group_by { |pair| pair.flatten.last }
            grp.map do |k,bulk| # parser => [ field, [ name, parser ] ]
              next if k.nil?
              k.parse Hash[common + bulk.map { |v| v.flatten[0..1].reverse }]
            end
          
          rescue EOFError, Interrupt
            _.map(&:kill)
            @quit = true
            break
          end
        end
      end
    end

    # dumpcap -n -q -i lo -f tcp -w - | tshark -r - -Y 'http' -Tfields -E seperator="$(echo)" -e 'http.authbasic' -e 'http.request.uri.query'
    def build_command
      _dump_cmd = [DEFAULT_DUMP] + %w{ -n -q -w - } + [ "-i", @interface, "-f", @capture_filter ]
      _shark_cmd = [DEFAULT_SHARK] + %w{ -r - -l }

      @options.each do |opt|
        _shark_cmd += [ "-o", opt ]
      end

      _shark_cmd += [ "-Y", @display_filter.map { |df| "( " + df + " )" }.join(" || ") ] unless @display_filter.empty?
      _shark_cmd += %w{ -Tfields }
      COMMON_FIELDS.each do |k|
        _shark_cmd += [ "-e", k ]
      end
      @fields.each do |k,_|
        _shark_cmd += [ "-e", k ]
      end
      [_dump_cmd, _shark_cmd]
    end
  end
end
