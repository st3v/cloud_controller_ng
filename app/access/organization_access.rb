module VCAP::CloudController
  class OrganizationAccess < BaseAccess
    def create?(org, params=nil)
      return true if admin_user?
      FeatureFlag.enabled?('user_org_creation')
    end

    def read_for_update?(org, params=nil)
      return true if admin_user?
      return false unless org.active?
      return false unless org.managers.include?(context.user)

      if params.present?
        return false if params.key?(:quota_definition_guid.to_s) || params.key?(:billing_enabled.to_s)
      end

      true
    end

    def read_related_object_for_update?(object, params={})
      same_user?(params) || super
    end

    def update?(org, params=nil)
      return true if admin_user?
      return false unless org.active?
      org.managers.include?(context.user)
    end

    def update_related_object?(object, params={})
      removing_same_user?(params) || super
    end

    private

    def removing_same_user?(options)
      options[:verb] == 'remove' && same_user?(options)
    end

    def same_user?(options)
      [:users, :managers, :billing_managers].include?(options[:relation]) && context.user.guid == options[:related_guid]
    end
  end
end
