module Bulkrax
  class OaiDcEntry < OaiEntry
    include Bulkrax::Concerns::HasMatchers

    def matcher_class
      Bulkrax::AtlaOaiMatcher
    end

    matcher 'contributor', split: true
    matcher 'creator', split: true
    matcher 'date', from: ['date'], split: true
    matcher 'description'
    matcher 'format_digital', from: ['format_digital', 'format'], parsed: true
    matcher 'identifier', from: ['identifier'], if: ->(parser, content) { content.match(/http(s{0,1}):\/\//) }
    matcher 'language', parsed: true, split: true
    matcher 'place', from: ['coverage']
    matcher 'publisher', split: /\s*[;]\s*/
    # NOTE (dewey4iv): Commented out per Rob. Being removed temporarily for ATLA's use
    # matcher 'relation', split: true
    matcher 'rights_statement', from: ['rights']
    matcher 'subject', split: true
    matcher 'title'
    matcher 'types', from: ['types', 'type'], split: true, parsed: true
    matcher 'remote_files', from: ['thumbnail_url'], parsed: true
  end
end
