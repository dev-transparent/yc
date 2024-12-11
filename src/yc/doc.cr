require "uuid"
require "./store"
require "./publisher"

module Yc
  class Doc
    getter guid : UUID

    private getter store : Store
    private getter publisher : Publisher

    def initialize(@guid)
      @store = Store.new
      @publisher = Publisher.new(store)
    end

    def encode_state_as_update_v1(sv : Codec::StateVector)
      store.diff_state_vector(sv, true)
    end
  end
end