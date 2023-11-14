module ApplicationHelper
  def slug_or_id_of(collection_obj_or_doc)
    return unless collection_obj_or_doc.respond_to?(:slug)
    return collection_obj_or_doc.id unless collection_obj_or_doc.slug.present?

    if collection_obj_or_doc.slug.is_a?(Array) # solr_documents store slug as an Array
      collection_obj_or_doc.slug.first
    else
      collection_obj_or_doc.slug
    end
  end

  def yield_meta_tag(_tag, default_text)
    content_for?(:meta_description) ? content_for(:meta_description) : default_text
  end

  def has_iiif?
    @presenter.universal_viewer? || @presenter.remote_manifest_url.present?
  end

  def render_full_image_tag(document, image_options = {}, url_options = {})
    value = if blacklight_config.view_config(document_index_view_type).thumbnail_method
              send(blacklight_config.view_config(document_index_view_type).thumbnail_method, document, image_options)
            elsif blacklight_config.view_config(document_index_view_type).thumbnail_field
              url = thumbnail_url(document).gsub('?file=thumbnail', '')

              image_tag url, image_options if url.present?
            end

    if value
      if url_options == false || url_options[:suppress_link]
        value
      else
        link_to_document document, value, url_options
      end
    end
  end

  def featured_work_title(work_id)
    Work.find(work_id).title.first
  end

  # Taken from logo_record method in app/presenters/hyrax/collection_presenter.rb,
  # except available everywhere and with a few tweaks to alttext
  # return the info of a given collection's logo if it exists, else return nil
  def collection_logo_info(collection_id)
    logo_info = []
    # Find Logo filename, alttext, linktext
    cbi = CollectionBrandingInfo.where(collection_id: collection_id).where(role: 'logo')
    return if cbi.empty?
    cbi.each do |coll_info|
      logo_file = File.split(coll_info.local_path).last
      file_location = "/" + coll_info.local_path.split("/")[-4..-1].join("/") unless logo_file.empty?
      # fallback on file name for alt tag
      alttext = coll_info.alt_text.presence || logo_file
      linkurl = coll_info.target_url
      logo_info << { file: logo_file, file_location: file_location, alttext: alttext, linkurl: linkurl }
    end
    logo_info
  end

  def show_sidebar_size
    has_iiif? ? 'col-sm-5' : 'col-sm-3'
  end

  def show_main_size
    has_iiif? ? 'col-sm-7' : 'col-sm-9'
  end

  def truncate_text(options = {})
    options[:value][0].truncate(300)
  end
end
