require "shopify_graphql_client/version"
require "graphql/client"
require "shopify_api"

module ShopifyGraphQLClient
  class Error < StandardError; end
  class GraphQLError < Error; end
  class ThrottledError < Error; end

  require "shopify_graphql_client/query_builder"

  class << self
    def parse(str, filename=nil, lineno=nil)
      if filename.nil? && lineno.nil?
        location = caller_locations(1, 1).first
        filename = location.path
        lineno = location.lineno
      end

      client.parse(str, filename=filename, lineno=lineno)
    end

    def client
      @client ||= GraphQL::Client.new(schema: schema, execute: Executor.new).tap do |client|
        client.allow_dynamic_queries = true
      end
    end

    # `query = ShopifyGraphQLClient.query(some_var: :Int!) do ... end`
    def query(**args, &blk)
      builder = QueryBuilder.new(&blk)
      # TODO call builder.build or something
    end

    def fragment(on_type, **args, &blk)
      builder = QueryBuilder.new(&blk)
    end

    def exec(*args)
      result = client.query(*args)
      errors = result.errors

      if result.errors&.any?
        messages = result.errors.messages.map do |path, messages|
          if messages.length > 0
            messages = messages.map{|message| "  - #{message}"}
            "#{path}:\n" + messages.join("\n")
          else
            "#{path}: #{messages.first}"
          end
        end

        raise GraphQLError, messages.join("\n")
      end

      result
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
