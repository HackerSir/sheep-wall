require "sheep-wall/parser"
require "base64"

module SheepWall
  class Parser
    class SMTPParser < Parser

      filter "smtp"

      field "smtp.auth.username_password"

      def parse flds
       @queue << { type: "SMTP", host: "#{flds["ip.dst_host"]}:#{flds["tcp.dstport"]}",
                    client: "#{flds["ip.src_host"]}",
                    cred: Base64.decode64(flds["smtp.auth.username_password"]).split("\0")[1..-1].join(":") }
      end
    end
  end
end

