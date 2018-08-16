module SheepWall
  class Display
    def initialize
    end

    def show entity
      case entity
      when Hash
        puts "%s %s %s %s" % [ entity[:type], entity[:client], entity[:host], entity[:cred] ]
      else
        puts entity
      end
    end

  end
end
