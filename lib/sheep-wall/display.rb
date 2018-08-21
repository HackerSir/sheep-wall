module SheepWall
  class Display

    def initialize
      @history = []
      @timestamps = []
    end

    def show entity
      return if @history.include? entity
      if ENV["DEBUG"]
        print "[debug] Accepted: "
        p entity
      end
      @history << entity
      @timestamps << [ entity, Time.now ]
      case entity
      when Hash
        puts "%s %s %s %s" % [ entity[:type], entity[:client], entity[:host], entity[:cred] ]
      else
        puts entity
      end
    end

  end
end

