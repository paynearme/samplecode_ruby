# PaynearmeCallbacks

PayNearMe Callbacks implementation for Ruby webservices and applications. 
Usable with any ```Rack``` friendly application.

This package serves as a starting point for integrating paynearme callbacks
into your existing ruby application stack. It is an example implementation
and leaves implementation details up to the end user (you). 

## Usage and Installation

### Rails

Add this line to your Rails app's `Gemfile`:

	gem 'paynearme_callbacks'

And then execute:

	$ bundle
	$ rails g paynearme:install_callbacks

This will install the following files:

	config/initializers/paynearme_api.rb
	app/api/paynearme.rb

And adds the following to routes:

	mount Paynearme::Callbacks::API => '/callbacks'

You can access the callbacks on

	http://0.0.0.0:3000/callbacks/{authorize,confirm}

Modify `app/api/paynearme.rb` for proper integration into your systems. 

#### Supported Versions

  * Rails 3.2.x (we recommend >= 3.2.15)
  * Rails 4.0.x (we recommend >= 4.0.2)

### Rack or standalone Installation

Add this line to your application's Gemfile:

    gem 'paynearme_callbacks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paynearme_callbacks


