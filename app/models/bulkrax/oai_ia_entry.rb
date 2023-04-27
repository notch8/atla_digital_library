module Bulkrax
  class OaiIaEntry < OaiDcEntry
    def build_metadata
      self.parsed_metadata = {}
      parsed_metadata[work_identifier] = [record.header.identifier]

      record.metadata.children.each do |child|
        child.children.each do |node|
          add_metadata(node.name, node.content)
        end
      end
      add_metadata('thumbnail_url', thumbnail_url)

      parsed_metadata['contributing_institution'] = [contributing_institution]
      parsed_metadata['remote_manifest_url'] ||= build_manifest

      add_visibility
      add_rights_statement
      add_collections

      # @todo remove this when field_mapping is in place
      parsed_metadata['contributor'] = nil

      parsed_metadata
    end

    # OVERRIDE: v4.4.2 Bulkrax::ImportBehavior#add_collections
    def add_collections
      return if self.find_collection_ids.blank?

      # we need this mapping to exist so that Bulkrax::ImportBehavior#build_for_importer calls #parent_jobs
      self.parsed_metadata[related_parents_parsed_mapping] = self.find_collection_ids
    end

    def build_manifest
      url = "https://iiif.archivelab.org/iiif/#{record.header.identifier.split(':').last}/manifest.json"
      return [url] if manifest_available?(url)
    end

    def manifest_available?(url)
      response = Faraday.get url
      if response.status == 200
        manifest_canvases?(response.body)
      else
        false
      end
    end

    # don't use if we don't have canvases
    def manifest_canvases?(manifest)
      JSON.parse(manifest)['sequences'].any? { |c| !c['canvases'].empty? }
    rescue
      false
    end
  end
end
