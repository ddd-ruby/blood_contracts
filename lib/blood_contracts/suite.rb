module BloodContracts
  class Suite
    extend Dry::Initializer

    option :data_generator, optional: true
    option :contract, ->(v) { Hashie::Mash.new(v) }, default: -> { Hash.new }

    option :input_writer,  optional: true
    option :output_writer, optional: true

    option :input_serializer,  ->(v) { parse_serializer(v) }, optional: true
    option :output_serializer, ->(v) { parse_serializer(v) }, optional: true

    option :storage_backend, optional: true
    option :storage, default: -> { default_storage }

    def data_generator=(generator)
      raise ArgumentError unless generator.respond_to?(:call)
      @data_generator = generator
    end

    def contract=(contract)
      raise ArgumentError unless contract.respond_to?(:to_h)
      @contract = Hashie::Mash.new(contract.to_h)
    end

    def input_writer=(writer)
      storage.input_writer = writer
    end

    def output_writer=(writer)
      storage.output_writer = writer
    end

    def default_storage
      Storage.new(
        input_writer: input_writer,
        output_writer: output_writer,
        input_serializer: input_serializer,
        output_serializer: output_serializer,
      )
    end
  end
end
