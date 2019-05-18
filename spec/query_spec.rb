require "shopify_graphql_client"

describe "query" do
  it "should create a simple query" do
    query = ShopifyGraphQLClient.query do
      app do
        handle
      end
    end

    # do something with the query
  end

  it "query with args" do
    query = ShopifyGraphQLClient.query(product_id: :ID!) do
      product(id: :product_id)
    end
  end

  it "should be able to create fragments" do
    fragment = ShopifyGraphQLClient.fragment(:Product) do
      title
      featured_image do
        transformed_src
      end
    end
  end

  it "should be able to include fragments" do
    fragment = ShopifyGraphQLClient.fragment(:Product) do
      title
      featured_image do
        transformed_src
      end
    end

    query = ShopifyGraphQLClient.query do
      product(id: 123) do
        include fragment
      end
    end
  end

  it "should support fragments with arguments" do
    fragment = ShopifyGraphQLClient.fragment(:QueryRoot, id: :Int!) do
      product(id: :id) do
        title
      end
    end
  end

  it "should support transformations" do
    fragment = ShopifyGraphQLClient.fragment(:Product) do
      title
      image << featured_image
    end
  end

  it "should let you get subfields" do
    fragment = ShopifyGraphQLClient.fragment(:Product) do
      image << featured_image.transformed_src
    end
  end

  it "complicated subfields" do
    query = ShopifyGraphQLClient.query do
      product_image << product(id: 123).featured_image.transformed_src
    end
  end

  it "should be able to get multiple things as an object" do
    query = ShopifyGraphQLClient.query do
      the_product << object do
        the_title << product(id: 123).title
        the_id << product(id: 123).id
      end
    end
  end

  it "should be able to include a returned object's fields directly" do
    query = ShopifyGraphQLClient.query do
      include product(id: 123) do
        title
        id
      end
    end
  end

  it "should let you provide a value with `with_value`" do
    query = ShopifyGraphQLClient.query do
      foo.with_value("Some Value")
    end
  end

  it "should support getting multiple products as an array" do
    query = ShopifyGraphQLClient.query do
      products << [1234234, 4723189, 349087].map do |id|
        product(id: "gid://shopify/Product/#{id.to_i}") do
          # field(:id) helps get around name shadowing
          # .with_value lets you provide a value to show up in the response
          field(:id).with_value(id)
          title
        end
      end
    end

    # result = query.exec
    # expect(result.products[0].id).to eq(1234234)
  end
end
