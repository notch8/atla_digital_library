require 'language_list'
require 'erb'
require 'ostruct'

module OAI::DC
  class RecordParser << OAI::Base::RecordParser
    def metadata
      return @metadata if @metadata

      @metadata = record.metadata&.child&.children&.each_with_object({}) do |node, hash|
        case node.name
        when 'language'
          hash['language'] ||= []
          language = parse_language node.content
          hash['language'] << language
        when 'title'
          hash['title'] ||= []
          title = parse_title node.content
          title.each {|t| hash['title'] << t}
        when 'format'
          hash['format_original'] ||= []
          hash['format_original'] << node.content
        when 'coverage'
          hash['place'] ||= []
          hash['place'] << node.content
        when 'relation'
          if @all
            hash['collection'] ||= []
            hash['collection'] << node.content
          end
        when 'type'
          hash['types'] ||= []
          hash['types'] << node.content
        when 'rights'
          next
        else
          hash[node.name] ||= []
          hash[node.name] << node.content
        end
      end

      if @metadata
        @metadata['contributing_institution'] = [institution]
        @metadata['rights'] = [rights]
      end

      @metadata
    end
  end
end
