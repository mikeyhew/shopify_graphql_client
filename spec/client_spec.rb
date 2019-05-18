require "shopify_graphql_client"
require "dotenv/load"

def with_session(&blk)
  ShopifyAPI::Session.temp(
    domain: ENV.fetch("SHOP_DOMAIN") + ".myshopify.com",
    token: ENV.fetch("OAUTH_TOKEN"),
    api_version: "2019-04",
    &blk
  )
end

describe "client" do
  it "primary domain should be $SHOP_DOMAIN.myshopify.com" do
    query = ShopifyGraphQLClient.parse <<~GRAPHQL
      {
        shop {
          myshopifyDomain
        }
      }
    GRAPHQL

    with_session do
      result = ShopifyGraphQLClient.exec(query)
      expect(result.data.shop.myshopify_domain).to eq(ENV["SHOP_DOMAIN"] + ".myshopify.com")
    end
  end

  it "should have the right file name and line number" do
    query_line = __LINE__ + 1
    query = ShopifyGraphQLClient.parse <<~GRAPHQL
      {
        shop {
          myshopifyDomain
        }
      }
    GRAPHQL

    expect(query.source_location).to eq([__FILE__, query_line])
  end
end

