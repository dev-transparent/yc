require "./history"

module Yc
  # TODO: Figure out type
  alias Subscriber = String

  class Publisher
    getter store : Store
    getter history : History
    getter subscribers : Array(Subscriber)

    getter observing : Atomic(Bool)

    @mutex : Mutex = Mutex.new

    def initialize(@store : Store)
      @history = History.new(store)
      @subscribers = Array(Subscriber).new
      @observing = Atomic(Bool).new(false)
    end

    def count
      @mutex.sync do
        @subscribers.size
      end
    end

    def subscribe(subscriber : Subscriber)
      @mutex.sync do
        @subscribers << subscriber
      end
    end

    def unsubscribe_all
      @mutex.sync do
        @subscribers.clear
      end
    end
  end
end