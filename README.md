# Hydra::RemoteIdentifier

[![Gem Version](https://badge.fury.io/rb/hydra-remote_identifier.png)](http://badge.fury.io/rb/hydra-remote_identifier)
[![Build Status](https://travis-ci.org/projecthydra-labs/hydra-remote_identifier.png)](https://travis-ci.org/project-hydra-labs/hydra-remote_identifier)

Coordinate the registration and minting of remote identifiers for persisted
objects.

## Installation

Add this line to your application's Gemfile:

    gem 'hydra-remote_identifier'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hydra-remote_identifier

## Usage

Configure your remote identifiers with credentials and what have you:

```ruby
doi_credentials = Psych.load('/path/to/doi_credentials.yml')
Hydra::RemoteIdentifier.configure do |config|
  config.remote_service(:doi, doi_credentials) do |doi|
    doi.register(Book, Page) do |map|
      map.target :url
      map.creator {|obj| obj.person_name }
      map.title :title
      map.publisher :publisher
      map.publicationyear :publicationyear
      map.set_identifier(:set_identifier=)
    end
  end
end
```

If you are using Rails, you can run `rails generate hydra:remote_identifier:install` to
create a Rails initializer with a configuration stub file. Also available is
`rails generate hydra:remote_identifier:doi`.

In your views allow users to request that a remote identifier be created/assigned:

```ruby
<%= form_for book do |f| %>
  <% Hydra::RemoteIdentifier.registered?(:doi, f.object) do |remote_service| %>
    <%= f.input remote_service.accessor_name %>
  <% end %>
<% end %>
```

Where you enqueue an asynchronous worker iterate over the requested identifiers:

```ruby
Hydra::RemoteIdentifier.applicable_remote_service_names_for(book) do |remote_service|
  MintRemoteIdentifierWorker.enqueue(book.to_param, remote_service.name)
end
```

Where your asynchronous worker does its work request the minting:

```ruby
# Instantiate target from input
Hydra::RemoteIdentifier.mint(remote_service_name, target)
```

In your show views you can provide a link to the remote identifier via
Hydra::RemoteIdentifier.remote_uri_for:

```ruby
<%= link_to(object.doi, Hydra::RemoteIdentifier.remote_uri_for(:doi, object.doi)) %>
```

## Extending Hydra::RemoteIdentifier with alternate remote identifiers

If you are interested in creating a new Hydra::RemoteIdentifier::RemoteService,
this can be done by creating a class in the Hydra::RemoteIdentifier::RemoteServices
namespace. See below:

```ruby
module Hydra::RemoteIdentifier::RemoteServices
  class MyRemoteService < Hydra::RemoteIdentifier::RemoteService
    # your code here
  end
end
```

Then configure your RemoteService for your persisted targets. See below:

```ruby
Hydra::RemoteIdentifier.configure do |config|
  config.remote_service(:my_remote_service, credentials) do |mine|
    mine.register(Book, Page) do |map|
      # map fields of Book, Page to the required payload for MyRemoteService
    end
  end
end
```
