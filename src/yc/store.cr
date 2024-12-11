module Yc
  class Store
    getter items : Hash(Codec::Client, Array(Codec::Node))
    getter pending : Codec::Update?
    getter delete_set : Codec::DeleteSet

    def initialize
      @items = {} of Codec::Client => Array(Codec::Node)
      @pending = nil
      @delete_set = Codec::DeleteSet.new
    end

    def clients : Array(Codec::Client)
      items.keys
    end

    def build_state_vector
      state = Codec::StateVector.new

      items.each do |client, structs|
        if last_struct = structs.last?
          state.map[client] ||= last_struct.clock + last_struct.length
        end
      end

      state
    end

    def diff_state_vector(sv : Codec::StateVector, with_pending : Bool)
      update_structs = diff_structs(sv)
      update = Codec::Update.new(structs: update_structs, delete_set: generate_delete_set)

      if with_pending
        # Do something with pending...
        if to_merge = pending
          puts "should be merging stuff..."
        end
      end

      update
    end

    def diff_structs(sv : Codec::StateVector)
      local_state_vector = build_state_vector
      diff = local_state_vector.diff(sv)

      update_structs = {} of Codec::Client => Array(Codec::Node)

      diff.each do |client, clock|
        if structs = items[client]?
          if items.empty?
            next
          end

          update_structs[client] = [] of Codec::Node

          clock = Math.max(structs.first.id.clock, clock)

          if index = node_index(structs, clock)
            first_block = structs[index]
            offset = first_block.clock - clock

            if offset != 0
              update_structs[client] << first_block.split_at(offset)[0]
            else
              update_structs[client] << first_block
            end

            structs.each.skip(index + 1).each do |item|
              update_structs[client] << item
            end
          end
        end
      end

      update_structs
    end

    def node_index(items : Array(Codec::Node), clock : Codec::Clock)
      left = 0
      right = items.size - 1
      middle = items[right]
      middle_clock = middle.clock

      if middle_clock == clock
        return right
      end

      middle_index = (clock / (middle_clock + middle.length - 1).to_i32 * right).to_i
      while left <= right
        middle = items[middle_index]
        middle_clock = middle.clock

        if middle_clock <= clock
          if clock < middle_clock + middle.length
            return middle_index
          end

          left = middle_index + 1
        else
          right = middle_index - 1
        end

        middle_index = ((left + right) / 2).to_i
      end

      nil
    end

    def generate_delete_set
      delete_set = Codec::DeleteSet.new

      items.each do |client, nodes|
        nodes.each do |node|
          delete_set.map[client] = Codec::Range.new(node.clock, node.length)
        end
      end

      delete_set
    end
  end
end