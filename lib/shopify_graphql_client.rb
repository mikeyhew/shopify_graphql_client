require "shopify_graphql_client/version"
require "graphql/client"
require "shopify_api"

module ShopifyGraphQLClient
  class Error < StandardError; end

  class << self
    delegate :parse, :query, to: :client

    def client
      @client ||= GraphQL::Client.new(schema: schema, execute: Executor.new)
    end

    private

    def schema
      @schema ||= load_schema
    end

    def load_schema
      unless File.exist?(schema_path)
        raise Error, "The schema file does not exist at #{schema_path}"
      end

      GraphQL::Client.load_schema(schema_path)
    end

    def schema_path
      File.join(__dir__, "../schema.json")
    end
  end

  class Executor < GraphQL::Client::HTTP
    # avoid initializing @uri
    def initialize; end

    def headers(_context)
      ShopifyAPI::Base.headers
    end

    def uri
      ShopifyAPI::Base.site.dup.tap do |uri|
        uri.path = "/admin/api/graphql.json"
      end
    end
  end
end
