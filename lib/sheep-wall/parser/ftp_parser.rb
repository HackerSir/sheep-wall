require "sheep-wall/parser"

module SheepWall
  class Parser
    class FTPParser < Parser

      filter 'ftp.request && ( ftp.request.command ~ "USER" || ftp.request.command ~ "PASS" )'

      field "ftp.request.command"
      field "ftp.request.arg"

    def initialize queue
      super(queue)
      @cache = {}
    end

    def parse flds
      if flds["ftp.request.command"] == "PASS" and @cache.key? flds["tcp.stream"]
        @queue << { type: "FTP", host: "#{flds["ip.dst_host"]}:#{flds["tcp.dstport"]}",
                    client: "#{flds["ip.src_host"]}",
                    cred: "#{@cache[flds["tcp.stream"]]}:#{flds["ftp.request.arg"]}" }
      elsif flds["ftp.request.command"] == "USER"
        @cache[flds["tcp.stream"]] = flds["ftp.request.arg"]
      end
    end

    end
  end
end
