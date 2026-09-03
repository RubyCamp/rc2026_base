module WorkRequestsHelper
  GANTT_COLORS = %w[#2f6fae #eab308 #14b8a6 #f87171 #6b7280].freeze
  GANTT_LANE_HEIGHT_REM = 3.25

  def gantt_business_color(index)
    GANTT_COLORS[index % GANTT_COLORS.size]
  end

  def gantt_row_height_rem(lanes_count)
    lanes_count * GANTT_LANE_HEIGHT_REM
  end

  # 会社ごとに1行を割り当て、勤務依頼を月内の開始/終了日にクリップして
  # 横位置(left/width)を決める。同じ会社内で日程が重なる依頼は、
  # その行の中で縦のレーンに振り分けてtop/heightを決める。
  def gantt_rows_for(businesses, work_requests, month)
    days_in_month = month.end_of_month.day

    businesses.map do |business|
      intervals = work_requests
        .select { |work_request| work_request.business_id == business.id }
        .map do |work_request|
          start_day = [ work_request.starts_at.to_date, month ].max.day
          end_day = [ [ work_request.ends_at.to_date, month.end_of_month ].min.day, start_day ].max

          { work_request: work_request, start_day: start_day, end_day: end_day }
        end
        .sort_by { |interval| interval[:start_day] }

      lane_ends = []

      placed = intervals.map do |interval|
        lane_index = lane_ends.find_index { |end_day| end_day < interval[:start_day] }

        if lane_index
          lane_ends[lane_index] = interval[:end_day]
        else
          lane_ends << interval[:end_day]
          lane_index = lane_ends.size - 1
        end

        interval.merge(lane_index: lane_index)
      end

      lanes_count = [ lane_ends.size, 1 ].max

      bars = placed.map do |interval|
        {
          work_request: interval[:work_request],
          left_pct: (interval[:start_day] - 1) / days_in_month.to_f * 100,
          width_pct: (interval[:end_day] - interval[:start_day] + 1) / days_in_month.to_f * 100,
          top_pct: interval[:lane_index] * (100.0 / lanes_count),
          height_pct: 100.0 / lanes_count
        }
      end

      { business: business, bars: bars, lanes_count: lanes_count }
    end
  end
end
