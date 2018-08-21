require "sheep-wall/parser"
require "base64"
require "json"

module SheepWall
  class Parser
    class HTTPParser < Parser

      filter 'http.request'

      field 'http.host'
      field 'http.request.uri.query'
      field 'http.authorization'
      field 'http.content_type'
      field 'http.cookie_pair'
      field 'http.file_data'

      def parse flds
        res = {}
        res[:type] = "HTTP"
        res[:client] = flds["ip.src_host"]
        res[:host] = (flds["http.host"].nil? or flds["http.host"].empty?) ? "#{flds["ip.dst_host"]}:#{flds["tcp.dstport"]}" : flds["http.host"]
        if flds['http.authorization'] and flds['http.authorization'].size > 0
          _res = res.dup
          t,v = flds['http.authorization'].split
          case t
          when 'Basic'
            _res[:cred] = Base64.decode64 v
          else
            _res[:cred] = v
          end
          @queue << _res
        end

        if flds['http.request.uri.query'] and flds['http.request.uri.query'].size > 0
          args = flds['http.request.uri.query'].split("&").map { |pair| pair.split("=",2) }
          u,pw = args.select { |pair| pair[0] =~ /username/i or pair[0] =~ /pass(word)?/ }
          tok,_ = args.select { |pair| pair[0] =~ /auth.+token/i }
          if u and pw
            _res = res.dup
            _res[:cred] = "#{u.last}:#{pw.last}"
            @queue << _res
          elsif tok
            _res = res.dup
            _res[:cred] = "token-" + tok.last
            @queue << _res
          end
        end

        if flds['http.cookie_pair'] and flds['http.cookie_pair'].size > 0
          pairs = flds['http.cookie_pair'].split(',')
                    .map { |pair| pair.split("=", 2) }
                    .select { |k,_| ( k =~ /session/i or k =~ /id/i ) and k != "__cfduid" }
          if pairs.size > 0
            _res = res.dup
            _res[:cred] = pairs.map { |pair| pair.join "=" }.join(";")
            @queue << _res
          end
        end

        if flds['http.file_data'] and flds['http.file_data'].size > 0
          if flds['http.content_type'] == 'application/json'
            args = JSON.parse(flds['http.file_data']).each.to_a
          elsif flds['http.content_type'] == 'application/x-www-form-urlencoded'
            args = flds['http.file_data'].split("&").map { |pair| pair.split("=",2) }
          else
            return
          end
          u,pw = args.select { |pair| pair[0] =~ /username/i or pair[0] =~ /pass(word)?/ }
          tok,_ = args.select { |pair| pair[0] =~ /auth.+token/i }
          if u and pw
            _res = res.dup
            _res[:cred] = "#{u.last}:#{pw.last}"
            @queue << _res
          elsif tok
            _res = res.dup
            _res[:cred] = tok.join("=")
            @queue << _res
          end
        end

      end

    end
  end
end
