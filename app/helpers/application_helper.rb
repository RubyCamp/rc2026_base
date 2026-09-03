module ApplicationHelper
  def enum_label(record, attribute)
    value = record.public_send(attribute)
    t("statuses.#{record.model_name.i18n_key}.#{value}")
  end

  def work_request_status_options(exclude_confirmed: false)
    options = %w[open draft confirmed cancelled]
    exclude_confirmed ? options.reject { |status| status == "confirmed" } : options
  end
end
