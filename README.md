# Servus: `async` and `call_async` depend on ActiveJob load order

A minimal Rails 8.1 app that reproduces a boot failure in
[Servus](https://github.com/zarpay/servus) 1.0.2 (and `main` at the time of
writing), for the pull request
[zarpay/servus: fix(railtie): load ActiveJob before events](https://github.com/zarpay/servus/compare/main...pootsbook:servus:fix/load-active-job-before-events?expand=1).

It is a fresh `rails new` app with three classes, each using a documented
Servus feature:

- [`Greeting::Send::Service`](app/services/greeting/send/service.rb), an ordinary service;
- [`Greeting::Archive::Service`](app/services/greeting/archive/service.rb), a service that configures its job with `async queue: :low`;
- [`GreetingSentEvent`](app/events/greeting_sent_event.rb), an event that `enqueue`s the second service.

## Reproduce

Ruby 3.2 or later.

```
git clone https://github.com/pootsbook/servus-async-boot-repro
cd servus-async-boot-repro
bundle install
```

The app fails to boot, in development and in production alike:

```
$ bin/rails runner 'puts :booted'
app/services/greeting/archive/service.rb:6:in '<class:Service>': undefined method 'async' for class Greeting::Archive::Service (NoMethodError)

$ RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails runner 'puts :booted'
app/services/greeting/archive/service.rb:6:in '<class:Service>': undefined method 'async' for class Greeting::Archive::Service (NoMethodError)
```

Without the event, the app boots, but in development nothing async works until
something else happens to load ActiveJob:

```
$ rm app/events/greeting_sent_event.rb
$ bin/rails runner script/check.rb
Servus 1.0.2, Rails 8.1.4, development
ActiveJob loaded after boot?                   false
Greeting::Send::Service.call_async             NoMethodError: undefined method 'call_async' for class Greeting::Send::Service
Greeting::Archive::Service job queue           NoMethodError: undefined method 'async' for class Greeting::Archive::Service
```

(`git checkout app/events` brings the event back.)

## Why

Servus installs `async` and `call_async` from `ActiveSupport.on_load(:active_job)`,
and Rails loads ActiveJob lazily. After a development boot it usually has not
loaded at all. The railtie's `to_prepare` loads events, and with them the
services they enqueue, before anything has touched `ActiveJob::Base`. That
also happens under production eager loading, because `to_prepare` runs before
`eager_load!`.

## The proposed fix

In the [`Gemfile`](Gemfile), comment out `gem "servus", "1.0.2"`, uncomment the
line below it, then `bundle install`:

```ruby
gem "servus", github: "pootsbook/servus", branch: "fix/load-active-job-before-events", glob: "gem/*.gemspec"
```

The same commands now boot, and the check passes:

```
$ bin/rails runner script/check.rb
Servus 1.1.0, Rails 8.1.4, development
ActiveJob loaded after boot?                   true
Greeting::Send::Service.call_async             Greeting::Send::ServiceJob
Greeting::Archive::Service job queue           low
```
