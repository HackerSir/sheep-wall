require "sheep-wall/parser"
require "base64"
require "json"
require "uri"

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
            u,pw = Base64.decode64(v).split(":")
            _res[:cred] = "#{u}:#{mask pw}"
          else
            _res[:cred] = mask v
          end
          @queue << _res
        end

        if flds['http.cookie_pair'] and flds['http.cookie_pair'].size > 0
          pairs = flds['http.cookie_pair'].split(',')
                    .map { |pair| pair.split("=", 2) }
                    .select { |k,_| ( k =~ /session/i or k =~ /([u_]|\b)u((ser_?)?)?id/i or k =~ /(_|\b)s(ess(ion_?)?)?id/i ) and k != "__cfduid" }
          if pairs.size > 0
            _res = res.dup
            _res[:cred] = pairs.map { |pair| "#{URI.unescape pair.first}=#{mask URI.unescape pair.last}" }.join(";")
            @queue << _res
          end
        end

        if flds['http.request.uri.query'] and flds['http.request.uri.query'].size > 0
          args = flds['http.request.uri.query'].split("&").map { |pair| pair.split("=",2) }
          params = args.select { |pair| pair[0] =~ /user(name)?/i or pair[0] =~ /txtID/i or pair[0] =~ /txtPW/i or pair[0] =~ /pass(word)?/i }
          tok,_ = args.select { |pair| pair[0] =~ /auth.+token/i }
          if params.size > 0
            _res = res.dup
            _res[:cred] = params.map { |pair| "#{URI.unescape pair.first}=#{mask URI.unescape pair.last}"}.join("&")
            @queue << _res
          elsif tok
            _res = res.dup
            _res[:cred] = "token-" + mask(tok.last)
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
          params = args.select { |pair| pair[0] =~ /user(name)?/i or pair[0] =~ /ID\b/i or pair[0] =~ /PW\b/i or pair[0] =~ /pass(word)?/i }
          tok,_ = args.select { |pair| pair[0] =~ /auth.+token/i }
          if params.size > 0
            _res = res.dup
            _res[:cred] = params.map { |pair| "#{URI.unescape pair.first}=#{mask URI.unescape pair.last}" }.join("&")
            @queue << _res
          elsif tok
            _res = res.dup
            _res[:cred] = "#{URI.unescape tok.first}=#{mask URI.unescape tok.last}"
            @queue << _res
          end
        end

      end

      def mask str
        return "(none)" if str.size == 0
        l = str.size / 3
        chr = str.size > 21 ? "." : "*"
        trl = l > 7 ? 7 : l
        str[l/2,l*2+1] = chr*trl*2 + chr
        str
      end

    end
  end
end
