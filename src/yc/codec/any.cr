require "big"

module Yc
  module Codec
    struct Undefined
    end

    struct Null
    end

    struct Any
      alias Type = Undefined | Null | Int32 | Float32 | Float64 | BigInt | Bool | String | Hash(String, Any) | Array(Any) | Bytes

      property value : Type

      def initialize(@value : Type)
      end

      def self.from_reader(reader : Reader)
        index = reader.read_byte.not_nil!
        value = case 127u8 &- index
        when 0
          Undefined.new
        when 1
          Null.new
        when 2
          raise "Unsupported type"
        when 3
          raise "Unsupported type"
        when 4
          raise "Unsupported type"
        when 5
          raise "Unsupported type"
        when 6
          false
        when 7
          true
        when 8
          reader.read_string.not_nil!
        when 9
          length = reader.read_u64.not_nil!
          # TODO:
          #
          raise "Unsupported type"
        when 10
          length = reader.read_u64.not_nil!
          values = Array(Any).new(length)

          length.times do
            values << from_reader(reader)
          end

          values
        when 11
          reader.read_bytes.not_nil!
        else
          Undefined.new
        end

        Any.new(value)
      end
    end
  end
end