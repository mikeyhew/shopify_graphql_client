require "shopify_graphql_client"
require "dotenv/load"

describe "client" do
  it "primary domain should be $SHOP_DOMAIN.myshopify.com" do
    QUERY = ShopifyGraphQLClient.parse <<~GRAPHQL
      {
        shop {
          myshopifyDomain
        }
      }
    GRAPHQL

    session = ShopifyAPI::Session.new(
      ENV.fetch("SHOP_DOMAIN") + ".myshopify.com",
      ENV.fetch("OAUTH_TOKEN"),
    )

    ShopifyAPI::Base.activate_session(session)

    result = ShopifyGraphQLClient.query(QUERY)

    expect(result.data.shop.myshopify_domain).to eq(ENV["SHOP_DOMAIN"] + ".myshopify.com")
  end
end

