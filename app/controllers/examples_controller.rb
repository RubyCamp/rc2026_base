class ExamplesController < ApplicationController
  def local_data
    json_path =
      Rails.root.join(
        "config/examples/team_locations.json"
      )

    @locations =
      JSON.parse(
        json_path.read,
        symbolize_names: true
      )
  end
end
