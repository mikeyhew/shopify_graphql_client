# ShopifyGraphQLClient

An alternative client for Shopify's GraphQL Admin API. Loads the schema from a file instead of dowloading it at runtime, so that you can parse queries before you have a shop session and assign them to a constant; and uses `ShopifyAPI::Base.site` when creating the endpoint's URI so that you don't have to create a new client for every shop.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shopify_graphql_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shopify_graphql_client

## Usage

```ruby
QUERY = ShopifyGraphQLClient.parse <<~GRAPHQL
  {
    shop {
      name
    }
  }
GRAPHQL

# later, once you have activated a session with ShopifyAPI
result = ShopifyGraphQLClient.query(QUERY)

result.data.shop.name
# => "My Shop"
```

Just like `ShopifyAPI::GraphQL`, this uses the `graphql-client` gem under the hood. The `client` method gives you access to the `GraphQL::Client` instance:

```ruby
ShopifyGrahphqlClient.client
# => #<GraphQL::Client:0x00...>
```

For example, you can to enable dynamic queries:

```ruby
ShopifyGraphQLClient.client.allow_dynamic_queries = true

ShopifyGraphQLClient.query(ShopifyGraphQLClient.parse("{shop{name}}"))
# => #<GraphQL::Client:Response:0x00...>
```

Note that dynamic queries are deprecated and that option will probably be removed by `graphql-client` at some point.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

The schema file will need to be updated from time to time. To do so, run `bin/update_schema`. It requires that you have a shop with an app installed in it, and an oauth token for that shop. You can pass these in as environment variables: `SHOP_NAME=myshop OAUTH_TOKEN=... bin/update_schema`. Alternatively, you can put them in a `.env` file and it will be loaded automatically with the `dotenv` gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/shopify_graphql_client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
