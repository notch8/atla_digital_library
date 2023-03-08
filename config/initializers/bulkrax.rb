Bulkrax.setup do |config|
  config.parsers += [
    { name: 'OAI - Princeton Theological Commons', class_name: 'Bulkrax::OaiPtcParser', partial: 'oai_ptc_fields' },
    { name: 'OAI - Internet Archive', class_name: 'Bulkrax::OaiIaParser', partial: 'oai_ia_fields' },
    { name: 'OAI - Manual Sets', class_name: 'Bulkrax::OaiSetsParser', partial: 'oai_sets_fields' },
    { name: 'OAI - Omeka', class_name: 'Bulkrax::OaiOmekaParser', partial: 'oai_omeka_fields' },
    { name: 'CDRI Xml File', class_name: 'Bulkrax::CdriParser', partial: 'cdri_fields' }
  ]

  config.default_work_type = 'Work'

  # Field to use during import to identify if the Work or Collection already exists.
  # Default is 'source'.
  # config.system_identifier_field = 'identifier'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  config.field_mappings = {
    # custom base oai mappings
    "Bulkrax::OaiDcParser" => {
      "contributor" => { from: ["contributor"], split: /\s*[;]\s*/ },
      "place"=>{:from=>["coverage"], split: /\s*[;]\s*/},
      "creator" => { from: ["creator"], split: /\s*[;]\s*/ },
      "date" => { from: ["date"], split: /\s*[;]\s*/ },
      "description" => { from: ["description"] },
      "format_digital" => { from: ["format"], parsed: true, split: /\s*[;]\s*/ },
      "identifier" => { from: ["identifier"], if: ['match?', /http(s{0,1}):\/\//], source_identifier: true },
      "language" => { from: ["language"], split: /\s*[;]\s*/, parsed: true },
      "publisher" => { from: ["publisher"], split: /\s*[;]\s*/ },
      "related_url" => { from: ["relation"], excluded: true },
      "rights_statement" => { from: ["rights"], split: /\s*[;]\s*/ },
      "contributing_institution" => { from: ["source"] },
      "subject" => { from: ["subject"], split: /\s*[;]\s*/, parsed: true},
      "title" => { from: ["title"] },
      "types" => { from: ["type"], split: /\s*[;]\s*/, parsed: true },
      "remote_files" => { from: ['thumbnail_url'], parsed: true }
    },
    "Bulkrax::CdriParser" => {
      "contributing_institution" => {from: ['publisher'] },
      "creator" => { from: ["creator"], split: /\s*[;]\s*/ },
      "date" => { from: ['date', 'pub_date'], split: /\s*[;]\s*/ },
      "language" => { from: ["language"], parsed: true, split: /\s*,\s*/ },
      "subject" => { from: ["subject"], parsed: true, split: /\s*[;]\s*/ }
    },
    "Bulkrax::OaiIaParser" => {},
    "Bulkrax::OaiSetsParser" => {},
    "Bulkrax::OaiOmekaParser" => {},
    "Bulkrax::OaiPtcParser" => {},
    "Bulkrax::CsvParser" => {},
    "Bulkrax::OaiQualifiedDcParser" => {}
  }

  # omeka - uses the same mappings as oai_dc
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # sets parser - uses the same mappings as oai_dc
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiSetsParser"][key] = value }

  # csv - custom mappings
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::CsvParser"][key] = value }
  config.field_mappings["Bulkrax::CsvParser"]["abstract"] = { from: ["abstract"], excluded: true }
  config.field_mappings["Bulkrax::CsvParser"]["alternative_title"] = { from: ["alternative_title"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["contributing_institution"] = { from: ["contributing_institution"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["extent"] = { from: ["extent"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["format_digital"] = { from: ["format", "format_digital"], parsed: true, split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["format_original"] = { from: ["format_original"], split: /\s*[;]\s*/, parsed: true }
  config.field_mappings["Bulkrax::CsvParser"]["has_manifest"] = { from: ["has_manifest"] }
  config.field_mappings["Bulkrax::CsvParser"]["place"] = { from: ["place"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["remote_files"] = { from: ["thumbnail_url", "remote_files"], parsed: true }
  config.field_mappings["Bulkrax::CsvParser"]["remote_manifest_url"] = { from: ["remote_manifest_url"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["rights_holder"] = { from: ["rights_holder"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["rights_statement"] = { from: ["rights", "rights_statement"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["time_period"] = { from: ["time_period"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::CsvParser"]["types"] = { from: ["type", "types", "resource_type"], split: /\s*[;]\s*/, parsed: true }

  # internet archive - custom mappings - exclude contributor, add date parser
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiIaParser"][key] = value }
  config.field_mappings["Bulkrax::OaiIaParser"]["contributor"] = { from: ["contributor"], excluded: true}
  config.field_mappings["Bulkrax::OaiIaParser"]["date"] = { from: ["date"], parsed: true, split: /\s*[;]\s*/}
  config.field_mappings["Bulkrax::OaiIaParser"]["format_digital"] = { from: ["format"], excluded: true }

  # ptc - custom mappings - switch format_digital for format_original
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiPtcParser"][key] = value }
  config.field_mappings["Bulkrax::OaiPtcParser"]["format_original"] = { from: ["format"], parsed: true, split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiPtcParser"].delete("format_digital")

  # custom mappings for qdc
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiQualifiedDcParser"][key] = value }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["abstract"] = { from: ["abstract"], excluded: true }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["alternative_title"] = { from: ["alternative"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["date"] = { from: ["date_created", "date"], split: /\s*[;]\s*/}
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["format_original"] = { from: ['medium'], parsed: true, split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["remote_manifest_url"] = { from: ["hasFormat"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["time_period"] = { from: ["temporal"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["extent"] = { from: ["extent"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["place"] = { from: ["coverage", "spatial"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["remote_files"] = { from: ["thumbnail_url", "hasVersion", "dcterms:hasVersion"], parsed: true }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["rights_holder"] = { from: ["rightsHolder"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["transcript_url"] = { from: ["transcript"] }
end

# Verify that scheduled jobs get created when needed
begin
i = Bulkrax::Importer.where('frequency <> ?', 'PT0S')
i.each do |importer|
  if importer.schedulable? && Delayed::Job.find_by('handler LIKE ? AND handler LIKE ?', "job_class: Bulkrax::ImporterJob", importer.to_gid.to_s)
    Bulkrax::ImporterJob.set(wait_until: importer.next_import_at).perform_later(importer.id, true)
  end
end
rescue => e
  puts "Bulkrax Importers not scheduled #{e.message}"
end
