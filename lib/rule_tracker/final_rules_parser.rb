# caution! this config file contains private API keys.
# ensure it remains in .gitignore regardless of file path
require_relative 'config'
require_relative 'Rule'
require_relative 'add_to_airtable'

def final_rules_parser(file)
  # The numbers of lines a file should read after keywords
  # before throwing an error and prompting manual review.
  error_buffer = 6

  lines = File.open(file).to_a
  file_name = File.basename(file, ".txt")
  puts "Parsing Final Rules in #{file_name} ..."

  lines.each_with_index do |line, idx|
    if line.include?("is amended.") || line.include?("is rescinded.")
      begin
        key_line = line
        jdx = idx

        until key_line.include?("CSR")
          jdx -= 1
          key_line = lines[jdx].gsub("\n", " ") + key_line

          # throws an error for edge cases, expected incidence <1%
          raise "!-- MANUAL REVIEW REQUIRED: Error Buffer Exceeded --!" if idx - jdx >= error_buffer
        end

        action = line.include?("amended") ? "Amend" : "Rescind"
        regexp = key_line.match(/^(s||D)*(?<CODE>\d+\s+CSR\s+[-.\d\s]+)\s*(?<DESCRIPTION>.*?)(?=\s+is #{action.downcase}ed.+$)/)
        raise "!-- MANUAL REVIEW REQUIRED: RegExp Returned nil --!" if regexp.nil?

        rule_citation, rule_description = regexp.captures

        add_to_airtable(Rule.new(rule_citation, rule_description, action, "Final Order", file_name))

      # rescue errors that require manual review
      # program continues running by default
      rescue => error
        puts error
        puts "An error has occured on line #{idx} in file #{file_name}."
        puts "Key line: #{key_line}"
        puts "Rule citation: #{rule_citation}"
        puts "Rule description: #{rule_description}"
        puts "Continuing ..."
        next
      end
    end
  end

  puts "Final rules uploaded to Airtable."
end
