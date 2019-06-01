require 'fastlane/action'
require_relative '../helper/kuhverij_helper'

module Fastlane
  module Actions
    class KuhverijAction < Action
      @excluded_target_extensions = ['xctest']

      def self.run(params)
        derived_data_path = params[:derived_data_path]
        coverage_report_path = Dir["#{derived_data_path}/**/*.xccovreport"].first
        UI.user_error!("No '.xccovreport' could be found at #{derived_data_path}") if coverage_report_path.nil?

        commands = []
        command = "xcrun xccov view --only-targets --json"
        command << " #{coverage_report_path.shellescape}"
        commands << command

        code_coverage_json = Fastlane::Actions.sh(command, log: false)

        code_coverage = code_coverage_message(code_coverage_json)
        UI.message(code_coverage)

        commands
      end

      def self.code_coverage_message(json_string)
        code_coverage = JSON.parse(json_string)
        covered_lines = 0
        executable_lines = 0

        code_coverage.each do |target|
          next if should_skip_target(target["name"])

          covered_lines += target["coveredLines"].to_f
          executable_lines += target["executableLines"].to_f
        end

        percentage = covered_lines / (executable_lines.nonzero? || 1) * 100
        message = format("Code Coverage: %.2f%%", percentage)

        message
      end

      def self.should_skip_target(name)
        return true if name.nil?

        extension = name.split(".").last

        @excluded_target_extensions.include?(extension)
      end

      def self.description
        "Simplified Code Coverage"
      end

      def self.authors
        ["mbogh"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Simplified Code Coverage, which e.g. can be used together with GitLab"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                  env_name: "KUHVERIJ_DERIVED_DATA_PATH",
                               description: "Path to derived data",
                             default_value: Actions.lane_context[Actions::SharedValues::SCAN_DERIVED_DATA_PATH],
                                  optional: false,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.category
        :testing
      end
    end
  end
end
