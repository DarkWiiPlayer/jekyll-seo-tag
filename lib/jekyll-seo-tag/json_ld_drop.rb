# frozen_string_literal: true

module Jekyll
  class SeoTag
    class JSONLDDrop < Jekyll::Drops::Drop
      extend Forwardable

      def_delegator :page_drop, :name,           :name
      def_delegator :page_drop, :description,    :description
      def_delegator :page_drop, :canonical_url,  :url
      def_delegator :page_drop, :page_title,     :headline
      def_delegator :page_drop, :date_modified,  :dateModified
      def_delegator :page_drop, :date_published, :datePublished
      def_delegator :page_drop, :links,          :sameAs
      def_delegator :page_drop, :logo,           :logo
      def_delegator :page_drop, :type,           :type

      # Expose #type and #logo as private methods and #@type as a public method
      alias_method :"@type", :type
      private :type
      private :logo

      VALID_ENTITY_TYPES = %w(BlogPosting CreativeWork).freeze
      VALID_AUTHOR_TYPES = %w(Organization Person).freeze
      private_constant :VALID_ENTITY_TYPES
      private_constant :VALID_AUTHOR_TYPES

      # page_drop should be an instance of Jekyll::SeoTag::Drop
      def initialize(page_drop)
        @mutations = {}
        @page_drop = page_drop
      end

      def fallback_data
        @fallback_data ||= {
          "@context" => "https://schema.org",
        }
      end

      def author
        author_type = page_drop.author["type"]

        return unless page_drop.author["name"]
        return nil if author_type && !VALID_AUTHOR_TYPES.include?(author_type)

        {
          "@type" => author_type || "Person",
          "name"  => page_drop.author["name"],
        }
      end

      def image
        return unless page_drop.image
        return page_drop.image.path if page_drop.image.keys.length == 1

        hash = page_drop.image.to_h
        hash["url"]   = hash.delete("path")
        hash["@type"] = "imageObject"
        hash
      end

      def publisher
        return unless logo

        output = {
          "@type" => "Organization",
          "logo"  => {
            "@type" => "ImageObject",
            "url"   => logo,
          },
        }
        output["name"] = page_drop.author.name if page_drop.author.name
        output
      end

      def main_entity
        return unless VALID_ENTITY_TYPES.include?(type)

        {
          "@type" => "WebPage",
          "@id"   => page_drop.canonical_url,
        }
      end
      alias_method :mainEntityOfPage, :main_entity
      private :main_entity

      def to_json
        drop_hash = to_h
        if page_drop.custom_structured_data.is_a? Hash
          drop_hash = Utils.deep_merge_hashes(drop_hash, page_drop.custom_structured_data)
        end
        drop_hash.reject { |_k, v| v.nil? }.to_json
      end

      private

      attr_reader :page_drop
    end
  end
end
