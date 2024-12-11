module Yc
  module Protocol
    struct DocMessage
      enum Type
        Step1 = 0
        Step2 = 1
        Update = 2

        def to_buffer(buffer : Buffer)
          buffer.write_u64(value.to_u64)
        end
      end

      getter type : Type
      getter bytes : Bytes

      def initialize(@type : Type, @bytes : Bytes)
      end

      def self.from_reader(reader : Reader)
        type = Type.from_value(reader.read_u64.not_nil!)

        DocMessage.new(type, reader.read_bytes.not_nil!)
      end

      def to_buffer(buffer : Buffer)
        type.to_buffer(buffer)
        buffer.write_bytes(bytes)
      end
    end
  end
end