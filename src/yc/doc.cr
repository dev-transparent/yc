require "uuid"
require "./store"
require "./publisher"
require "./type"

module Yc
  class Doc
    getter guid : UUID
    getter store : Store
    getter publisher : Publisher

    def initialize(@guid)
      @store = Store.new
      @publisher = Publisher.new(store)
    end

    # Generate an update from a client provided state with everything they are missing
    def update_from_state(state : Codec::StateVector)
      Codec::Update.new(
        store.updates_from_state(state), # Get everything that has been updated
        store.build_delete_set # Get everything that has been deleted
      )
    end

    def apply(update : Codec::Update)

    end
  end
end