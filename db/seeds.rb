ActiveFedora.fedora.connection.send(:init_base_path)

puts "\n== Creating default collection types"
Hyrax::CollectionType.find_or_create_default_collection_type
Hyrax::CollectionType.find_or_create_admin_set_type

puts "\n== Loading workflows"
Hyrax::Workflow::WorkflowImporter.load_workflows
errors = Hyrax::Workflow::WorkflowImporter.load_errors
abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

puts "\n== Creating default admin set"
admin_set_id = AdminSet.find_or_create_default_admin_set_id

# I have found that when I come back to a development
# environment, that I may have an AdminSet in Fedora, but it is
# not indexed in Solr.  This remediates that situation by
# ensuring we have an indexed AdminSet
puts "\n== Ensuring the found or created admin set is indexed"
AdminSet.find(admin_set_id).update_index

if Rails.env.development?
  User.where(email: 'rob@notch8.com').first_or_create do |f|
    f.password = 'testing123'
    f.admin_area = true
  end

  User.where(email: 'archivist1@example.com').first_or_create do |f|
    f.password = 'Ka55ttp72'
  end

  User.where(email: 'acarter@atla.com').first_or_create do |f|
    f.password = 'Ka55ttp72'
    f.admin_area = true
  end

  User.where(email: 'ckarpinski@atla.com').first_or_create do |f|
    f.password = 'Ka55ttp72'
    f.admin_area = true
  end

  User.where(email: 'jbutler@atla.com').first_or_create do |f|
    f.password = 'Ka55ttp72'
    f.admin_area = true
  end

  Bulkrax::Importer.find_or_create_by(name: 'Trinity International University - Evangelical Beacon') do |importer|
    importer.admin_set_id = "admin_set/default",
    importer.user_id = 1,
    importer.frequency = "PT0S",
    importer.parser_klass = "Bulkrax::OaiDcParser",
    importer.limit = 10,
    importer.parser_fields = {
      "base_url"=>"http://collections.carli.illinois.edu/oai/oai.php",
      "metadata_prefix"=>"oai_dc",
      "set"=>"tiu_beacon",
      "institution_name"=>"Trinity International University Rolfing Library",
      "rights_statement"=>"http://rightsstatements.org/vocab/UND/1.0/",
      "override_rights_statement"=>"1",
      "thumbnail_url"=>"http://collections.carli.illinois.edu/utils/getthumbnail/collection/tiu_beacon/id/<%= identifier.split('/').last %>"
      },
    importer.field_mapping = nil
  end

  Bulkrax::Importer.find_or_create_by(name: 'AMBS - Biblioteca Digital Anabautista') do |importer|
    importer.admin_set_id = "admin_set/default",
    importer.user_id = 1,
    importer.frequency = "PT0S",
    importer.limit = 50,
    importer.parser_klass = "Bulkrax::OaiIaParser",
    importer.parser_fields = {
      "base_url"=>"https://archive.org/services/oai.php",
      "metadata_prefix"=>"oai_dc",
      "set"=>"collection:bibliotecadigitalanabautista",
      "collection_title"=>"AMBS -  Biblioteca Digital Anabautista",
      "institution_name"=>"Anabaptist Mennonite Biblical Seminary",
      "rights_statement"=>"http://rightsstatements.org/vocab/UND/1.0/",
      "override_rights_statement"=>"1",
      "thumbnail_url"=>"https://archive.org/services/img/<%= identifier.split(':').last %>"
    },
    importer.field_mapping = nil
  end

  # Uncomment if you want the importers to kick off at startup.
  # begin
  #   Bulkrax::Importer.each do |i|
  #     i.import_collections
  #     i.import_works
  #   end
  # end

  #   Harvester.create!(
  #     name: "Princeton Theological Commons - Benson",
  #     admin_set_id: "admin_set/default",
  #     user_id: 1,
  #     base_url: "http://commons.ptsem.edu/api/oai-pmh",
  #     external_set_id: "collection:Benson",
  #     institution_name: "Princeton Theological Seminary",
  #     frequency: "PT0S",
  #     limit: 50,
  #     importer_name: "OAI::PTC::Importer",
  #     right_statement: "http://rightsstatements.org/vocab/CNE/1.0/",
  #     thumbnail_url: "http://commons.ptsem.edu/?cover=<%= identifier.split('/').last %>",
  #     metadata_prefix: 'oai_dc'
  #   )
end
