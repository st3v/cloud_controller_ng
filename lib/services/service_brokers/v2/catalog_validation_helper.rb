require 'json'
require 'json_schema'

module VCAP::Services::ServiceBrokers::V2
  module CatalogValidationHelper
    def validate_string!(name, input, opts={})
      if !input.is_a?(String) && !input.nil?
        errors.add("#{human_readable_attr_name(name)} must be a string, but has value #{input.inspect}")
        return
      end

      if opts[:required] && (input.nil? || input.empty? || is_blank_str?(input))
        errors.add("#{human_readable_attr_name(name)} is required")
      end
    end

    def validate_hash!(name, input)
      errors.add("#{human_readable_attr_name(name)} must be a hash, but has value #{input.inspect}") unless input.is_a? Hash
    end

    def validate_bool!(name, input, opts={})
      if !is_a_bool?(input) && !input.nil?
        errors.add("#{human_readable_attr_name(name)} must be a boolean, but has value #{input.inspect}")
        return
      end

      if opts[:required] && input.nil?
        errors.add("#{human_readable_attr_name(name)} is required")
      end
    end

    def validate_array_of_strings!(name, input)
      unless is_an_array_of(String, input)
        errors.add("#{human_readable_attr_name(name)} must be an array of strings, but has value #{input.inspect}")
      end
    end

    def validate_tags!(name, input)
      if !validate_array_of_strings!(name, input) && !input.empty?
        tags_length = input.join.length
        unless tags_length <= 2048
          errors.add("Tags for the service #{@name} must be 2048 characters or less.")
        end
      end
    end

    def validate_array_of_hashes!(name, input)
      unless is_an_array_of(Hash, input)
        errors.add("#{human_readable_attr_name(name)} must be an array of hashes, but has value #{input.inspect}")
      end
    end

    def validate_dependently_in_order(validations)
      validations.each do |validation|
        errors_count = errors.messages.count
        send(validation)
        break if errors_count != errors.messages.count
      end
    end

    def validate_schema!(name, json_schema, json_meta_schema)
      return unless json_schema #schema is optional

      begin
        schema_data = JSON.parse(json_schema)
        schema = JsonSchema.parse!(schema_data)
        schema.expand_references!

        meta_schema_data = JSON.parse(json_meta_schema)
        meta_schema = JsonSchema.parse!(meta_schema_data)
        meta_schema.expand_references!

        meta_schema.validate!(schema_data)
      rescue StandardError => e
        errors.add("#{human_readable_attr_name(name)} must be a valid broker parameter schema, #{e.message}")
      end
    end

    def is_an_array_of(klass, input)
      input.is_a?(Array) && input.all? { |i| i.is_a?(klass) }
    end

    def is_a_bool?(value)
      [true, false].include?(value)
    end

    def is_blank_str?(value)
      value !~ /[^[:space:]]/
    end
  end
end
