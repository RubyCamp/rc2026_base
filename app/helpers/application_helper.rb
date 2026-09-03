module ApplicationHelper
  COMMON_BASE_LABEL = "共通基盤".freeze
  INTEGRATION_LABEL = "統合版".freeze

  # Keep provenance in one place so a page can be extended without scattering
  # team labels throughout the individual team views.
  PAGE_OWNERSHIP = {
    "home#index" => COMMON_BASE_LABEL,
    "guide#index" => INTEGRATION_LABEL,
    "sessions#new" => "Team 3",
    "sessions#create" => "Team 3",
    "sessions#destroy" => "Team 3",
    "admin/calendar#index" => "Team 3",
    "admin/details#show" => "Team 3",
    "admin/demo_data#index" => INTEGRATION_LABEL,
    "admin/demo_data#authenticate" => INTEGRATION_LABEL,
    "admin/demo_data#relock" => INTEGRATION_LABEL,
    "admin/demo_data#create" => INTEGRATION_LABEL,
    "admin/demo_data#reset" => INTEGRATION_LABEL,
    "admin/demo_data#destroy" => INTEGRATION_LABEL,
    "provider/detail#show" => "Team 3",
    "provider/work_requests#show" => "Team 3",
    "provider/work_requests#new" => "Team 3",
    "provider/work_requests#create" => "Team 3",
    "provider/work_requests#edit" => "Team 3",
    "provider/work_requests#update" => "Team 3",
    "work_requests#index" => "Team 1 / Team 5",
    "work_requests#show" => "Team 1 / Team 5",
    "work_requests#edit" => "Team 1 / Team 5",
    "work_requests#update" => "Team 1 / Team 5",
    "work_requests#assign" => "Team 1 / Team 5",
    "work_requests#unassign" => "Team 1 / Team 5",
    "work_requests#confirm" => "Team 1 / Team 5",
    "work_requests#destroy_assignment" => "Team 1 / Team 5",
    "work_requests#draft" => "Team 5",
    "work_requests#unassign_all" => "Team 5",
    "work_requests#shift" => "Team 5",
    "work_requests#export" => "Team 5",
    "details_of_shifts#index" => "Team 4",
    "details_of_shifts#show" => "Team 4",
    "details_of_shifts#edit" => "Team 4",
    "details_of_shifts#update" => "Team 4",
    "availabilities#index" => "Team 6",
    "availabilities#new" => "Team 6",
    "availabilities#create" => "Team 6",
    "availabilities#edit" => "Team 6",
    "availabilities#update" => "Team 6",
    "availabilities#destroy" => "Team 6",
    "list_views#index" => "Team 1",
    "list_views#confirmed" => "Team 1",
    "list_views#confirm" => "Team 1",
    "list_views#unconfirm" => "Team 1",
    "change_events#index" => "Team 2",
    "change_events#update" => "Team 2",
    "debug/change_events#index" => "Team 2",
    "debug/change_events#create" => "Team 2",
    "debug/change_events#destroy" => "Team 2",
    "staff_members#index" => COMMON_BASE_LABEL,
    "tutorials#index" => COMMON_BASE_LABEL,
    "tutorials#debug" => COMMON_BASE_LABEL,
    "tutorials#show" => COMMON_BASE_LABEL,
    "examples#local_data" => COMMON_BASE_LABEL
  }.freeze

  def page_ownership_label
    PAGE_OWNERSHIP.fetch("#{controller_path}##{action_name}", COMMON_BASE_LABEL)
  end

  def enum_label(record, attribute)
    value = record.public_send(attribute)
    t("statuses.#{record.model_name.i18n_key}.#{value}")
  end

  def work_request_status_options(exclude_confirmed: false)
    options = %w[open draft confirmed cancelled]
    exclude_confirmed ? options.reject { |status| status == "confirmed" } : options
  end
end
