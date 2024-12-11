module Yc
  module Codec
    record Id,
      client : UInt64,
      clock : UInt64 do
        def self.from_reader(reader : Reader)
          client = reader.read_u64.not_nil!
          clock = reader.read_u64.not_nil!

          new(client, clock)
        end
      end
  end
end