# frozen_string_literal: true
# OVERRIDE Bulkrax 4.4.2 Application Parser here to make sure atla custom parse methods get added
Bulkrax::ApplicationMatcher.class_eval do
  def process_parse
    # OVERRIDE here to make sure atla custom parse methods get added
    # New parse methods will need to be added here
    parsed_fields = ['remote_files',
                     'language', 'subject', 'types', 'model', 'resource_type',
                     'format_original', 'format_digital', 'date']
    # This accounts for prefixed matchers
    parser = parsed_fields.find { |field| to&.include? field }
    if @result.is_a?(Array) && self.parsed && self.respond_to?("parse_#{parser}")
      @result.each_with_index do |res, index|
        @result[index] = send("parse_#{parser}", res.strip)
      end
      @result.delete(nil)
    elsif self.parsed && self.respond_to?("parse_#{parser}")
      @result = send("parse_#{parser}", @result)
    end
  end
end
