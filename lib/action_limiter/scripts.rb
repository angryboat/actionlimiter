# frozen_string_literal: true

module ActionLimiter
  ##
  # @private
  SCRIPTS = Dir.glob("#{__dir__}/scripts/*.lua").each_with_object({}) do |script_path, object|
    script_name = File.basename(script_path, '.lua').to_sym

    object[script_name] = File.read(script_path).freeze
  end.freeze
end
