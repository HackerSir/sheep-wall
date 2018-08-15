module SheepWall
  class Parser

    module Helper
      def field name
        @fields << name
      end
      def fields
        @fields ||= []
      end
    end

    def self.inherited klass
      klass.extend Helper
      klass.fields
    end

    def initialize queue
    end

    def fields
      self.class.fields
    end

    def parse elements
    end

  end
end
