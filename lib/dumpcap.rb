
# wrap dumpcap command
#
# @param interface [String]
# @param filter [String] Capture filter
# @param output [String] output filename or specify '-' for stdout
# @param block [Proc] yields io when passed '-' as output
# @return [IO|Boolean] pass pipe when called with output as '-' but with no block, else would pass command call result
def dumpcap interface: "lo", filter: nil, output: "-", options: [], &block
  dumpcap_cmd = %w{ dumpcap -n -q -w } + [output]

  dumpcap_cmd += ["-i", interface]
  dumpcap_cmd += ["-f", filter] if filter

  dumpcap_cmd += options

  if output == '-'
    return IO.popen dumpcap_cmd, &block
  else
    return system dumpcap_cmd
  end

end

