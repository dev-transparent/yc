module Yc
  module Codec
    struct StateVector
      getter map : Hash(UInt64, Clock)

      def initialize(@map : Hash(UInt64, Clock) = {} of UInt64 => Clock)
      end

      def self.from_reader(reader : Reader)
        length = reader.read_u64.not_nil!

        map = {} of UInt64 => Clock

        length.times do
          client = reader.read_u64.not_nil!
          clock = reader.read_u64.not_nil!

          map[client] = clock.as(Clock)
        end

        new(map)
      end

      def diff(other : StateVector) : Array(Tuple(UInt64, Clock))
        diff = [] of Tuple(UInt64, Codec::Clock)

        other.map.each do |client, other_clock|
          local_clock = map[client]? || 0

          if local_clock > other_clock
            diff << {client, other_clock}
          end
        end

        map.each do |client, _|
          if other.map[client]? == 0
            diff << {client, 0u64}
          end
        end

        diff
      end

      def contains(id : Id)
        id.clock <= (map[id.client]? || 0u64)
      end
    end
  end
end