
@restart = true

Signal.trap 'CHLD' do
  @restart = true
end

# dumpcap -n -q -i lo -f tcp -w - | tshark -r - -Y 'http' -Tfields -E seperator="$(echo)" -e 'http.authbasic' -e 'http.request.uri.query'
def tshark interface: nil, capture_filter: nil, display_filter: nil, format: "fields", fields: [], options: [], &block
  dumpcap = %w{ dumpcap -n -q -w - }
  tshark = %w{ tshark -l -r - }

  tshark += options

  dumpcap += ["-i", interface] if interface
  dumpcap += ["-f", capture_filter] if capture_filter
  tshark += ["-Y", display_filter] if display_filter

  tshark += ["-T", format]

  fields.each do |field|
    tshark += [ "-e", field ]
  end

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

