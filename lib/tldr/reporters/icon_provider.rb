module IconProvider
  class Base
    def success
      "."
    end

    def failure
      "F"
    end

    def error
      "E"
    end

    def skip
      "S"
    end

    def tldr
      "!"
    end

    def run
      ""
    end

    def wip
      ""
    end

    def slow
      ""
    end

    def not_run
      ""
    end

    def alarm
      ""
    end

    def rock_on
      ""
    end
  end

  class Emoji < Base
    def success
      "😁"
    end

    def failure
      "😡"
    end

    def error
      "🤬"
    end

    def skip
      "🫥"
    end

    def tldr
      "🥵"
    end

    def run
      "🏃"
    end

    def wip
      "🙅"
    end

    def slow
      "🐢"
    end

    def not_run
      "🙈"
    end

    def alarm
      "🚨"
    end

    def rock_on
      "🤘"
    end
  end
end
