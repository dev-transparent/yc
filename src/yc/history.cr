module Yc
  abstract class ParentNode
  end

  class Root < ParentNode
    def initialize(value : String)
    end
  end

  class Node < ParentNode
    def initialize(node : Node)
    end
  end

  class Unknown < ParentNode
  end

  class History
    private getter store : Store
    private getter parents : Hash(String, Node)

    @mutex : Mutex = Mutex.new

    def initialize(@store : Store)
      @parents = {} of String => Node
    end

    def resolve
      parents = @mutex.sync do
        @parents
      end

      store.items.values.each do |node|

      end
    end
  end
end