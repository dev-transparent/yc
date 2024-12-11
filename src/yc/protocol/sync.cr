module Yc
  module Protocol
    enum MessageType
      Auth
      Awareness
      AwarenessQuery
      Doc

      def self.from_reader(reader : Reader)
        MessageType.from_value(reader.read_u64.not_nil!)
      end

      def to_buffer(buffer : Buffer)
        buffer.write_i64(value.to_u64)
      end
    end

    abstract struct SyncMessage
      def self.from_reader(reader : Reader)
        type = MessageType.from_reader(reader)

        case type
        when MessageType::Auth
          Auth.from_reader(reader)
        when MessageType::Awareness
          Awareness.from_reader(reader)
        when MessageType::AwarenessQuery
          AwarenessQuery.new
        when MessageType::Doc
          puts "got a doc"
          Doc.from_reader(reader)
        end
      end

      abstract def to_buffer(buffer : Buffer)
    end

    struct Auth < SyncMessage
      enum Permission
        Denied
        Granted
      end

      getter reason : String?

      def initialize(@reason : String? = nil)
      end

      def self.from_reader(reader : Reader)
        new
      end

      def to_buffer(buffer : Buffer)
        MessageType::Auth.to_buffer(buffer)

        if reason
          buffer.write_byte(Permission::Denied)
          buffer.write_string(reason.not_nil!)
        else
          buffer.write_byte(Permission::Granted)
        end
      end
    end

    struct Awareness < SyncMessage
      getter states : Hash(UInt64, AwarenessState)

      def initialize(@states : Hash(UInt64, AwarenessState))
      end

      def self.from_reader(reader : Reader)
        reader = reader.new_from_length.not_nil!
        length = reader.read_u64.not_nil!

        states = length.times.reduce({} of UInt64 => AwarenessState) do |hash|
          client_id = reader.read_u64.not_nil!
          awareness = AwarenessState.from_reader(reader)

          hash[client_id] = awareness
          hash
        end

        new(states)
      end

      def to_buffer(buffer : Buffer)
        MessageType::Awareness.to_buffer(buffer)

        states_buffer = Buffer.new
        states_buffer.write_u64(states.size)

        states.each do |client_id, state|
          states_buffer.write_u64(client_id)
          state.to_buffer(states_buffer)
        end

        buffer.write_buffer(states_buffer)
      end
    end

    struct AwarenessState
      def initialize(@clock : UInt64, @content : String)
      end

      def self.from_reader(reader : Reader)
        clock = reader.read_u64.not_nil!
        content = reader.read_string.not_nil!

        new(clock, content)
      end

      def to_buffer(buffer : Buffer)
        buffer.write_u64(clock)
        buffer.write_string(content)
      end
    end

    struct AwarenessQuery < SyncMessage
      def to_buffer(buffer : Buffer)
        # noop
      end
    end

    struct Doc < SyncMessage
      def initialize(@doc_message : DocMessage)
      end

      def self.from_reader(reader : Reader)
        new(doc_message: DocMessage.from_reader(reader))
      end

      def to_buffer(buffer : Buffer)
      end
    end
  end
end