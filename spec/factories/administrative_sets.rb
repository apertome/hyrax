# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    title { ['My Admin Set'] }

    transient do
      with_permission_template { false }
      user { create(:user) }
      access_grants { [] }
    end

    after(:build) do |adminset, evaluator|
      adminset.creator = [evaluator.user.user_key]
    end

    after(:create) do |admin_set, evaluator|
      if evaluator.with_permission_template
        template = Hyrax::PermissionTemplate.find_or_create_by(source_id: admin_set.id.to_s)
        evaluator.access_grants.each do |grant|
          Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: template.id,
                                                            agent_type: grant[:agent_type],
                                                            agent_id: grant[:agent_id],
                                                            access: grant[:access])
        end
        Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: template.id,
                                                          agent_type: Hyrax::PermissionTemplateAccess::USER,
                                                          agent_id: evaluator.user.user_key,
                                                          access: Hyrax::PermissionTemplateAccess::MANAGE)
        template.reset_access_controls_for(collection: admin_set)
      end
    end
  end

  factory :invalid_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    # Title is required.  Without title, the admin set is invalid.
  end

  factory :default_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    id { Hyrax::AdminSetCreateService::DEFAULT_ID }
    title { Hyrax::AdminSetCreateService::DEFAULT_TITLE }
  end
end
