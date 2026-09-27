# An event that enqueues the service above, as documented in
# https://zarpay.github.io/servus/features/event-bus
class GreetingSentEvent < Servus::Event
  enqueue Greeting::Archive::Service
end
