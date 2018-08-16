require "sheep-wall/parser"

module SheepWall
  class Parser
    class IMAPParser < Parser

      filter 'imap.request.command ~ "LOGIN"'

      field 'imap.request'

      def parse flds
             @queue << { type: "IMAP", host: "#{flds["ip.dst_host"]}:#{flds["tcp.dstport"]}",
                    client: "#{flds["ip.src_host"]}",
                    cred: flds["imap.request"].split[1..-1].join(":") }
      end

    end
  end
end
