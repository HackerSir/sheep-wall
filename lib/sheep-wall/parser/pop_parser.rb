require "sheep-wall/parser"

module SheepWall
  class Parser
    class POPParser < Parser

      filter 'pop.request && ( pop.request.command ~ "USER" || pop.request.command ~ "PASS" )'

      field "pop.request.command"
      field "pop.request.parameter"

    def initialize queue
      super(queue)
      @cache = {}
    end

    def parse flds
      if flds["pop.request.command"] == "PASS" and @cache.key? flds["tcp.stream"]
        @queue << { type: "POP", host: "#{flds["ip.dst_host"]}:#{flds["tcp.dstport"]}",
                    client: "#{flds["ip.src_host"]}",
                    cred: "#{@cache[flds["tcp.stream"]]}:#{flds["pop.request.parameter"]}" }
      elsif flds["pop.request.command"] == "USER"
        @cache[flds["tcp.stream"]] = flds["pop.request.parameter"]
      end
    end

    end
  end
end
