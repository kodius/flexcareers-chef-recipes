# frozen_string_literal: true

module Drivers
  module Framework
    class Base < Drivers::Base
      include Drivers::Dsl::Logrotate
      include Drivers::Dsl::Output
      include Drivers::Dsl::Packages

      def setup
        handle_packages
      end

      def configure
        configure_logrotate
      end

      def deploy_before_restart
        old_before_restart_commands
        assets_precompile if out[:assets_precompile]
      end

      def validate_app_engine; end

      def migrate?
        applicable_databases.any?(&:can_migrate?) && out[:migrate]
      end

      protected

      def assets_precompile
        output = out
        deploy_to = deploy_dir(app)
        env = environment.merge('HOME' => node['deployer']['home'])

        context.execute 'assets:precompile' do
          command output[:assets_precompilation_command]
          user node['deployer']['user']
          cwd File.join(deploy_to, 'current')
          group www_group
          environment env
        end
      end

      def database_url
        deploy_to = deploy_dir(app)
        applicable_databases.first.try(:url, deploy_to)
      end

      def applicable_databases
        dbs = options[:databases] || Drivers::Db::Factory.build(context, app)
        Array.wrap(dbs).select(&:applicable_for_configuration?)
      end

      def environment
        app['environment'].merge(out[:deploy_environment])
      end

      def old_before_restart_commands
        # if new_resource.environment['APACHE_SPECTRUM_SUPPORT'] == 'true'
        #   Chef::Log.info('Modifying Apache Vhosts so Spectrum UI can run on port 80')
        #   CONFIG_PATH = '/etc/apache2/sites-available/flexcareers_workers.conf'.freeze
        #   config_file = ::File.open(CONFIG_PATH).read
        #   config_file = config_file.gsub!('<VirtualHost *:80>', '<VirtualHost *:8080>')
        #   ::File.open(CONFIG_PATH, 'w') { |file| file.write(config_file) }
        # end
      end
    end
  end
end
