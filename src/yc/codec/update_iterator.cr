module Yc
  module Codec
    class UpdateIterator
      include Iterator(Tuple(Node, UInt64))

      getter update : Update
      getter sv : StateVector

      private getter stack : Array(Node)

      def initialize(@update : Update, @sv : StateVector)
        @client_ids = update.structs.keys.sort
        @current_client_id = @client_ids.pop
        @stack = [] of Node
      end

      def next
        while current = next_candidate
          id = current.id

          if current.is_a?(SkipNode)
            current = next_candidate
          elsif !sv.contains(id)
            stack << current
            # self.update_missing_state(id.client, id.clock - 1);
            # self.add_stack_to_rest();
          else
            # if dep = get_missing_dep(current)
            #   stack << current

            #   if updates = update.structs[dep]?
            #     @current = updates.shift
            #     next
            #   else
            #     # update_missing_state(dep, state.get(dep))
            #     # add_stack_to_rest
            #   end
            # else
            #   local_state = state[id.client]
            #   offset = local_state - id.clock
            #   if offset == 0 || offset < current.length
            #     state.set_max(id.client, id.clock + current.length)
            #     return {current, offset}
            #   end
            # end
          end
        end

        stop
      end

      private def next_candidate
        if !stack.empty?
          stack.pop
        elsif client = next_client
          update.structs[client].shift
        end
      end

      private def next_client
        while client = @current_client_id
          if (structs = update.structs[client]?) && !structs.empty?
            @current_client_id = client
            return @current_client_id
          else
            update.structs.delete(client)
            @current_client_id = @client_ids.pop
          end
        end
      end
    end
  end
end