require "uuid"
require "./store"
require "./publisher"

module Yc
  class Doc
    getter guid : UUID

    getter store : Store
    private getter publisher : Publisher

    def initialize(@guid)
      @store = Store.new
      @publisher = Publisher.new(store)
    end

    def encode_state_as_update_v1(sv : Codec::StateVector)
      store.diff_state_vector(sv, true)
    end

    def apply_update(update : Codec::Update)
      retry = false

      loop do
        iterator = Codec::UpdateIterator.new(update, store.build_state_vector)
        iterator.each do |(node, offset)|
            case node
            when Codec::ItemNode
              store.repair(node.item)
            end

            # store.integrate(node, offset)
        end

        # iterator = DeleteSetIterator.new(update.delete_set, sv)
        # iterator.each do |(client, range)|
        #   # store.delete_range(client, range)
        # end


      end
    end
  end
end