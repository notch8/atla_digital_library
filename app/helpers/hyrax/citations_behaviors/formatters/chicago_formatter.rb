# NOTE(dewey4iv @ 06/18/20): Hyrax Override: fotmats aren't quite what Atla wants.
# Changed to match: https://gitlab.com/notch8/atla_digital_library/-/issues/285#note_363126537

# frozen_string_literal: true
module Hyrax
  module CitationsBehaviors
    module Formatters
      class ChicagoFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior
        def format(work)
          text = ""

          # setup formatted author list
          authors_list = all_authors(work)
          text += format_authors(authors_list)
          text = "<span class=\"citation-author\">#{text}</span>" if text.present?

          text += format_title(work.to_s)
          pub_info = setup_pub_info(work, false)
          text += " #{whitewash(pub_info)}." if pub_info.present?

          # NOTE(dewey4iv): moved date down to match Atla request
          pub_date = setup_pub_date(work)
          text += " #{whitewash(pub_date)}." unless pub_date.nil?

          # NOTE(dewey4iv): Hyrax Override: adds addtl content for citation
          text += add_retrieved_from
          text += add_link_to_original(work)
          # end

          text.html_safe
        end

        def format_authors(authors_list = [])
          return '' if authors_list.blank?
          text = ''
          text += surname_first(authors_list.first) if authors_list.first
          authors_list[1..6].each_with_index do |author, index|
            text += if index + 2 == authors_list.length # we've skipped the first author
                      ", and #{given_name_first(author)}."
                    else
                      ", #{given_name_first(author)}"
                    end
          end
          text += " et al." if authors_list.length > 7
          # if for some reason the first author ended with a comma
          text = text.gsub(',,', ',')
          text += "." unless text.end_with?(".")
          whitewash(text)
        end

        def format_date(pub_date); end

        def format_title(title_info)
          return "" if title_info.blank?
          title_text = chicago_citation_title(title_info)
          title_text += '.' unless title_text.end_with?(".")
          title_text = whitewash(title_text)
          " <i class=\"citation-title\">#{title_text}</i>"
        end

        private

        def whitewash(text)
          Loofah.fragment(text.to_s).scrub!(:whitewash).to_s
        end
      end
    end
  end
end
