module AvailabilitiesHelper
  def time_label(starts_at, ends_at)
    labels = []
    labels << "朝" if starts_at.hour < 10 && ends_at.hour > 6
    labels << "昼" if starts_at.hour < 16 && ends_at.hour > 10
    labels << "夜" if ends_at.hour > 16
    labels.uniq.join("-").presence || "時間帯"
  end
end
