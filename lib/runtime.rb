require_relative 'steps'
require_relative 'test_case_translator'
require_relative 'requirement_translator'
require_relative 'test_cases'
require_relative 'requirements'

module Norm

  RED    = "\033[0;31m"
  YELLOW = "\033[0;33m"
  GREEN  = "\033[0;32m"
  NORMAL = "\033[m"

  class Runtime
    attr_reader :directives_path,
                :utilities_path,
                :test_cases_path,
                :requirements_path,
                :output_path

    def initialize(directives_path)
      @directives_path = directives_path

      @utilities_path    = File.join(directives_path, 'utilities')
      @test_cases_path   = File.join(directives_path, 'test_cases')
      @requirements_path = File.join(directives_path, 'requirements')
      @output_path       = File.join(directives_path, '..', 'output')

      ensure_output_dir
    end

    def load_requirements
      Dir.entries(output_path).each do |file_name|
        require_relative File.join(output_path, file_name) if file_name =~ /^.+\.requirements\.rb$/
      end
    end

    def load_test_cases
      Dir.entries(output_path).each do |file_name|
        require_relative File.join(output_path, file_name) if file_name =~ /^.+\.test_cases\.rb$/
      end
    end

    def load_utilities(path = utilities_path)
      Dir.entries(path).each do |entry_name|
        next if entry_name =~ /^\.\.?$/

        if entry_name =~ /^.+\.rb$/
          require_relative File.join(path, entry_name)
        elsif File.directory?(path)
          load_utilities(File.join(path, entry_name))
        end
      end
    end

    def process_requirements
      Dir.entries(requirements_path).each do |file_name|
        /\w+\.requirements$/.match(file_name) do |match|
          file     = File.open(File.join(requirements_path, match[0]), 'rb')
          contents = RequirementTranslator.translate(file.read)
          file.close

          file = File.new(File.join(output_path, match[0] + ".rb"), 'w')
          file.write(contents)
          file.close
        end
      end
    end

    def process_test_cases
      Dir.entries(test_cases_path).each do |file_name|
        /\w+\.test_cases$/.match(file_name) do |match|
          file     = File.open(File.join(test_cases_path, match[0]), 'rb')
          contents = TestCaseTranslator.translate(file.read)
          file.close

          file = File.new(File.join(output_path, match[0] + ".rb"), 'w')
          file.write(contents)
          file.close
        end
      end
    end

    def start
      load_utilities

      process_test_cases
      load_test_cases

      process_requirements
      load_requirements
    end

    private

    def ensure_output_dir
      Dir.mkdir(output_path) unless Dir.exists?(output_path)

      Dir.entries(output_path).each do |file_name|
        next if file_name =~ /^..?$/
        File.delete(File.join(output_path, file_name))
      end
    end
  end

end