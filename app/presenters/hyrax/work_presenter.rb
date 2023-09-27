# Generated via
#  `rails generate hyrax:work Work`
module Hyrax
  class WorkPresenter < Hyrax::WorkShowPresenter
    # Adds behaviors for hyrax-iiif_av plugin.
    include Hyrax::IiifAv::DisplaysIiifAv
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter

    delegate :title, :date_created, :description,
             :creator, :contributor, :subject, :date, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :license, :source, :rights_statement, :rights_holder, :thumbnail_id,
             :representative_id, :rendering_ids, :member_of_collection_ids, :contributing_institution, :place, :extent,
             :format_original, :format_digital, :time_period, :alternative_title, :types, :remote_manifest_url,
             :has_manifest, :ancestor_collection_ids, :ancestor_relationships, to: :solr_document

    # # Override the override so that it does not try to use the avalon player
    # def iiif_viewer
    #   :universal_viewer
    # end

    # ranges are not working at the moment, need to update to iiif-manifest 0.6+ first
    def ranges
      []
    end

    def iiif_viewer?
      has_manifest.present? &&
        has_manifest.first == "1" &&
        representative_id.present? &&
        representative_presenter.present? &&
        iiif_media? &&
        Hyrax.config.iiif_image_server? &&
        members_include_viewable?
    end
    alias universal_viewer? iiif_viewer?

    def iiif_media?
      representative_presenter.image? ||
        representative_presenter.video? ||
        representative_presenter.audio?
    end

    def audio?
      representative_presenter&.audio? || resource_type.include?('Sound') || types&.include?('Sound')
    end

    def video?
      representative_presenter&.video? || resource_type.include?('MovingImage') || types&.include?('Moving Image')
    end

    def members_include_viewable?
      file_set_presenters.any? do |presenter|
        (presenter.image? || presenter.video? || presenter.audio?) && current_ability.can?(:read, presenter.id)
      end
    end

    # OVERRIDE FILE from Hyrax v2.9.0
    # @return [Array] list to display with Kaminari pagination
    # paginating on members so we can filter out derived status
    Hyrax::WorkShowPresenter.class_eval do
      def list_of_item_ids_to_display
        paginated_item_list(page_array: members)
      end
    end

    def ancestor_collections
      Collection.where(id: ancestor_collection_ids)
    end

    # use this to select urls from identifier
    def url
      solr_document.identifier.select { |i| i.match('http') }
    end

    # OVERRIDE FILE from Hyrax v2.9.0
    # Gets the member id's for pagination, filter out derived files
    Hyrax::WorkShowPresenter.class_eval do
      def members
        members = member_presenters_for(authorized_item_ids)
        filtered_members =
          if current_ability.admin?
            members
          else
            members.reject { |m| m.solr_document['is_derived_ssi'] == 'true' }
          end
        filtered_members.collect(&:id)
      end
    end
  end
end
