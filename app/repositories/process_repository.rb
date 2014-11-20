require 'models/v3/mappers/process_mapper'

module VCAP::CloudController
  class ProcessRepository
    class MutationAttemptWithoutALock < StandardError; end
    class InvalidProcess < StandardError; end
    class ProcessNotFound < StandardError; end

    def new_process(opts)
      AppProcess.new(opts)
    end

    def persist!(desired_process)
      process_model = ProcessMapper.map_domain_to_model(desired_process)

      raise ProcessNotFound if process_model.nil?
      raise MutationAttemptWithoutALock if process_model.guid && !@lock_acquired

      process_model.save
      ProcessMapper.map_model_to_domain(process_model)
    rescue Sequel::ValidationFailed => e
      raise InvalidProcess.new(e.message)
    end

    def find_by_guid(guid)
      process_model = App.where(guid: guid).first
      return if process_model.nil?
      ProcessMapper.map_model_to_domain(process_model)
    end

    def find_for_show(guid)
      process_model = App.where(apps__guid: guid).eager_graph(:space).all.first
      return nil, nil if process_model.nil?
      return ProcessMapper.map_model_to_domain(process_model), process_model.space
    end

    def find_for_update(guid)
      App.db.transaction do
        # We need to lock the row in the apps table. However we cannot eager
        # load associations while using the for_update method. Therefore we
        # need to fetch the App twice. This allows us to only make 2 queries,
        # rather than 3-4.
        App.for_update.where(guid: guid).first
        process_model = App.where(apps__guid: guid).eager_graph(:space, :stack).all.first
        yield nil, nil and return if process_model.nil?

        @lock_acquired = true
        begin
          yield ProcessMapper.map_model_to_domain(process_model), process_model.space
        ensure
          @lock_acquired = false
        end
      end
    end

    def find_by_guid_for_update(guid)
      process_model = App.find(guid: guid)
      yield nil and return if process_model.nil?

      process_model.db.transaction do
        process_model.lock!
        process = ProcessMapper.map_model_to_domain(process_model)
        @lock_acquired = true
        begin
          yield process
        ensure
          @lock_acquired = false
        end
      end
    end

    def delete(process)
      process_model = App.find(guid: process.guid)
      return unless process_model
      raise MutationAttemptWithoutALock unless @lock_acquired
      process_model.destroy

      process
    end
  end
end
