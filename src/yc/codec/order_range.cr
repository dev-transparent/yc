module Yc
  module Codec
    abstract struct OrderRange
      abstract def to_buffer(buffer : Buffer)

      def self.from_reader(reader : Reader)
        number_of_deletes = reader.read_u64.not_nil!

        if number_of_deletes == 1
          Range.from_reader(reader)
        else
          Fragment.from_reader(reader, number_of_deletes)
        end
      end
    end

    struct Range < OrderRange
      property clock : UInt64
      property size : UInt64

      def initialize(@clock : UInt64, @size : UInt64)
      end

      def to_buffer(buffer : Buffer)
      end

      def self.from_reader(reader : Reader)
        clock = reader.read_u64.not_nil!
        length = reader.read_u64.not_nil!

        new(clock, length)
      end
    end

    struct Fragment < OrderRange
      property ranges : Array(Range)

      def initialize(@ranges : Array(Range))
      end

      def to_buffer(buffer : Buffer)
      end

      def self.from_reader(reader : Reader, number_of_deletes)
        ranges = [] of Range

        number_of_deletes.times do
          ranges << Range.from_reader(reader)
        end

        new(ranges)
      end
    end
  end
end