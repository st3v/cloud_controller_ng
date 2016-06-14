require 'spec_helper'

describe 'Apps' do
  let(:user) { VCAP::CloudController::User.make }
  let(:space) { VCAP::CloudController::Space.make }

  before do
    space.organization.add_user(user)
    space.add_developer(user)
  end

  describe 'GET /v2/apps' do
    let!(:process) {
      VCAP::CloudController::AppFactory.make(
        space:            space,
        environment_json: { 'RAILS_ENV' => 'staging' },
        command:          'hello_world',
        docker_credentials_json: { 'docker_user' => 'bob', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' }
      )
    }

    it 'lists all apps' do
      get '/v2/apps', nil, headers_for(user)

      expect(last_response.status).to eq(200)

      parsed_response = MultiJson.load(last_response.body)
      expect(parsed_response).to be_a_response_like(
        {
          'total_results' => 1,
          'total_pages'   => 1,
          'prev_url'      => nil,
          'next_url'      => nil,
          'resources'     => [{
            'metadata' => {
              'guid'       => process.guid,
              'url'        => "/v2/apps/#{process.guid}",
              'created_at' => iso8601,
              'updated_at' => iso8601
            },
            'entity' => {
              'name'                       => process.name,
              'production'                 => false,
              'space_guid'                 => space.guid,
              'stack_guid'                 => process.stack.guid,
              'buildpack'                  => nil,
              'detected_buildpack'         => nil,
              'environment_json'           => { 'RAILS_ENV' => 'staging' },
              'memory'                     => 1024,
              'instances'                  => 1,
              'disk_quota'                 => 1024,
              'state'                      => 'STOPPED',
              'version'                    => process.version,
              'command'                    => 'hello_world',
              'console'                    => false,
              'debug'                      => nil,
              'staging_task_id'            => nil,
              'package_state'              => 'PENDING',
              'health_check_type'          => 'port',
              'health_check_timeout'       => nil,
              'staging_failed_reason'      => nil,
              'staging_failed_description' => nil,
              'diego'                      => false,
              'docker_image'               => nil,
              'package_updated_at'         => iso8601,
              'detected_start_command'     => '',
              'enable_ssh'                 => true,
              'docker_credentials_json'    => {
                'redacted_message' => '[PRIVATE DATA HIDDEN]'
              },
              'ports'                      => nil,
              'space_url'                  => "/v2/spaces/#{space.guid}",
              'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
              'routes_url'                 => "/v2/apps/#{process.guid}/routes",
              'events_url'                 => "/v2/apps/#{process.guid}/events",
              'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
              'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
            }
          }]
        }
      )
    end

    context 'with inline-relations-depth' do
      it 'includes related records' do
        get '/v2/apps?inline-relations-depth=1', nil, headers_for(user)

        expect(last_response.status).to eq(200)

        parsed_response = MultiJson.load(last_response.body)
        expect(parsed_response).to be_a_response_like(
          {
            'total_results' => 1,
            'total_pages'   => 1,
            'prev_url'      => nil,
            'next_url'      => nil,
            'resources'     => [{
              'metadata' => {
                'guid'       => process.guid,
                'url'        => "/v2/apps/#{process.guid}",
                'created_at' => iso8601,
                'updated_at' => iso8601
              },
              'entity' => {
                'name'                       => process.name,
                'production'                 => false,
                'space_guid'                 => space.guid,
                'stack_guid'                 => process.stack.guid,
                'buildpack'                  => nil,
                'detected_buildpack'         => nil,
                'environment_json'           => { 'RAILS_ENV' => 'staging' },
                'memory'                     => 1024,
                'instances'                  => 1,
                'disk_quota'                 => 1024,
                'state'                      => 'STOPPED',
                'version'                    => process.version,
                'command'                    => 'hello_world',
                'console'                    => false,
                'debug'                      => nil,
                'staging_task_id'            => nil,
                'package_state'              => 'PENDING',
                'health_check_type'          => 'port',
                'health_check_timeout'       => nil,
                'staging_failed_reason'      => nil,
                'staging_failed_description' => nil,
                'diego'                      => false,
                'docker_image'               => nil,
                'package_updated_at'         => iso8601,
                'detected_start_command'     => '',
                'enable_ssh'                 => true,
                'docker_credentials_json'    => {
                  'redacted_message' => '[PRIVATE DATA HIDDEN]'
                },
                'ports'                      => nil,
                'space_url'                  => "/v2/spaces/#{space.guid}",
                'space'                      => {
                  'metadata' => {
                    'guid'       => space.guid,
                    'url'        => "/v2/spaces/#{space.guid}",
                    'created_at' => iso8601,
                    'updated_at' => nil
                  },
                  'entity' => {
                    'name'                        => space.name,
                    'organization_guid'           => space.organization_guid,
                    'space_quota_definition_guid' => nil,
                    'allow_ssh'                   => true,
                    'organization_url'            => "/v2/organizations/#{space.organization_guid}",
                    'developers_url'              => "/v2/spaces/#{space.guid}/developers",
                    'managers_url'                => "/v2/spaces/#{space.guid}/managers",
                    'auditors_url'                => "/v2/spaces/#{space.guid}/auditors",
                    'apps_url'                    => "/v2/spaces/#{space.guid}/apps",
                    'routes_url'                  => "/v2/spaces/#{space.guid}/routes",
                    'domains_url'                 => "/v2/spaces/#{space.guid}/domains",
                    'service_instances_url'       => "/v2/spaces/#{space.guid}/service_instances",
                    'app_events_url'              => "/v2/spaces/#{space.guid}/app_events",
                    'events_url'                  => "/v2/spaces/#{space.guid}/events",
                    'security_groups_url'         => "/v2/spaces/#{space.guid}/security_groups"
                  }
                },
                'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
                'stack'                      => {
                  'metadata' => {
                    'guid'       => process.stack.guid,
                    'url'        => "/v2/stacks/#{process.stack.guid}",
                    'created_at' => iso8601,
                    'updated_at' => nil
                  },
                  'entity' => {
                    'name'        => process.stack.name,
                    'description' => process.stack.description
                  }
                },
                'routes_url'                 => "/v2/apps/#{process.guid}/routes",
                'routes'                     => [],
                'events_url'                 => "/v2/apps/#{process.guid}/events",
                'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
                'service_bindings'           => [],
                'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
              }
            }]
          }
        )
      end
    end
  end

  describe 'GET /v2/apps/:guid' do
    let!(:process) {
      VCAP::CloudController::App.make(
        space: space,
        docker_credentials_json: { 'docker_user' => 'bob', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' }
      )
    }

    it 'maps domain_url to the shared domains controller' do
      get "/v2/apps/#{process.guid}", nil, headers_for(user)
      expect(last_response.status).to eq(200)

      parsed_response = MultiJson.load(last_response.body)
      expect(parsed_response).to be_a_response_like(
        {
          'metadata' => {
            'guid'       => process.guid,
            'url'        => "/v2/apps/#{process.guid}",
            'created_at' => iso8601,
            'updated_at' => nil
          },
          'entity' => {
            'name'                       => process.name,
            'production'                 => false,
            'space_guid'                 => process.space.guid,
            'stack_guid'                 => process.stack.guid,
            'buildpack'                  => nil,
            'detected_buildpack'         => nil,
            'environment_json'           => nil,
            'memory'                     => 1024,
            'instances'                  => 1,
            'disk_quota'                 => 1024,
            'state'                      => 'STOPPED',
            'version'                    => process.version,
            'command'                    => process.command,
            'console'                    => false,
            'debug'                      => nil,
            'staging_task_id'            => nil,
            'package_state'              => 'PENDING',
            'health_check_type'          => 'port',
            'health_check_timeout'       => nil,
            'staging_failed_reason'      => nil,
            'staging_failed_description' => nil,
            'diego'                      => false,
            'docker_image'               => nil,
            'package_updated_at'         => nil,
            'detected_start_command'     => '',
            'enable_ssh'                 => true,
            'docker_credentials_json'    => {
              'redacted_message' => '[PRIVATE DATA HIDDEN]'
            },
            'ports'                      => nil,
            'space_url'                  => "/v2/spaces/#{process.space.guid}",
            'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
            'routes_url'                 => "/v2/apps/#{process.guid}/routes",
            'events_url'                 => "/v2/apps/#{process.guid}/events",
            'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
            'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
          }
        }
      )
    end
  end

  describe 'GET /v2/apps/:guid/summary' do
    let!(:process) { VCAP::CloudController::AppFactory.make(space: space, name: 'woo') }

    it 'gives a summary of the specified app' do
      private_domains = process.space.organization.private_domains
      shared_domains = VCAP::CloudController::SharedDomain.all.collect do |domain|
        { 'guid' => domain.guid,
          'name' => domain.name,
          'router_group_guid' => domain.router_group_guid,
          'router_group_type' => domain.router_group_type,
        }
      end
      avail_domains = private_domains + shared_domains

      get "/v2/apps/#{process.guid}/summary", nil, headers_for(user)

      expect(last_response.status).to eq(200)
      expect(MultiJson.load(last_response.body)).to be_a_response_like(
        {
          'guid'                       => process.guid,
          'name'                       => 'woo',
          'routes'                     => [],
          'running_instances'          => 0,
          'services'                   => [],
          'available_domains'          => avail_domains,
          'production'                 => false,
          'space_guid'                 => space.guid,
          'stack_guid'                 => process.stack.guid,
          'buildpack'                  => nil,
          'detected_buildpack'         => nil,
          'environment_json'           => nil,
          'memory'                     => 1024,
          'instances'                  => 1,
          'disk_quota'                 => 1024,
          'state'                      => 'STOPPED',
          'version'                    => process.version,
          'command'                    => nil,
          'console'                    => false,
          'debug'                      => nil,
          'staging_task_id'            => nil,
          'package_state'              => 'PENDING',
          'health_check_type'          => 'port',
          'health_check_timeout'       => nil,
          'staging_failed_reason'      => nil,
          'staging_failed_description' => nil,
          'diego'                      => false,
          'docker_image'               => nil,
          'package_updated_at'         => iso8601,
          'detected_start_command'     => '',
          'enable_ssh'                 => true,
          'docker_credentials_json'    => {'redacted_message' => '[PRIVATE DATA HIDDEN]'},
          'ports'                      => nil
        })
    end
  end

  describe 'GET /v2/apps/:guid/service_bindings' do
    let!(:process) { VCAP::CloudController::AppFactory.make }
    let!(:admin) { VCAP::CloudController::User.make(admin: true) }
    let!(:service_instance) { VCAP::CloudController::ManagedServiceInstance.make(space: process.space) }
    let!(:service_binding) { VCAP::CloudController::ServiceBinding.make(service_instance: service_instance, app: process) }


    before do
      service_instance.add_service_binding(service_binding)
    end

    it 'lists the service bindings associated with the app' do
      get "/v2/apps/#{process.guid}/service_bindings", nil, admin_headers_for(admin)

      parsed_response = MultiJson.load(last_response.body)

      expect(last_response.status).to eq 200
      expect(parsed_response['total_results']).to be(1)
      expect(parsed_response['resources'][0]['entity']['app_guid']).to eq(process.guid)
      expect(parsed_response['resources'][0]['entity']['service_instance_guid']).to eq(service_instance.guid)
    end
  end

  describe 'GET /v2/apps/:guid/instances' do
    let!(:admin) { VCAP::CloudController::User.make(admin: true) }
    let!(:process) { VCAP::CloudController::AppFactory.make(diego: true, state: 'STARTED', package_state: 'STAGED', instances: 2) }
    let(:tps_url) { "http://tps.service.cf.internal:1518/v1/actual_lrps/#{process.guid}-#{process.version}" }
    let(:instances) { [
      { process_guid: process.guid, instance_guid: 'instance-A', index: 0, state: 'RUNNING', uptime: 0 },
      { process_guid: process.guid, instance_guid: 'instance-A', index: 1, state: 'RUNNING', uptime: 0 }
    ]}

    before do
      stub_request(:get, tps_url).with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, body: instances.to_json)
    end

    it 'gets the instance information for a started app' do
      get "/v2/apps/#{process.guid}/instances", nil, admin_headers_for(admin)
      parsed_response = MultiJson.load(last_response.body)

      expect(last_response.status).to eq(200)
      expect(parsed_response.length).to eq 2
      expect(parsed_response['0']['state']).to eq 'RUNNING'
      expect(parsed_response['1']['state']).to eq 'RUNNING'
    end
  end

  describe 'POST /v2/apps' do
    it 'creates an app' do
      post_params = MultiJson.dump({
        name:       'maria',
        space_guid: space.guid,
        detected_start_command: 'argh',
        docker_credentials_json: { 'docker_user' => 'bob', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' }
      })

      post '/v2/apps', post_params, headers_for(user)

      process = VCAP::CloudController::App.last
      expect(last_response.status).to eq(201)
      expect(MultiJson.load(last_response.body)).to be_a_response_like(
        {
          'metadata' => {
            'guid'       => process.guid,
            'url'        => "/v2/apps/#{process.guid}",
            'created_at' => iso8601,
            'updated_at' => nil
          },
          'entity' => {
            'name'                       => 'maria',
            'production'                 => false,
            'space_guid'                 => space.guid,
            'stack_guid'                 => process.stack.guid,
            'buildpack'                  => nil,
            'detected_buildpack'         => nil,
            'environment_json'           => {

            },
            'memory'                     => 1024,
            'instances'                  => 1,
            'disk_quota'                 => 1024,
            'state'                      => 'STOPPED',
            'version'                    => process.version,
            'command'                    => nil,
            'console'                    => false,
            'debug'                      => nil,
            'staging_task_id'            => nil,
            'package_state'              => 'PENDING',
            'health_check_type'          => 'port',
            'health_check_timeout'       => nil,
            'staging_failed_reason'      => nil,
            'staging_failed_description' => nil,
            'diego'                      => false,
            'docker_image'               => nil,
            'package_updated_at'         => nil,
            'detected_start_command'     => '',
            'enable_ssh'                 => true,
            'docker_credentials_json'    => {
              'redacted_message' => '[PRIVATE DATA HIDDEN]'
            },
            'ports'                      => nil,
            'space_url'                  => "/v2/spaces/#{space.guid}",
            'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
            'routes_url'                 => "/v2/apps/#{process.guid}/routes",
            'events_url'                 => "/v2/apps/#{process.guid}/events",
            'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
            'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
          }
        }
      )
    end
  end

  describe 'POST /v2/apps/:guid/copy_bits' do
    let!(:source_process) { VCAP::CloudController::AppFactory.make(space: space) }
    let!(:destination_process) { VCAP::CloudController::AppFactory.make(space: space) }

    it 'queues a job to copy the bits' do
      post "/v2/apps/#{destination_process.guid}/copy_bits", MultiJson.dump({source_app_guid: source_process.guid}), headers_for(user)

      expect(last_response.status).to eq(201)
      parsed_response = MultiJson.load(last_response.body)
      expect(parsed_response['entity']['status']).to eq 'queued'
    end
  end

  describe 'PUT /v2/apps/:guid' do
    let!(:process) {
      VCAP::CloudController::AppFactory.make(
        space:            space,
        name: 'mario',
        environment_json: { 'RAILS_ENV' => 'staging' },
        command:          'hello_world',
        docker_credentials_json: { 'docker_user' => 'bob', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' }
      )
    }

    it 'updates an app' do
      update_params = MultiJson.dump({
        name:       'maria',
        environment_json: { 'RAILS_ENV' => 'production' },
        state: 'STARTED',
        detected_start_command: 'argh'
      })

      put "/v2/apps/#{process.guid}", update_params, headers_for(user)

      process.reload
      expect(last_response.status).to eq(201)
      expect(MultiJson.load(last_response.body)).to be_a_response_like(
        {
          'metadata' => {
            'guid'       => process.guid,
            'url'        => "/v2/apps/#{process.guid}",
            'created_at' => iso8601,
            'updated_at' => iso8601
          },
          'entity' => {
            'name'                       => 'maria',
            'production'                 => false,
            'space_guid'                 => space.guid,
            'stack_guid'                 => process.stack.guid,
            'buildpack'                  => nil,
            'detected_buildpack'         => nil,
            'environment_json'           => {
              'RAILS_ENV' => 'production'
            },
            'memory'                     => 1024,
            'instances'                  => 1,
            'disk_quota'                 => 1024,
            'state'                      => 'STARTED',
            'version'                    => process.version,
            'command'                    => 'hello_world',
            'console'                    => false,
            'debug'                      => nil,
            'staging_task_id'            => nil,
            'package_state'              => 'PENDING',
            'health_check_type'          => 'port',
            'health_check_timeout'       => nil,
            'staging_failed_reason'      => nil,
            'staging_failed_description' => nil,
            'diego'                      => false,
            'docker_image'               => nil,
            'package_updated_at'         => iso8601,
            'detected_start_command'     => '',
            'enable_ssh'                 => true,
            'docker_credentials_json'    => {
              'redacted_message' => '[PRIVATE DATA HIDDEN]'
            },
            'ports'                      => nil,
            'space_url'                  => "/v2/spaces/#{space.guid}",
            'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
            'routes_url'                 => "/v2/apps/#{process.guid}/routes",
            'events_url'                 => "/v2/apps/#{process.guid}/events",
            'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
            'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
          }
        }
      )
    end
  end

  describe 'PUT /v2/apps/:guid/routes/:route_guid' do
    let!(:process) { VCAP::CloudController::AppFactory.make(space: space) }
    let!(:route) { VCAP::CloudController::Route.make(space: space) }

    it 'associates an app and a route' do
      put "/v2/apps/#{process.guid}/routes/#{route.guid}", nil, headers_for(user)
      process.reload

      expect(last_response.status).to eq(201)

      get "/v2/apps/#{process.guid}/route_mappings", nil, headers_for(user)
      parsed_response = MultiJson.load(last_response.body)

      expect(parsed_response['total_results']).to eq 1
      expect(parsed_response['resources'][0]['entity']['route_guid']).to eq(route.guid)
    end
  end

  describe 'DELETE /v2/apps/:guid' do
    let!(:process) { VCAP::CloudController::AppFactory.make(space: space) }

    it 'deletes the specified app' do
      delete "/v2/apps/#{process.guid}", nil, headers_for(user)

      expect(last_response.status).to eq(204)

      get "/v2/apps/#{process.guid}", nil, headers_for(user)
      parsed_response = MultiJson.load(last_response.body)

      expect(parsed_response['error_code']).to eq 'CF-AppNotFound'
    end
  end
end
