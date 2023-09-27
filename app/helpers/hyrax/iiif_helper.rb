module Hyrax
  module IiifHelper
    # @todo remove after upgrade to Hyrax 3.x

    def iiif_viewer_display(work_presenter, locals = {})
      render iiif_viewer_display_partial(work_presenter),
             locals.merge(presenter: work_presenter)
    end

    def base_url
      request&.base_url
    end

    def iiif_viewer_display_partial(work_presenter)
      'hyrax/base/iiif_viewers/' + work_presenter.iiif_viewer.to_s
    end

    def universal_viewer_base_url
      base_url = request&.base_url
      base_url = base_url.sub(/\Ahttp:/, 'https:') if request&.ssl?
      "#{base_url}/uv/uv.html"
    end

    def universal_viewer_config_url
      base_url = request&.base_url
      base_url = base_url.sub(/\Ahttp:/, 'https:') if request&.ssl?
      "#{base_url}/uv/uv-config.json"
    end
  end
end
