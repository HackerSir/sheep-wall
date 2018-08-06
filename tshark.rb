require "pry"

@restart = true

Signal.trap 'CHLD' do
  @restart = true
end

# dumpcap -n -q -i lo -f tcp -w - | tshark -r - -Y 'http' -Tfields -E seperator="$(echo)" -e 'http.authbasic' -e 'http.request.uri.query'
def tshark interface: nil, filter: nil, disp_filter: nil, format: "fields", fields: [], options: [], &block
  dumpcap = %w{ dumpcap -n -q -w - }
  tshark = %w{ tshark -l -r - }

  dumpcap += ["-i", interface] if interface
  dumpcap += ["-f", filter] if filter
  tshark += ["-Y", disp_filter] if disp_filter

  tshark += ["-T", format]

  fields.each do |field|
    tshark += [ "-e", field ]
  end

  tshark += options

  @copy_thread = nil

  loop do
    break unless @restart
    @restart = false
    IO.popen dumpcap do |dumpio|
      IO.popen tshark, "r+" do |sharkio|
        @copy_thread.kill if @copy_thread and @copy_thread.alive?

        @copy_thread = Thread.new do
          loop do
            IO.copy_stream dumpio, sharkio
            break if dumpio.closed? or sharkio.closed?
          end
        end

        yield sharkio
      end
    end
  end

end

FIELDS = %w{ ip.src_host tcp.dstport http.host http.request.uri http.request.uri.query http.authbasic http.content_type http.file_data }

tshark interface: ARGV[0] || "lo", filter: "tcp", disp_filter: "http && http.request", fields: FIELDS do |io|
  io.sync = true
  @quit = false

  Signal.trap 'INT' do
    @quit = true
  end

  loop do
    ra, _ = IO.select [io], nil, nil, 1
    if @quit || $?
      STDERR.puts "Terminating tshark..."    
      Process.kill 'TERM', io.pid
      Process.wait
      io.close
      exit
    elsif ra && ra.size > 0
      line = io.gets
      p Hash[FIELDS.zip(line.chomp.split "\t")] if line
    end
  end
end

