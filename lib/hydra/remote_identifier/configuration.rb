require File.expand_path('../remote_services', __FILE__)

module Hydra::RemoteIdentifier

  # Configuration is responsible for exposing the available RemoteServices
  # and configuring those RemoteServices.
  class Configuration

    def initialize(remote_service_namespace_container = Hydra::RemoteIdentifier::RemoteServices)
      @remote_service_namespace_container = remote_service_namespace_container
      @remote_services = {}
    end
    attr_reader :remote_service_namespace_container
    private :remote_service_namespace_container
    attr_reader :remote_services

    def find_remote_service(service_name)
      remote_services.fetch(service_name, remote_service_class_lookup(service_name).new)
    end

    def remote_service(service_name, *args, &block)
      remote_service_class_lookup(service_name).configure(*args, &block)
    end

    class ConfigRegistration
      attr_reader :remote_service
      def initialize(remote_service)
        @remote_service = remote_service
      end
      def register(*klasses, &map)
        Registration.new(remote_service, *klasses, &map)
      end
    end

    def configure_remote_service(service_name, *args, &block)
      remote_service = remote_service_class_lookup(service_name).new(*args)
      remote_services[service_name]
      yield(ConfigRegistration.new(remote_service))
    end

    private

    def remote_service_class_lookup(string)
      remote_service_class_name = string.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
      if remote_service_namespace_container.const_defined?(remote_service_class_name)
        remote_service_namespace_container.const_get(remote_service_class_name)
      else
        raise NotImplementedError.new(
          "Unable to find #{self} remote_service '#{string}'. Consider creating #{remote_service_namespace_container}::#{remote_service_class_name}"
        )
      end
    end
  end

end