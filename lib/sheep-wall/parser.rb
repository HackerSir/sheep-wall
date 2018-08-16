module SheepWall
  class Parser

    module Helper
      def field name
        @fields << name
      end
      def fields
        @fields ||= []
      end
      def filter f = nil
        @filter = f if f
        @filter
      end
    end

    def self.inherited klass
      klass.extend Helper
      klass.fields
    end

    def initialize queue
      @queue = queue
    end

    def filter
      self.class.filter
    end

    def fields
      self.class.fields
    end

    def parse elements
    end

  end
end

%w{ftp_parser  http_parser  imap_parser  smtp_parser pop_parser}.each do |f|
  require "sheep-wall/parser/" + f
end
