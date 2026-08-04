module ApplicationHelper
  def enum_label(record, attribute)
    value = record.public_send(attribute)
    t("statuses.#{record.model_name.i18n_key}.#{value}")
  end
end
