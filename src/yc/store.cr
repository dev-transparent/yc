require "./codec"

module Yc
  class Store
    getter blocks : Hash(Codec::Client, Array(Codec::Node))
    getter pending : Codec::Update?
    getter delete_set : Codec::DeleteSet

    def initialize
      @blocks = Hash(Codec::Client, Array(Codec::Node)).new do |hash, key|
        hash[key] = [] of Codec::Node
      end

      @pending = nil
      @delete_set = Codec::DeleteSet.new
    end

    def clients : Array(Codec::Client)
      blocks.keys
    end

    def build_state_vector : Codec::StateVector
      blocks.each_with_object(Codec::StateVector.new) do |(client, nodes), state|
        if last_node = nodes.last?
          state.map[client] ||= last_node.clock + last_node.length
        end
      end
    end

    def build_delete_set : Codec::DeleteSet
      blocks.each_with_object(Codec::DeleteSet.new) do |(client, nodes), delete_set|
        nodes.each do |node|
          if node.deleted?
            delete_set.map[client] = Codec::Range.new(node.clock, node.length)
          end
        end
      end
    end

    def updates_from_state(state : Codec::StateVector) : Hash(Codec::Client, Array(Codec::Node))
      local_state = build_state_vector

      diff = local_state.diff(state)
      diff.each_with_object({} of Codec::Clock => Array(Codec::Node)) do |(client, clock), updates|
        items = blocks[client]?

        if items && items.size > 0
          updates[client] = [] of Codec::Node
          clock = Math.max(items.first.id.clock, clock)

          if index = items.bsearch_index { |item| item.clock == clock }
            first_block = items[index]
            offset = first_block.clock - clock

            if offset != 0
              updates[client] << first_block.split_at(offset).first
            else
              updates[client] << first_block
            end

            items.each.skip(index + 1).each do |item|
              updates[client] << item
            end
          end
        end
      end
    end
  end
end