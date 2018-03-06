require 'nanoid'

module BloodContracts
  module Storages
    class FileBackend < BaseBackend
      option :root, default: -> { Rails.root.join(path) }

      def suggestion
        "#{path}/*/*"
      end

      def unexpected_suggestion
        "#{path}/#{Storage::UNDEFINED_RULE}/*"
      end

      def default_path
        "./tmp/contract_tests/"
      end

      def timestamp
        @timestamp ||= Time.current.to_s(:usec)[8..-3]
      end

      def reset_timestamp!
        @timestamp = nil
      end

      def parse_run_pattern(run_pattern)
        path_items = run_pattern.split("/")
        sample = path_items.pop
        tag = path_items.pop
        path_str = path_items.join("/")
        run_n_example_str = path_str.sub(default_path, '')
        if run_n_example_str.end_with?('*')
          [
            run_n_example_str.chomp("*"),
            tag,
            sample
          ]
        elsif run_n_example_str.end_with?(example_name)
          [
            run_n_example_str.chomp(example_name),
            tag,
            sample
          ]
        else
          %w(__no_match__ __no_match__ __no_match__)
        end
      end

      def find_all_samples(run_pattern)
        run, tag, sample = parse_run_pattern(run_pattern)
        run_path = path(run_name: run)
        files = Dir.glob("#{run_path}/#{tag.to_s}/#{sample}*")
        files.select { |f| f.end_with?(".output") }
             .map { |f| f.chomp(".output") }
      end

      def path(run_name: name)
        File.join(default_path, run_name, example_name.to_s)
      end

      def sample_name(tag, run_path: root, sample: timestamp)
        File.join(run_path, tag.to_s, sample)
      end

      def sample_exists?(run_pattern)
        run, tag, sample = parse_run_pattern(run_pattern)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        File.exist?("#{name}.input")
      end

      def read_sample(run_pattern, dump_type)
        run, tag, sample = parse_run_pattern(run_pattern)
        name = sample_name(tag, run_path: path(run_name: run), sample: sample)
        File.read("#{name}.#{dump_type}.dump")
      end

      def write(writer, cntxt, options)
        writer = cntxt.method(writer) if cntxt && writer.respond_to?(:to_sym)
        writer.call(options).encode(
          "UTF-8", invalid: :replace, undef: :replace, replace: "?",
        )
      end

      def save_sample(tag, options, context)
        FileUtils.mkdir_p File.join(root, tag.to_s)

        reset_timestamp!
        name = sample_name(tag)
        File.open("#{name}.input", "w+") do |f|
          f << write(input_writer, context, options)
        end
        File.open("#{name}.output", "w+") do |f|
          f << write(output_writer, context, options)
        end
      end

      def serialize_input(tag, options, context)
        return unless (dump_proc = input_serializer[:dump])
        name = sample_name(tag)
        File.open("#{name}.input.dump", "w+") do |f|
          f << write(dump_proc, context, options)
        end
      end

      def serialize_output(tag, options, context)
        return unless (dump_proc = output_serializer[:dump])
        name = sample_name(tag)
        File.open("#{name}.output.dump", "w+") do |f|
          f << write(dump_proc, context, options)
        end
      end

      def serialize_meta(tag, options, context)
        return unless (dump_proc = meta_serializer[:dump])
        name = sample_name(tag)
        File.open("#{name}.meta.dump", "w+") do |f|
          f << write(dump_proc, context, options)
        end
      end
    end
  end
end
