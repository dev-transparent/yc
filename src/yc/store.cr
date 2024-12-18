require "./codec"

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

    def repair(item : Codec::Item)
      if left_id = item.origin_left_id
        if (left_node = split_at_and_get_left(left_id)) && left_node.is_a?(Codec::ItemNode)
          item.origin_left_id = left_node.item.last_id
          item.left = left_node.item
        else
          item.origin_left_id = nil
        end
      end

      if right_id = item.origin_right_id
        if (right_node = split_at_and_get_right(right_id)) && right_node.is_a?(Codec::ItemNode)
          item.origin_right_id = right_node.id
          item.right = right_node.item
        else
          item.origin_right_id = nil
        end
      end

      parent = item.parent
      case parent
      when String
        # TODO: Get or create a type...
      when Codec::Id
        # case node = get_node(parent)
        # when Codec::ItemNode
        #   case node.content
        #   when Codec::TypeContent
        #     # TODO: got to do something here
        #   end
        # else
        #   item.parent = nil
        # end
      when Nil
        if left = item.left
          item.parent = left.parent
          item.parent_sub = left.parent_sub
        elsif right = item.right
          item.parent = right.parent
          item.parent_sub = right.parent_sub
        end
      end

      case item.content
      when Codec::TypeContent
        # TODO: Got to do something with type and dangling type
      end
    end

    def split_at_and_get_right(id : Codec::Id)
      nodes = items[id.client]

      if index = node_index(nodes, id.clock)
        item = nodes[index]
        offset = id.clock - item.clock

        if offset > 0 && item.is_a?(Codec::ItemNode)
          split_node_at(nodes, index, offset)[1]
        else
          item
        end
      else
        raise "Couldn't split"
      end
    end

    def split_at_and_get_left(id : Codec::Id)
      nodes = items[id.client]

      if index = node_index(nodes, id.clock)
        item = nodes[index]
        offset = id.clock - item.clock

        if offset != item.length - 1 && !item.is_a?(Codec::GCNode)
          split_node_at(nodes, index, offset + 1)[0]
        else
          item
        end
      else
        raise "Couldn't split"
      end
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

    def node_index(items : Array(Codec::Node), clock : Codec::Clock) : Int32?
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

    def split_node_at(items : Array(Codec::Node), index : Int32, diff : UInt64) : Tuple(Codec::ItemNode, Codec::ItemNode)
      node = items[index]

      case node
      when Codec::ItemNode
        left_node, right_node = node.split_at(diff)
        left_item = left_node.item
        right_item = right_node.item

        left_item.left = if left_item.right
          left_item.right
        else
          node.item
        end

        right_item.right = left_item.right
        left_item.right = right_item
        right_item.origin_left_id = left_item.last_id
        right_item.origin_right_id = left_item.origin_right_id

        items[index + 1] = right_node

        {node, right_node}
      else
        raise "Unsupported split"
      end
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