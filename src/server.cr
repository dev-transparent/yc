require "kemal"
require "./yc"

# https://github.com/toeverything/OctoBase/blob/master/libs/jwst-core/src/workspaces/sync.rs#L14

get "/" do
  "hello"
end

# TODO: Encapsulate all this state...
connections = {} of HTTP::WebSocket => Set(UInt64)
doc = Yc::Doc.new(UUID.v4)

ws "/:room" do |socket, env|
  connections[socket] ||= Set(UInt64).new

  socket.on_message do |message|
    puts "got message"
  end

  socket.on_binary do |binary|
    reader = Yc::Reader.new(binary)

    case type = reader.read_u64.not_nil!
    when 0
      message = Yc::Protocol::DocMessage.from_reader(reader)

      case message.type
      when .step1?
        puts "step 1"
        state_vector = Yc::Codec::StateVector.from_reader(Yc::Reader.new(message.bytes))

        update = doc.update_from_state(state_vector)
        update_buffer = Yc::Buffer.new
        update.to_buffer(update_buffer)

        reply = Yc::Protocol::DocMessage.new(
          type: Yc::Protocol::DocMessage::Type::Step2,
          bytes: update_buffer.to_slice
        )

        reply_buffer = Yc::Buffer.new
        reply.to_buffer(reply_buffer)

        socket.send reply_buffer.to_slice
      when .step2?
        update = Yc::Codec::Update.from_reader(Yc::Reader.new(message.bytes))

        puts "step 2"
        pp update

        doc.apply(update)
      when .update?
        update = Yc::Codec::Update.from_reader(Yc::Reader.new(message.bytes))
        puts "update"
        pp update

        before_state = doc.store.build_state_vector
        doc.apply(update)


        # let before_state = doc.get_state_vector();
        # doc.apply_update_from_binary_v1(update)
        #     .and_then(|_| {
        #         // TODO: encode without pending update
        #         let update = doc.encode_state_as_update(&before_state)?;
        #         if update.is_content_empty() {
        #             return Ok(None);
        #         }

        #         let mut encoder = RawEncoder::default();
        #         update.write(&mut encoder)?;
        #         let update = encoder.into_inner();
        #         debug!("step3 return changed update: {}", update.len());
        #         Ok(Some(update))
        #     })
        #     .map_err(|e| warn!("failed to apply update: {:?}", e))
        #     .ok()
        #     .flatten()
        #     .map(|u| SyncMessage::Doc(DocMessage::Update(u)))
      end
    when 1
      pp Yc::Protocol::Awareness.from_reader(reader)
    else
      raise "unsupported... #{type}"
    end
  end

  socket.on_close do
    puts "closed"
  end

  # Send over initial document as sync step 1
  # message = Yc::Protocol::DocMessage.new(
  #   Yc::Protocol::DocMessage::Type::STEP1,
  #   #doc.to_slice
  # )
  #
  # buffer = Yc::Buffer.new(IO::Memory.new)
  # message.to_buffer(Yc::Buffer.new(IO::Memory.new))
  # send(buffer.io.to_slice)

  # doc.awareness.states.each do |state|
  #   buffer = Yc::Buffer.new(IO::Memory.new)
  #   # buffer.
  # end
end

Kemal.run(port: 9080)