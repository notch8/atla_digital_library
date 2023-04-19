module Bulkrax
  class OaiOmekaEntry < OaiDcEntry
    # override to swap out the thumbnail_url
    def build_metadata
      self.parsed_metadata = {}
      parsed_metadata[work_identifier] ||= [record.header.identifier]

      record.metadata.children.each do |child|
        child.children.each do |node|
          add_metadata(node.name, node.content)
        end
      end

      identifiers = parsed_metadata['identifier']
      # remove all image urls
      if identifiers.present?
        parsed_metadata['identifier'] = identifiers.reject do |id|
          id =~ %r{http(s{0,1}):\/\/.+\.(jpg|png|gif|pdf|jp2|mp4|mp3|srt)}
        end
      end
      # use first image url as thumbnail in identifiers matching the given pattern
      if identifiers.present?
        parsed_metadata['remote_files'] = [identifiers.map do |id|
                                             { url: id } if %r{http(s{0,1}):\/\/.+\.(jpg|png|gif|jp2)}.match?(id)
                                           end .compact.first]
      end
      parsed_metadata['contributing_institution'] = [contributing_institution]

      add_visibility
      add_rights_statement
      add_collections

      parsed_metadata
    end
  end
end
